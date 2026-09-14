//
//  FlightResultsViewData.swift
//  GoZayanProject
//
//  Display-ready values for each UI element. All strings are already formatted
//  (spec §6.5) so views only bind them. Foundation only.
//

import Foundation

/// Route header (FR-01). Built from the search request, so it is valid in every state.
nonisolated struct RouteHeaderViewData: Hashable, Sendable {
    let title: String               // "Dhaka - Bangkok"
    let dateText: String            // "14 Oct, 2026"
    let passengerCountText: String  // "01"
    let tripTypeText: String        // "One Way"
    let accessibilityLabel: String  // "Dhaka to Bangkok, 14 October 2026, 1 traveller, One Way"
}

/// One chip in the date & price strip (FR-02). Hard-coded dummy data.
nonisolated struct DateChipViewData: Hashable, Sendable, Identifiable {
    let id: String                  // "2026-10-14"
    let dayText: String             // "Wed 14 Oct"
    let fareText: String            // "BDT 37,400"
    let isSelected: Bool
}

/// One promo in the discount carousel (FR-05). The destination URL is deliberately
/// not here: the view reports the promo id and the Coordinator does the navigation.
nonisolated struct PromoViewData: Hashable, Sendable, Identifiable {
    let id: String
    let imageName: String
    let title: String
}

/// One flight card (FR-04).
nonisolated struct FlightCardViewData: Hashable, Sendable, Identifiable {
    let id: String
    let airlineName: String         // "Air Arabia + US-Bangla Airlines"
    let airlineLogoURL: URL?
    let departureTime: String       // "12:30"
    let departureCode: String       // "DAC"
    let arrivalTime: String         // "16:50"
    let arrivalCode: String         // "BKK"
    let dayOffsetText: String?      // "+1Day", nil when arriving the same day
    let durationText: String        // "4h 40m"
    let stopCount: Int
    let stopsText: String           // "Non-Stop" / "1 Stop" / "2 Stop"
    let price: Price?               // nil → "Price unavailable" (D-07)
    let accessibilityLabel: String

    nonisolated struct Price: Hashable, Sendable {
        let currencyCode: String    // "BDT"
        let amountText: String      // "37,400"
    }
}
