//
//  FlightResultsError.swift
//  GoZayanProject
//
//  User-presentable failure kinds and the copy for the empty/error states
//  (spec §4.3, ERR-02). Copy lives here, not in the network layer.
//

import Foundation

nonisolated enum FlightResultsError: Error, Hashable, Sendable {
    case offline
    case unauthorized
    case quotaExceeded
    case server
    case invalidResponse
}

nonisolated struct StateMessage: Hashable, Sendable {
    let title: String
    let message: String
    let actionTitle: String
}

nonisolated extension FlightResultsError {
    var stateMessage: StateMessage {
        switch self {
        case .offline:
            StateMessage(title: "No internet connection",
                         message: "Check your connection and try again.",
                         actionTitle: "Try again")
        case .unauthorized:
            StateMessage(title: "Couldn't load flights",
                         message: "The flight service rejected our request.",
                         actionTitle: "Try again")
        case .quotaExceeded:
            StateMessage(title: "Too many searches",
                         message: "Please try again later.",
                         actionTitle: "Try again")
        case .server:
            StateMessage(title: "Something went wrong",
                         message: "We couldn't load flights right now.",
                         actionTitle: "Try again")
        case .invalidResponse:
            StateMessage(title: "Something went wrong",
                         message: "We received an unexpected response.",
                         actionTitle: "Try again")
        }
    }
}

nonisolated extension StateMessage {
    static let noFlights = StateMessage(title: "No flights found",
                                        message: "Try a different date or route.",
                                        actionTitle: "Search again")
}

nonisolated enum FlightResultsCopy {
    static let loadingMessage = "Hang tight! We're finding the best flight options for you."
}
