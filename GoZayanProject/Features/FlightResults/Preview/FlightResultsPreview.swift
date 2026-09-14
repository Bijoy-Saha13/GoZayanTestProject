//
//  FlightResultsPreview.swift
//  GoZayanProject
//
//  DEBUG-only sample data so the UI can be built and checked in every state
//  before the ViewModel, service and Coordinator exist (spec §15, steps 7–9).
//  Temporary: replaced by the ViewModel binding + stub service (UI-09).
//
//  Pick a state with a launch argument:
//      -FlightsPreviewState loading | success | empty | error
//  Default: loading for 2 s, then success.
//

#if DEBUG
import UIKit

enum FlightResultsPreview {

    static func attach(to viewController: FlightResultsViewController) {
        viewController.configure(header: header, dateChips: dateChips, promos: promos)

        var sort = SortOption.cheapest
        weak let weakController = viewController

        func showResults() {
            weakController?.render(.success(FlightResultsContent(offers: sortedOffers(by: sort),
                                                                  promoInsertionIndex: 2,
                                                                  selectedSort: sort)))
        }

        func loadThenShowResults() {
            weakController?.render(.loading)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: showResults)
        }

        viewController.onSortSelected = { option in
            sort = option
            showResults()
        }
        viewController.onRetry = loadThenShowResults
        viewController.onFlightSelected = { id in print("[Preview] flight selected: \(id)") }
        viewController.onPromoLearnMore = { id in print("[Preview] learn more: \(id)") }

        switch UserDefaults.standard.string(forKey: "FlightsPreviewState") {
        case "loading": viewController.render(.loading)
        case "success": showResults()
        case "empty": viewController.render(.empty)
        case "error": viewController.render(.error(.offline))
        default: loadThenShowResults()
        }
    }

    // MARK: - Sample data

    static let header = RouteHeaderViewData(title: "Dhaka - Bangkok",
                                            dateText: "14 Oct, 2026",
                                            passengerCountText: "01",
                                            tripTypeText: "One Way",
                                            accessibilityLabel: "Dhaka to Bangkok, 14 October 2026, 1 traveller, One Way")

    static let dateChips: [DateChipViewData] = [
        ("2026-10-11", "Sun 11 Oct", "BDT 70,129"),
        ("2026-10-12", "Mon 12 Oct", "BDT 52,300"),
        ("2026-10-13", "Tue 13 Oct", "BDT 41,250"),
        ("2026-10-14", "Wed 14 Oct", "BDT 37,400"),
        ("2026-10-15", "Thu 15 Oct", "BDT 39,900"),
        ("2026-10-16", "Fri 16 Oct", "BDT 45,600"),
        ("2026-10-17", "Sat 17 Oct", "BDT 48,000")
    ].map { DateChipViewData(id: $0.0, dayText: $0.1, fareText: $0.2, isSelected: $0.0 == "2026-10-14") }

    static let promos: [PromoViewData] = [
        PromoViewData(id: "intl", imageName: "PromoInternationalFlights", title: "On International Flight Bookings"),
        PromoViewData(id: "domestic", imageName: "PromoDomesticFlights", title: "On Domestic Flight Bookings"),
        PromoViewData(id: "hotels", imageName: "PromoHotels", title: "On Hotel Bookings")
    ]

    /// Preview-only ordering so the dropdown visibly works. Real sorting is a
    /// ViewModel function over `FlightOffer` (EXT-03), not this.
    private static func sortedOffers(by sort: SortOption) -> [FlightCardViewData] {
        offers.sorted { lhs, rhs in
            switch sort {
            case .cheapest: (lhs.price ?? .max, lhs.minutes) < (rhs.price ?? .max, rhs.minutes)
            case .fastest: (lhs.minutes, lhs.price ?? .max) < (rhs.minutes, rhs.price ?? .max)
            }
        }
        .map(\.viewData)
    }

    private static let offers: [(viewData: FlightCardViewData, price: Int?, minutes: Int)] = [
        offer(id: "BG388", airline: "Biman Bangladesh Airlines", logo: "BG", depart: "12:30", arrive: "16:50",
              dayOffset: nil, minutes: 280, stops: 0, price: 37_400),
        offer(id: "BS201-BS218", airline: "US-Bangla Airlines", logo: "BS", depart: "04:00", arrive: "08:20",
              dayOffset: "+1Day", minutes: 1_640, stops: 1, price: 78_880),
        offer(id: "TG340", airline: "Thai Airways", logo: "TG", depart: "09:15", arrive: "13:30",
              dayOffset: nil, minutes: 195, stops: 0, price: 41_250),
        offer(id: "G9512-BS143-BS215", airline: "Air Arabia + US-Bangla Airlines", logo: nil, depart: "09:30",
              arrive: "07:40", dayOffset: "+2Day", minutes: 3_020, stops: 2, price: 202_972),
        offer(id: "6E1116-6E1053", airline: "IndiGo", logo: "6E", depart: "22:10", arrive: "06:05",
              dayOffset: "+1Day", minutes: 415, stops: 1, price: nil)
    ]

    private static func offer(id: String, airline: String, logo: String?, depart: String, arrive: String,
                              dayOffset: String?, minutes: Int, stops: Int,
                              price: Int?) -> (viewData: FlightCardViewData, price: Int?, minutes: Int) {
        let duration = minutes % 60 == 0 ? "\(minutes / 60)h" : "\(minutes / 60)h \(minutes % 60)m"
        let stopsText = stops == 0 ? "Non-Stop" : "\(stops) Stop"
        let amount = price.map { $0.formatted(.number.grouping(.automatic).locale(Locale(identifier: "en_US"))) }
        let priceText = amount.map { "BDT \($0)" } ?? "Price unavailable"

        let viewData = FlightCardViewData(
            id: id,
            airlineName: airline,
            airlineLogoURL: logo.flatMap { URL(string: "https://www.gstatic.com/flights/airline_logos/70px/\($0).png") },
            departureTime: depart,
            departureCode: "DAC",
            arrivalTime: arrive,
            arrivalCode: "BKK",
            dayOffsetText: dayOffset,
            durationText: duration,
            stopCount: stops,
            stopsText: stopsText,
            price: amount.map { FlightCardViewData.Price(currencyCode: "BDT", amountText: $0) },
            accessibilityLabel: "\(airline), departs \(depart) DAC, arrives \(arrive) BKK"
                + (dayOffset.map { " \($0)" } ?? "")
                + ", \(duration), \(stopsText), \(priceText)"
        )
        return (viewData, price, minutes)
    }
}
#endif
