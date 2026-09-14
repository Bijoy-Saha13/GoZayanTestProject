//
//  CalendarDay.swift
//  GoZayanProject
//

import Foundation

/// A calendar date with no time and no time zone, e.g. the search date "2026-10-15".
///
/// Kept as plain components so a date can never shift by a day when the device's
/// time zone changes. Date arithmetic runs on a fixed UTC Gregorian calendar.
nonisolated struct CalendarDay: Hashable, Comparable, Codable, Sendable {
    let year: Int
    let month: Int
    let day: Int

    init?(year: Int, month: Int, day: Int) {
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = Self.utc.date(from: components),
              Self.utc.dateComponents([.year, .month, .day], from: date) == components else { return nil }
        self.year = year
        self.month = month
        self.day = day
    }

    /// Parses "yyyy-MM-dd". Rejects impossible dates such as "2026-02-31".
    init?(isoString: String) {
        let parts = isoString.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else { return nil }
        self.init(year: year, month: month, day: day)
    }

    /// Today's date as seen on the device.
    static func today(now: Date = Date(), calendar: Calendar = .current) -> CalendarDay {
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        // Components from a real Date are always a valid day.
        return CalendarDay(year: components.year ?? 1970, month: components.month ?? 1, day: components.day ?? 1)!
    }

    var isoString: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// 1 = Sunday … 7 = Saturday.
    var weekday: Int {
        Self.utc.component(.weekday, from: startDate)
    }

    func adding(days: Int) -> CalendarDay {
        let date = Self.utc.date(byAdding: .day, value: days, to: startDate) ?? startDate
        let components = Self.utc.dateComponents([.year, .month, .day], from: date)
        return CalendarDay(year: components.year!, month: components.month!, day: components.day!)!
    }

    /// Whole days from `self` to `other` (negative if `other` is earlier).
    func days(until other: CalendarDay) -> Int {
        Self.utc.dateComponents([.day], from: startDate, to: other.startDate).day ?? 0
    }

    static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    // MARK: - Private

    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private var startDate: Date {
        Self.utc.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
