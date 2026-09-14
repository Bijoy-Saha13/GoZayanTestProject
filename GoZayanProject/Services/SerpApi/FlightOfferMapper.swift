//
//  FlightOfferMapper.swift
//  GoZayanProject
//

import Foundation

/// Flattens SerpApi's nested itineraries into `FlightOffer`s (spec §6.4).
/// Pure and deterministic; invalid itineraries are dropped, never crashed on.
nonisolated enum FlightOfferMapper {

    /// MAP-01: `best_flights` then `other_flights`, each in API order.
    static func offers(from response: FlightSearchResponseDTO, currency: String) -> [FlightOffer] {
        let itineraries = (response.bestFlights ?? []).map { ($0, FlightOffer.Source.best) }
            + (response.otherFlights ?? []).map { ($0, FlightOffer.Source.other) }

        var usedIDs = Set<String>()
        var offers: [FlightOffer] = []
        for (itinerary, source) in itineraries {
            guard let offer = offer(from: itinerary, source: source, currency: currency) else { continue }
            // MAP-10: ids must be unique for the diffable data source.
            var id = offer.id
            var suffix = 2
            while usedIDs.contains(id) {
                id = "\(offer.id)#\(suffix)"
                suffix += 1
            }
            usedIDs.insert(id)
            offers.append(offer.replacingID(with: id))
        }
        return offers
    }

    static func offer(from itinerary: ItineraryDTO, source: FlightOffer.Source, currency: String) -> FlightOffer? {
        // MAP-09: an itinerary without legs, endpoints or parseable times can't be shown.
        guard let legs = itinerary.flights, let firstLeg = legs.first, let lastLeg = legs.last,
              let originCode = firstLeg.departureAirport?.id.nonBlank,
              let destinationCode = lastLeg.arrivalAirport?.id.nonBlank,
              let departure = firstLeg.departureAirport?.time.flatMap(LocalDateTime.init(serpApiString:)),
              let arrival = lastLeg.arrivalAirport?.time.flatMap(LocalDateTime.init(serpApiString:)),
              let durationMinutes = duration(of: itinerary, legs: legs) else {
            return nil
        }

        // MAP-02: non-stop itineraries omit `layovers`, so fall back to the leg count.
        let stops = itinerary.layovers?.count ?? max(legs.count - 1, 0)

        // MAP-07: distinct airlines in leg order.
        var airlineNames: [String] = []
        for name in legs.compactMap({ $0.airline.nonBlank }) where !airlineNames.contains(name) {
            airlineNames.append(name)
        }

        let flightNumbers = legs.compactMap { $0.flightNumber.nonBlank?.replacingOccurrences(of: " ", with: "") }
        let idPrefix = flightNumbers.isEmpty ? airlineNames.joined(separator: "+") : flightNumbers.joined(separator: "-")

        return FlightOffer(id: "\(idPrefix)@\(firstLeg.departureAirport?.time ?? "")",
                           airlineNames: airlineNames,
                           airlineLogoURL: (itinerary.airlineLogo.nonBlank ?? firstLeg.airlineLogo.nonBlank).flatMap { URL(string: $0) },
                           originCode: originCode,
                           destinationCode: destinationCode,
                           departure: departure,
                           arrival: arrival,
                           durationMinutes: durationMinutes,
                           stops: stops,
                           layoverCodes: itinerary.layovers?.compactMap { $0.id.nonBlank } ?? [],
                           price: itinerary.price,
                           currency: currency,
                           source: source)
    }

    /// MAP-06: `total_duration`, else legs + layovers. Never arrival − departure:
    /// the two times are in different time zones.
    private static func duration(of itinerary: ItineraryDTO, legs: [FlightLegDTO]) -> Int? {
        if let total = itinerary.totalDuration, total > 0 {
            return total
        }
        let legMinutes = legs.compactMap(\.duration).reduce(0, +)
        let layoverMinutes = itinerary.layovers?.compactMap(\.duration).reduce(0, +) ?? 0
        let sum = legMinutes + layoverMinutes
        return sum > 0 ? sum : nil
    }
}

private nonisolated extension FlightOffer {
    func replacingID(with id: String) -> FlightOffer {
        FlightOffer(id: id, airlineNames: airlineNames, airlineLogoURL: airlineLogoURL,
                    originCode: originCode, destinationCode: destinationCode,
                    departure: departure, arrival: arrival, durationMinutes: durationMinutes,
                    stops: stops, layoverCodes: layoverCodes, price: price,
                    currency: currency, source: source)
    }
}

private nonisolated extension Optional where Wrapped == String {
    var nonBlank: String? {
        guard let trimmed = self?.trimmingCharacters(in: .whitespaces), !trimmed.isEmpty else { return nil }
        return trimmed
    }
}
