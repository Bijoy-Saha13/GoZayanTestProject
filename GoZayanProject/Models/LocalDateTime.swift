//
//  LocalDateTime.swift
//  GoZayanProject
//

import Foundation

/// Wall-clock time at an airport, exactly as SerpApi sends it ("2026-10-15 13:40").
///
/// SerpApi times carry no time zone: departure is local to the origin airport and
/// arrival local to the destination. Storing components (not a `Date`) means the
/// device time zone can never change what is shown (spec MAP-11), and nobody is
/// tempted to subtract two of them to get a duration (MAP-06).
nonisolated struct LocalDateTime: Hashable, Comparable, Codable, Sendable {
    let day: CalendarDay
    let hour: Int
    let minute: Int

    init?(day: CalendarDay, hour: Int, minute: Int) {
        guard (0..<24).contains(hour), (0..<60).contains(minute) else { return nil }
        self.day = day
        self.hour = hour
        self.minute = minute
    }

    /// Parses "yyyy-MM-dd HH:mm".
    init?(serpApiString: String) {
        let parts = serpApiString.split(separator: " ")
        guard parts.count == 2, let day = CalendarDay(isoString: String(parts[0])) else { return nil }
        let time = parts[1].split(separator: ":", omittingEmptySubsequences: false)
        guard time.count == 2, time[0].count == 2, time[1].count == 2,
              let hour = Int(time[0]), let minute = Int(time[1]) else { return nil }
        self.init(day: day, hour: hour, minute: minute)
    }

    static func < (lhs: LocalDateTime, rhs: LocalDateTime) -> Bool {
        (lhs.day, lhs.hour, lhs.minute) < (rhs.day, rhs.hour, rhs.minute)
    }
}
