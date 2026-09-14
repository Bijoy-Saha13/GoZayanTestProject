//
//  SerpApiDTOs.swift
//  GoZayanProject
//
//  Mirrors the SerpApi Google Flights response (spec §6.2). Only fields the app uses
//  are decoded; everything is optional because SerpApi omits keys freely — e.g.
//  non-stop itineraries have no `layovers` key and some itineraries have no `price`.
//  Keys are snake_case in JSON and decoded with `.convertFromSnakeCase`.
//

import Foundation

nonisolated struct FlightSearchResponseDTO: Decodable, Sendable {
    let searchMetadata: SearchMetadataDTO?
    let bestFlights: [ItineraryDTO]?
    let otherFlights: [ItineraryDTO]?
    /// Present on HTTP 200 when Google Flights returned nothing.
    let error: String?
}

nonisolated struct SearchMetadataDTO: Decodable, Sendable {
    /// "Success", "Processing", "Queued" or "Error".
    let status: String?
}

nonisolated struct ItineraryDTO: Decodable, Sendable {
    let flights: [FlightLegDTO]?
    let layovers: [LayoverDTO]?
    let totalDuration: Int?
    let price: Int?
    let airlineLogo: String?
}

nonisolated struct FlightLegDTO: Decodable, Sendable {
    let departureAirport: AirportDTO?
    let arrivalAirport: AirportDTO?
    let duration: Int?
    let airline: String?
    let airlineLogo: String?
    let flightNumber: String?
}

nonisolated struct AirportDTO: Decodable, Sendable {
    let id: String?
    let name: String?
    /// "yyyy-MM-dd HH:mm", local to the airport.
    let time: String?
}

nonisolated struct LayoverDTO: Decodable, Sendable {
    let id: String?
    let name: String?
    let duration: Int?
}
