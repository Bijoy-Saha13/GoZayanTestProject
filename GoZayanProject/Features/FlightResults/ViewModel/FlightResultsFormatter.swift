//
//  FlightResultsFormatter.swift
//  GoZayanProject
//
//  Display strings for the Flight Results screen (spec §6.5). Locale-independent on
//  purpose: the design fixes English labels, so output must not depend on the device.
//

import Foundation

nonisolated enum FlightResultsFormatter {

    /// "USD 1,297" — code, space, grouped whole amount (D-03).
    static func price(_ amount: Int, currency: String) -> String {
        "\(currency) \(groupedAmount(amount))"
    }

    /// "1,297"
    static func groupedAmount(_ amount: Int) -> String {
        amount.formatted(.number.grouping(.automatic).locale(Locale(identifier: "en_US")))
    }

    /// 280 → "4h 40m", 120 → "2h", 45 → "45m".
    static func duration(minutes: Int) -> String {
        let hours = minutes / 60
        let remainder = minutes % 60
        switch (hours, remainder) {
        case (0, _): return "\(remainder)m"
        case (_, 0): return "\(hours)h"
        default: return "\(hours)h \(remainder)m"
        }
    }

    /// 280 → "4 hours 40 minutes", for VoiceOver.
    static func spokenDuration(minutes: Int) -> String {
        let hours = minutes / 60
        let remainder = minutes % 60
        let hourText = hours == 1 ? "1 hour" : "\(hours) hours"
        let minuteText = remainder == 1 ? "1 minute" : "\(remainder) minutes"
        switch (hours, remainder) {
        case (0, _): return minuteText
        case (_, 0): return hourText
        default: return "\(hourText) \(minuteText)"
        }
    }

    /// MAP-03 — the brief's exact wording: "Non-Stop", "1 Stop", "2 Stop".
    static func stops(_ count: Int) -> String {
        count == 0 ? "Non-Stop" : "\(count) Stop"
    }

    /// 1 → "+1Day", 0 → nil (Figma).
    static func dayOffset(_ days: Int) -> String? {
        switch days {
        case 0: nil
        case 1...: "+\(days)Day"
        default: "\(days)Day"
        }
    }

    /// 1 → ", 1 day later", 0 → "", for VoiceOver.
    static func spokenDayOffset(_ days: Int) -> String {
        guard days != 0 else { return "" }
        let count = abs(days) == 1 ? "1 day" : "\(abs(days)) days"
        return ", \(count) \(days > 0 ? "later" : "earlier")"
    }

    /// "13:40"
    static func time(_ time: LocalDateTime) -> String {
        String(format: "%02d:%02d", time.hour, time.minute)
    }

    /// "15 Oct, 2026" (route header).
    static func headerDate(_ day: CalendarDay) -> String {
        String(format: "%02d %@, %04d", day.day, monthNames[day.month - 1], day.year)
    }

    /// "15 October 2026", for VoiceOver.
    static func spokenDate(_ day: CalendarDay) -> String {
        "\(day.day) \(fullMonthNames[day.month - 1]) \(day.year)"
    }

    /// "Thu 15 Oct" (date strip).
    static func chipDay(_ day: CalendarDay) -> String {
        String(format: "%@ %02d %@", weekdayNames[day.weekday - 1], day.day, monthNames[day.month - 1])
    }

    /// 1 → "01" (Figma).
    static func passengerCount(_ count: Int) -> String {
        String(format: "%02d", count)
    }

    /// ["Air Arabia", "US-Bangla Airlines"] → "Air Arabia + US-Bangla Airlines" (D-09).
    static func airlines(_ names: [String]) -> String {
        names.isEmpty ? "Unknown airline" : names.joined(separator: " + ")
    }

    private static let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    private static let fullMonthNames = ["January", "February", "March", "April", "May", "June", "July",
                                         "August", "September", "October", "November", "December"]
    private static let weekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
}
