//
//  DummyDataProviders.swift
//  GoZayanProject
//
//  The hard-coded parts of the screen (spec §7), behind protocols so the
//  ViewModel doesn't depend on where the data comes from.
//

import Foundation

nonisolated protocol FareCalendarProviding: Sendable {
    /// Fares for the days around `day`, in date order.
    func fares(around day: CalendarDay, currency: String) -> [DateFare]
}

nonisolated protocol PromoProviding: Sendable {
    func promos() -> [Promo]
}

/// DUM-01: fixed fares for three days either side of the search date, so the
/// highlighted chip always matches the header date. Taps are ignored (FR-02).
nonisolated struct DummyFareCalendarProvider: FareCalendarProviding {

    private let amounts = [412, 356, 318, 297, 305, 339, 368]

    func fares(around day: CalendarDay, currency: String) -> [DateFare] {
        let firstOffset = -(amounts.count / 2)
        return amounts.enumerated().map { index, amount in
            DateFare(day: day.adding(days: firstOffset + index), amount: amount, currency: currency)
        }
    }
}

/// DUM-02: promos that all lead to gozayaan.com. Images are bundled assets (DUM-03).
nonisolated struct DummyPromoProvider: PromoProviding {

    func promos() -> [Promo] {
        let gozayaan = URL(string: "https://gozayaan.com")!
        return [
            Promo(id: "international-flights", imageName: "PromoInternationalFlights",
                  title: "On International Flight Bookings", url: gozayaan),
            Promo(id: "domestic-flights", imageName: "PromoDomesticFlights",
                  title: "On Domestic Flight Bookings", url: gozayaan),
            Promo(id: "hotels", imageName: "PromoHotels",
                  title: "On Hotel Bookings", url: gozayaan)
        ]
    }
}
