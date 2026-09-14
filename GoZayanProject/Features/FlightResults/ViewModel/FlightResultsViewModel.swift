//
//  FlightResultsViewModel.swift
//  GoZayanProject
//
//  Foundation only: no UIKit, no Coordinator (spec ARCH-01…03). Navigation-worthy
//  events go out through a delegate protocol; state goes out through a closure.
//

import Foundation

/// How the ViewModel reports things that may need navigation. The ViewModel only
/// sees this protocol — it does not know what implements it. Name from the brief.
protocol FlightResultsCoordinatorDelegate: AnyObject {
    func didSelectFlight(_ offer: FlightOffer)
    func didSelectPromo(_ promo: Promo)
}

@MainActor
final class FlightResultsViewModel {

    weak var delegate: FlightResultsCoordinatorDelegate?

    /// Receives the current state immediately when set, then every change.
    var onStateChange: ((FlightResultsState) -> Void)? {
        didSet { onStateChange?(state) }
    }

    /// Starts as `.loading` — there is no idle state (spec §4).
    private(set) var state: FlightResultsState = .loading {
        didSet {
            if state != oldValue { onStateChange?(state) }
        }
    }

    // Static parts of the screen, valid in every state.
    let header: RouteHeaderViewData
    let dateChips: [DateChipViewData]
    let promos: [PromoViewData]

    private let request: FlightSearchRequest
    private let service: FlightSearchServicing
    private let promoItems: [Promo]

    private var offers: [FlightOffer] = []
    private var displayedOffers: [FlightOffer] = []
    private var selectedSort: SortOption = .cheapest
    private var loadTask: Task<Void, Never>?
    private var loadGeneration = 0

    init(request: FlightSearchRequest,
         service: FlightSearchServicing,
         fareCalendar: FareCalendarProviding,
         promoProvider: PromoProviding) {
        self.request = request
        self.service = service
        self.promoItems = promoProvider.promos()
        self.header = Self.makeHeader(for: request)
        self.dateChips = fareCalendar.fares(around: request.outboundDate, currency: request.currency).map {
            DateChipViewData(id: $0.day.isoString,
                             dayText: FlightResultsFormatter.chipDay($0.day),
                             fareText: FlightResultsFormatter.price($0.amount, currency: $0.currency),
                             isSelected: $0.day == request.outboundDate)
        }
        self.promos = promoItems.map { PromoViewData(id: $0.id, imageName: $0.imageName, title: $0.title) }
    }

    // MARK: - Intents

    /// Fetches flights. A newer call supersedes an older one: its result is ignored
    /// even if it arrives later (ST-T6).
    func load() {
        loadTask?.cancel()
        loadGeneration += 1
        let generation = loadGeneration
        state = .loading

        loadTask = Task { [weak self, service, request] in
            let result: Result<[FlightOffer], Error>
            do {
                result = .success(try await service.searchFlights(request))
            } catch {
                result = .failure(error)
            }
            self?.finishLoading(with: result, generation: generation)
        }
    }

    func retry() {
        load()
    }

    /// Re-sorts in place without a network call (ST-T7). The choice survives reloads.
    func selectSort(_ option: SortOption) {
        guard option != selectedSort else { return }
        selectedSort = option
        if case .success = state {
            publishOffers()
        }
    }

    func didSelectOffer(id: FlightCardViewData.ID) {
        guard let offer = displayedOffers.first(where: { $0.id == id }) else { return }
        delegate?.didSelectFlight(offer)
    }

    func didTapLearnMore(promoID: PromoViewData.ID) {
        guard let promo = promoItems.first(where: { $0.id == promoID }) else { return }
        delegate?.didSelectPromo(promo)
    }

    // MARK: - Pure logic

    /// EXT-03…05: a plain function over offers. Stable; a missing price sorts last.
    nonisolated static func sort(_ offers: [FlightOffer], by option: SortOption) -> [FlightOffer] {
        offers.enumerated().sorted { lhs, rhs in
            let left = lhs.element, right = rhs.element
            let leftPrice = left.price ?? .max, rightPrice = right.price ?? .max

            switch option {
            case .cheapest:
                if leftPrice != rightPrice { return leftPrice < rightPrice }
                if left.durationMinutes != right.durationMinutes { return left.durationMinutes < right.durationMinutes }
            case .fastest:
                if left.durationMinutes != right.durationMinutes { return left.durationMinutes < right.durationMinutes }
                if leftPrice != rightPrice { return leftPrice < rightPrice }
            }
            return lhs.offset < rhs.offset
        }
        .map(\.element)
    }

    /// FR-07: the carousel goes after the 2nd card, or after the last if there are fewer.
    nonisolated static func promoInsertionIndex(offerCount: Int) -> Int {
        min(2, offerCount)
    }

    nonisolated static func makeCardViewData(for offer: FlightOffer) -> FlightCardViewData {
        typealias Format = FlightResultsFormatter

        let airline = Format.airlines(offer.airlineNames)
        let dayOffset = Format.dayOffset(offer.arrivalDayOffset)
        let stops = Format.stops(offer.stops)
        let priceText = offer.price.map { Format.price($0, currency: offer.currency) } ?? "Price unavailable"

        return FlightCardViewData(
            id: offer.id,
            airlineName: airline,
            airlineLogoURL: offer.airlineLogoURL,
            departureTime: Format.time(offer.departure),
            departureCode: offer.originCode,
            arrivalTime: Format.time(offer.arrival),
            arrivalCode: offer.destinationCode,
            dayOffsetText: dayOffset,
            durationText: Format.duration(minutes: offer.durationMinutes),
            stopCount: offer.stops,
            stopsText: stops,
            price: offer.price.map { FlightCardViewData.Price(currencyCode: offer.currency, amountText: Format.groupedAmount($0)) },
            accessibilityLabel: "\(airline). Departs \(offer.originCode) at \(Format.time(offer.departure)). "
                + "Arrives \(offer.destinationCode) at \(Format.time(offer.arrival))\(Format.spokenDayOffset(offer.arrivalDayOffset)). "
                + "\(Format.spokenDuration(minutes: offer.durationMinutes)), \(stops). \(priceText)."
        )
    }

    // MARK: - Private

    private func finishLoading(with result: Result<[FlightOffer], Error>, generation: Int) {
        guard generation == loadGeneration else { return }

        switch result {
        case .success(let offers):
            self.offers = offers
            publishOffers()
        case .failure(let error):
            guard !(error is CancellationError) else { return }
            state = .error(FlightResultsError(error))
        }
    }

    private func publishOffers() {
        guard !offers.isEmpty else {
            displayedOffers = []
            state = .empty
            return
        }
        displayedOffers = Self.sort(offers, by: selectedSort)
        state = .success(FlightResultsContent(offers: displayedOffers.map(Self.makeCardViewData),
                                              promoInsertionIndex: Self.promoInsertionIndex(offerCount: displayedOffers.count),
                                              selectedSort: selectedSort))
    }

    private static func makeHeader(for request: FlightSearchRequest) -> RouteHeaderViewData {
        let travellers = request.adults == 1 ? "1 traveller" : "\(request.adults) travellers"
        return RouteHeaderViewData(
            title: "\(request.departureCity) - \(request.arrivalCity)",
            dateText: FlightResultsFormatter.headerDate(request.outboundDate),
            passengerCountText: FlightResultsFormatter.passengerCount(request.adults),
            tripTypeText: "One Way",
            accessibilityLabel: "\(request.departureCity) to \(request.arrivalCity), "
                + "\(FlightResultsFormatter.spokenDate(request.outboundDate)), \(travellers), One Way"
        )
    }
}
