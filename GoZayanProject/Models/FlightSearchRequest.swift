//
//  FlightSearchRequest.swift
//  GoZayanProject
//

import Foundation

/// What the user searched for. Drives both the API call and the route header,
/// so the header is correct even when the search fails (FR-01a).
nonisolated struct FlightSearchRequest: Codable, Hashable, Sendable {

    nonisolated enum TripType: Int, Codable, Sendable {
        /// SerpApi `type=2`.
        case oneWay = 2
    }

    let departureID: String
    let departureCity: String
    let arrivalID: String
    let arrivalCity: String
    let outboundDate: CalendarDay
    let adults: Int
    let currency: String
    let tripType: TripType

    /// The search the app runs (decision D-01): Dhaka → Bangkok, one adult,
    /// 30 days from today so the date is never in the past.
    ///
    /// Currency is USD because SerpApi rejects BDT
    /// (HTTP 400 "Unsupported `BDT` for currency.", verified 2026-09-15).
    static func defaultSearch(today: CalendarDay) -> FlightSearchRequest {
        FlightSearchRequest(departureID: "DAC",
                            departureCity: "Dhaka",
                            arrivalID: "BKK",
                            arrivalCity: "Bangkok",
                            outboundDate: today.adding(days: 30),
                            adults: 1,
                            currency: "USD",
                            tripType: .oneWay)
    }
}
