//
//  DateConverter.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation

/// Utility for converting between UTC and local timezone
/// All Notion API dates are in UTC, but UI displays local time
enum DateConverter {
    // MARK: - Formatters

    /// ISO8601 formatter for API communication (always UTC) - Format with Z
    private static let iso8601FormatterZ: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    /// ISO8601 formatter with timezone offset (+00:00) - Notion uses this format
    private static let iso8601FormatterWithOffset: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withYear,
            .withMonth,
            .withDay,
            .withTime,
            .withColonSeparatorInTime,
            .withFractionalSeconds,
            .withColonSeparatorInTimeZone
        ]
        return formatter
    }()

    /// Fallback ISO8601 formatter without fractional seconds
    private static let iso8601FormatterNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Date formatter for API date strings (YYYY-MM-DD in UTC)
    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // MARK: - UTC to Local

    /// Convert UTC date to local timezone
    /// - Parameter utcDate: Date in UTC timezone
    /// - Returns: Same moment in time, but for display in local timezone
    /// - Note: The Date object itself is timezone-agnostic; this is for UI formatting
    static func toLocal(from utcDate: Date) -> Date {
        // Date objects are timezone-agnostic in Swift
        // This method exists for clarity and future timezone handling
        return utcDate
    }

    // MARK: - Local to UTC

    /// Convert local date to UTC timezone
    /// - Parameter localDate: Date in local timezone
    /// - Returns: Same moment in time, prepared for API calls
    /// - Note: The Date object itself is timezone-agnostic; this is for API formatting
    static func toUTC(from localDate: Date) -> Date {
        // Date objects are timezone-agnostic in Swift
        // This method exists for clarity and future timezone handling
        return localDate
    }

    // MARK: - API Formatting

    /// Format date for Notion API (ISO8601 with UTC)
    /// - Parameter date: Date to format
    /// - Returns: ISO8601 string in format "2025-10-22T12:00:00.000Z"
    static func formatForAPI(_ date: Date) -> String {
        return iso8601FormatterZ.string(from: date)
    }

    /// Format date as YYYY-MM-DD for Notion date filters (UTC)
    /// - Parameter date: Date to format
    /// - Returns: Date string in format "2025-10-22"
    static func formatDateOnly(_ date: Date) -> String {
        return apiDateFormatter.string(from: date)
    }

    /// Parse ISO8601 string from Notion API
    /// - Parameter string: ISO8601 date string from API
    /// - Returns: Parsed Date, or nil if invalid format
    static func parseFromAPI(_ string: String) -> Date? {
        // Try format with timezone offset first (Notion's preferred format)
        // Example: "2025-10-22T14:59:00.000+00:00"
        if let date = iso8601FormatterWithOffset.date(from: string) {
            return date
        }

        // Try format with Z (standard ISO8601)
        // Example: "2025-10-22T14:59:00.000Z"
        if let date = iso8601FormatterZ.date(from: string) {
            return date
        }

        // Try without fractional seconds
        // Example: "2025-10-22T14:59:00Z"
        if let date = iso8601FormatterNoFraction.date(from: string) {
            return date
        }

        // Fallback to date-only format
        // Example: "2025-10-22"
        return apiDateFormatter.date(from: string)
    }

    // MARK: - Today Helpers

    /// Get today's date at midnight in UTC (for filtering)
    /// - Returns: Start of today in UTC timezone
    static func todayUTC() -> Date {
        let calendar = Calendar(identifier: .gregorian)
        var utcCalendar = calendar
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!

        let now = Date()
        return utcCalendar.startOfDay(for: now)
    }

    /// Get today's date as YYYY-MM-DD string in UTC
    /// - Returns: Today's date formatted for API filters
    static func todayUTCString() -> String {
        return formatDateOnly(todayUTC())
    }

    /// Check if a date is today (in local timezone)
    /// - Parameter date: Date to check
    /// - Returns: True if the date is today in local timezone
    static func isToday(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(date)
    }
}

// MARK: - Display Formatting

extension DateConverter {
    /// Format date for UI display (local timezone)
    /// - Parameter date: Date to format
    /// - Returns: Formatted string like "14:30" or "22. Okt. 2025"
    static func formatForDisplay(_ date: Date, style: DisplayStyle = .time) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.timeZone = TimeZone.current

        switch style {
        case .time:
            formatter.dateFormat = "HH:mm"
        case .dateShort:
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        case .dateMedium:
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
        case .dateTime:
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
        }

        return formatter.string(from: date)
    }

    enum DisplayStyle {
        case time           // "14:30"
        case dateShort      // "22.10.2025"
        case dateMedium     // "22. Okt. 2025"
        case dateTime       // "22. Okt. 2025, 14:30"
    }
}

// MARK: - Test Helpers

#if DEBUG
extension DateConverter {
    /// Create a date from components in UTC for testing
    static func makeUTCDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = TimeZone(identifier: "UTC")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: components)
    }
}
#endif
