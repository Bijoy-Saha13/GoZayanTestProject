//
//  DebugFlightSearchServices.swift
//  GoZayanProject
//
//  DEBUG-only services for running without an API key and for showing each
//  screen state on demand (spec KEY-05, UI-09). Selected in `AppDependencies`.
//

#if DEBUG
import Foundation

/// Serves the bundled real SerpApi response (`FlightResultsFixture.json`).
nonisolated struct FixtureFlightSearchService: FlightSearchServicing {

    var delay: Duration = .milliseconds(800)

    func searchFlights(_ request: FlightSearchRequest) async throws -> [FlightOffer] {
        try await Task.sleep(for: delay)
        return try Self.offers(fromBundledJSON: "FlightResultsFixture", currency: request.currency)
    }

    /// Decodes a bundled SerpApi-shaped body through the same path as a live response.
    static func offers(fromBundledJSON name: String, currency: String) throws -> [FlightOffer] {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw RequestError.invalidResponse
        }
        return try SerpApiFlightSearchService.offers(from: Data(contentsOf: url), currency: currency)
    }
}

/// Forces one screen state. Launch argument: `-FlightsStubState loading|success|empty|error`.
///
/// `success` adds a hand-made 3-leg itinerary (`StubMultiStopItinerary.json`) to the
/// real fixture, because the captured DAC → BKK response has no 2-stop flight and
/// the brief asks for multi-leg itineraries to show "2 Stop" (spec MAP-02, DoD-11).
nonisolated struct StubFlightSearchService: FlightSearchServicing {

    nonisolated enum Mode: String, Sendable {
        case loading, success, empty, error
    }

    let mode: Mode

    func searchFlights(_ request: FlightSearchRequest) async throws -> [FlightOffer] {
        switch mode {
        case .loading:
            try await Task.sleep(for: .seconds(60 * 60))
            return []
        case .success:
            return try await FixtureFlightSearchService().searchFlights(request)
                + FixtureFlightSearchService.offers(fromBundledJSON: "StubMultiStopItinerary", currency: request.currency)
        case .empty:
            try await Task.sleep(for: .milliseconds(800))
            return []
        case .error:
            try await Task.sleep(for: .milliseconds(800))
            throw RequestError.offline
        }
    }
}
#endif
