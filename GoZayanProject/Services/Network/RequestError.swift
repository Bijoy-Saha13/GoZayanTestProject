//
//  RequestError.swift
//  GoZayanProject
//
//  Transport-level failures. No user-facing copy here — the ViewModel turns these
//  into `FlightResultsError` (spec ERR-02).
//

import Foundation

nonisolated enum RequestError: Error, Equatable, Sendable {
    case invalidURL
    /// No connection, connection lost, or timed out.
    case offline
    case transport(URLError.Code)
    case invalidResponse
    /// HTTP 401 / 403 — missing or rejected API key.
    case unauthorized(statusCode: Int)
    /// HTTP 429 — hourly limit hit or searches used up.
    case rateLimited
    /// Any other non-2xx status.
    case server(statusCode: Int)
    case decoding(description: String)
}

nonisolated extension RequestError {
    init(_ error: URLError) {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut, .dataNotAllowed, .internationalRoamingOff:
            self = .offline
        default:
            self = .transport(error.code)
        }
    }
}
