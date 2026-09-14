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
        guard let url = Bundle.main.url(forResource: "FlightResultsFixture", withExtension: "json") else {
            throw RequestError.invalidResponse
        }
        return try SerpApiFlightSearchService.offers(from: Data(contentsOf: url), currency: request.currency)
    }
}

/// Forces one screen state. Launch argument: `-FlightsStubState loading|success|empty|error`.
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
