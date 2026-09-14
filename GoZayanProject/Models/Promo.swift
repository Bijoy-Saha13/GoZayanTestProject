//
//  Promo.swift
//  GoZayanProject
//

import Foundation

/// A discount shown in the carousel (FR-05). Dummy data.
nonisolated struct Promo: Hashable, Identifiable, Sendable {
    let id: String
    let imageName: String
    let title: String
    let url: URL
}

/// The lowest fare for one day in the date strip (FR-02). Dummy data.
nonisolated struct DateFare: Hashable, Sendable {
    let day: CalendarDay
    let amount: Int
    let currency: String
}
