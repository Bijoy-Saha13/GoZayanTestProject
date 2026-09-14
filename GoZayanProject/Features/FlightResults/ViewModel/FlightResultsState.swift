//
//  FlightResultsState.swift
//  GoZayanProject
//
//  The four states of the Flight Results screen (spec §4). Foundation only —
//  the ViewModel owns and emits this; the view controller only renders it.
//

import Foundation

nonisolated enum FlightResultsState: Hashable, Sendable {
    case loading
    case success(FlightResultsContent)
    case empty
    case error(FlightResultsError)
}

nonisolated struct FlightResultsContent: Hashable, Sendable {
    /// Already sorted by `selectedSort`.
    let offers: [FlightCardViewData]
    /// Number of flight cards shown before the promo carousel (FR-07).
    let promoInsertionIndex: Int
    let selectedSort: SortOption
}

nonisolated enum SortOption: String, CaseIterable, Hashable, Sendable {
    case cheapest
    case fastest

    var title: String {
        switch self {
        case .cheapest: "Cheapest"
        case .fastest: "Fastest"
        }
    }
}
