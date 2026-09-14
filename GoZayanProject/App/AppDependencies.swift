//
//  AppDependencies.swift
//  GoZayanProject
//
//  Composition root: the one place that decides which concrete services the app
//  uses. Coordinators pass these into ViewModels.
//

import Foundation

struct AppDependencies {
    let searchRequest: FlightSearchRequest
    let flightSearchService: FlightSearchServicing
    let fareCalendar: FareCalendarProviding
    let promoProvider: PromoProviding

    static func make(defaults: UserDefaults = .standard, bundle: Bundle = .main, now: Date = Date()) -> AppDependencies {
        AppDependencies(searchRequest: .defaultSearch(today: CalendarDay.today(now: now)),
                        flightSearchService: makeFlightSearchService(defaults: defaults, bundle: bundle),
                        fareCalendar: DummyFareCalendarProvider(),
                        promoProvider: DummyPromoProvider())
    }

    /// Debug launch arguments (set in the shared scheme, off by default):
    /// - `-FlightsStubState loading|success|empty|error` forces a screen state.
    /// - `-FlightsBypassCache YES` skips the development response cache.
    private static func makeFlightSearchService(defaults: UserDefaults, bundle: Bundle) -> FlightSearchServicing {
        #if DEBUG
        if let mode = defaults.string(forKey: "FlightsStubState").flatMap(StubFlightSearchService.Mode.init(rawValue:)) {
            return StubFlightSearchService(mode: mode)
        }
        guard let apiKey = APIKeyProvider.serpApiKey(in: bundle) else {
            print("[Config] No SerpApi key in Config/Secrets.plist; showing bundled fixture data.")
            return FixtureFlightSearchService()
        }
        let client: HTTPClient = defaults.bool(forKey: "FlightsBypassCache")
            ? URLSessionHTTPClient()
            : CachingHTTPClient(wrapping: URLSessionHTTPClient())
        return SerpApiFlightSearchService(client: client, apiKey: apiKey)
        #else
        // Without a key SerpApi answers 401, which the screen shows as an error.
        return SerpApiFlightSearchService(client: URLSessionHTTPClient(),
                                          apiKey: APIKeyProvider.serpApiKey(in: bundle) ?? "")
        #endif
    }
}
