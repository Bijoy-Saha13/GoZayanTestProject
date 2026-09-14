//
//  FlightSearchService.swift
//  GoZayanProject
//

import Foundation

/// The ViewModel's only dependency for data. Returns offers in API order.
nonisolated protocol FlightSearchServicing: Sendable {
    func searchFlights(_ request: FlightSearchRequest) async throws -> [FlightOffer]
}

nonisolated enum FlightSearchError: Error, Equatable, Sendable {
    /// SerpApi reported `search_metadata.status == "Error"`.
    case searchFailed
}

/// SerpApi Google Flights, one-way (spec §5).
nonisolated struct SerpApiFlightSearchService: FlightSearchServicing {

    private let client: HTTPClient
    private let apiKey: String

    init(client: HTTPClient, apiKey: String) {
        self.client = client
        self.apiKey = apiKey
    }

    func searchFlights(_ request: FlightSearchRequest) async throws -> [FlightOffer] {
        let data = try await client.data(for: GoogleFlightsEndpoint(request: request, apiKey: apiKey))
        return try Self.offers(from: data, currency: request.currency)
    }

    /// Decodes a SerpApi body into offers.
    ///
    /// When Google Flights finds nothing, SerpApi still answers HTTP 200 with
    /// `status: "Success"` and an `"error"` message. That is an empty result, not a
    /// failure, so it returns `[]` and the screen shows the empty state (spec §4.1).
    static func offers(from data: Data, currency: String) throws -> [FlightOffer] {
        let response: FlightSearchResponseDTO
        do {
            response = try makeDecoder().decode(FlightSearchResponseDTO.self, from: data)
        } catch {
            throw RequestError.decoding(description: String(describing: error))
        }

        if response.searchMetadata?.status == "Error" {
            throw FlightSearchError.searchFailed
        }
        return FlightOfferMapper.offers(from: response, currency: currency)
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

nonisolated struct GoogleFlightsEndpoint: Endpoint {
    let request: FlightSearchRequest
    let apiKey: String

    var host: String { "serpapi.com" }
    var path: String { "/search" }

    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "engine", value: "google_flights"),
            URLQueryItem(name: "departure_id", value: request.departureID),
            URLQueryItem(name: "arrival_id", value: request.arrivalID),
            URLQueryItem(name: "outbound_date", value: request.outboundDate.isoString),
            URLQueryItem(name: "type", value: String(request.tripType.rawValue)),
            URLQueryItem(name: "currency", value: request.currency),
            URLQueryItem(name: "hl", value: "en"),
            URLQueryItem(name: "adults", value: String(request.adults)),
            URLQueryItem(name: "api_key", value: apiKey)
        ]
    }
}
