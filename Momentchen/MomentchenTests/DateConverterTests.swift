//
//  DateConverterTests.swift
//  MomentchenTests
//
//  Created by Test Architect on 22.10.2025.
//

import XCTest
@testable import Momentchen

final class DateConverterTests: XCTestCase {

    // MARK: - parseFromAPI Tests

    func testParseFromAPI_WithTimezoneOffset() {
        // Given: Notion's preferred format with timezone offset and milliseconds
        let dateString = "2025-10-22T14:59:00.000+00:00"

        // When
        let result = DateConverter.parseFromAPI(dateString)

        // Then
        XCTAssertNotNil(result, "Should parse date with timezone offset format")

        // Verify the parsed date components (in UTC)
        if let date = result {
            let calendar = Calendar(identifier: .gregorian)
            var utcCalendar = calendar
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!

            let components = utcCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            XCTAssertEqual(components.year, 2025)
            XCTAssertEqual(components.month, 10)
            XCTAssertEqual(components.day, 22)
            XCTAssertEqual(components.hour, 14)
            XCTAssertEqual(components.minute, 59)
        }
    }

    func testParseFromAPI_WithZTimezone() {
        // Given: Standard ISO8601 format with Z
        let dateString = "2025-10-22T14:59:00.000Z"

        // When
        let result = DateConverter.parseFromAPI(dateString)

        // Then
        XCTAssertNotNil(result, "Should parse date with Z timezone format")

        if let date = result {
            let calendar = Calendar(identifier: .gregorian)
            var utcCalendar = calendar
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!

            let components = utcCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            XCTAssertEqual(components.year, 2025)
            XCTAssertEqual(components.month, 10)
            XCTAssertEqual(components.day, 22)
            XCTAssertEqual(components.hour, 14)
            XCTAssertEqual(components.minute, 59)
        }
    }

    func testParseFromAPI_WithoutFractionalSeconds() {
        // Given: ISO8601 without milliseconds
        let dateString = "2025-10-22T14:59:00Z"

        // When
        let result = DateConverter.parseFromAPI(dateString)

        // Then
        XCTAssertNotNil(result, "Should parse date without fractional seconds")
    }

    func testParseFromAPI_DateOnly() {
        // Given: Date-only format (fallback)
        let dateString = "2025-10-22"

        // When
        let result = DateConverter.parseFromAPI(dateString)

        // Then
        XCTAssertNotNil(result, "Should parse date-only format as fallback")

        if let date = result {
            let calendar = Calendar(identifier: .gregorian)
            var utcCalendar = calendar
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!

            let components = utcCalendar.dateComponents([.year, .month, .day], from: date)
            XCTAssertEqual(components.year, 2025)
            XCTAssertEqual(components.month, 10)
            XCTAssertEqual(components.day, 22)
        }
    }

    func testParseFromAPI_InvalidFormat() {
        // Given: Invalid date string
        let dateString = "not-a-date"

        // When
        let result = DateConverter.parseFromAPI(dateString)

        // Then
        XCTAssertNil(result, "Should return nil for invalid format")
    }

    func testParseFromAPI_EmptyString() {
        // Given: Empty string
        let dateString = ""

        // When
        let result = DateConverter.parseFromAPI(dateString)

        // Then
        XCTAssertNil(result, "Should return nil for empty string")
    }

    func testParseFromAPI_DifferentTimezoneOffsets() {
        // Given: Various timezone offset formats
        let testCases = [
            "2025-10-22T14:59:00.000+01:00",  // +01:00
            "2025-10-22T14:59:00.000-05:00",  // -05:00
            "2025-10-22T14:59:00.000+00:00"   // UTC
        ]

        // When/Then
        for dateString in testCases {
            let result = DateConverter.parseFromAPI(dateString)
            XCTAssertNotNil(result, "Should parse timezone offset: \(dateString)")
        }
    }

    // MARK: - formatForAPI Tests

    func testFormatForAPI_ProducesValidISO8601() {
        // Given
        let date = DateConverter.makeUTCDate(year: 2025, month: 10, day: 22, hour: 14, minute: 59)!

        // When
        let formatted = DateConverter.formatForAPI(date)

        // Then
        XCTAssertTrue(formatted.contains("2025-10-22"))
        XCTAssertTrue(formatted.contains("T"))
        XCTAssertTrue(formatted.hasSuffix("Z") || formatted.contains("+"))

        // Verify round-trip
        let parsed = DateConverter.parseFromAPI(formatted)
        XCTAssertNotNil(parsed)
    }

    func testFormatForAPI_RoundTrip() {
        // Given
        let originalDate = Date()

        // When
        let formatted = DateConverter.formatForAPI(originalDate)
        let parsed = DateConverter.parseFromAPI(formatted)

        // Then
        XCTAssertNotNil(parsed)
        if let parsed = parsed {
            // Allow 1 second tolerance for rounding
            XCTAssertEqual(originalDate.timeIntervalSince1970,
                          parsed.timeIntervalSince1970,
                          accuracy: 1.0,
                          "Round-trip should preserve date within 1 second")
        }
    }

    // MARK: - formatDateOnly Tests

    func testFormatDateOnly_ProducesCorrectFormat() {
        // Given
        let date = DateConverter.makeUTCDate(year: 2025, month: 10, day: 22)!

        // When
        let formatted = DateConverter.formatDateOnly(date)

        // Then
        XCTAssertEqual(formatted, "2025-10-22")
    }

    // MARK: - todayUTC Tests

    func testTodayUTC_ReturnsStartOfDay() {
        // When
        let today = DateConverter.todayUTC()

        // Then
        let calendar = Calendar(identifier: .gregorian)
        var utcCalendar = calendar
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!

        let components = utcCalendar.dateComponents([.hour, .minute, .second], from: today)
        XCTAssertEqual(components.hour, 0, "Should be midnight")
        XCTAssertEqual(components.minute, 0, "Should be midnight")
        XCTAssertEqual(components.second, 0, "Should be midnight")
    }

    func testTodayUTCString_ProducesValidDateString() {
        // When
        let todayString = DateConverter.todayUTCString()

        // Then
        let regex = "^\\d{4}-\\d{2}-\\d{2}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        XCTAssertTrue(predicate.evaluate(with: todayString),
                     "Should match YYYY-MM-DD format")
    }

    // MARK: - isToday Tests

    func testIsToday_WithTodaysDate() {
        // Given
        let now = Date()

        // When
        let result = DateConverter.isToday(now)

        // Then
        XCTAssertTrue(result, "Current date should be recognized as today")
    }

    func testIsToday_WithYesterdaysDate() {
        // Given
        let yesterday = Date(timeIntervalSinceNow: -86400) // 24 hours ago

        // When
        let result = DateConverter.isToday(yesterday)

        // Then
        XCTAssertFalse(result, "Yesterday should not be recognized as today")
    }
}
