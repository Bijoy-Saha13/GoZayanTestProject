//
//  FlightOffer.swift
//  GoZayanProject
//

import Foundation

/// One bookable itinerary, flattened from SerpApi's nested `flights` + `layovers`
/// into exactly what a flight card needs (spec §6.3). UI-agnostic.
nonisolated struct FlightOffer: Codable, Hashable, Identifiable, Sendable {

    /// Which SerpApi array the offer came from.
    nonisolated enum Source: String, Codable, Sendable {
        case best
        case other
    }

    let id: String
    /// Distinct operating airlines in leg order.
    let airlineNames: [String]
    let airlineLogoURL: URL?
    /// First leg's departure airport.
    let originCode: String
    /// Last leg's arrival airport.
    let destinationCode: String
    let departure: LocalDateTime
    let arrival: LocalDateTime
    /// SerpApi `total_duration`, including layovers.
    let durationMinutes: Int
    let stops: Int
    let layoverCodes: [String]
    /// `nil` when SerpApi omits the price (seen in real responses).
    let price: Int?
    let currency: String
    let source: Source

    /// Calendar days between departure and arrival, e.g. 1 for an overnight flight.
    var arrivalDayOffset: Int {
        departure.day.days(until: arrival.day)
    }
}
