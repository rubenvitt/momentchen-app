//
//  Moment.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation

/// Domain model representing a single Moment entry
/// This is a plain struct that represents business logic, not tied to any persistence layer
struct Moment: Identifiable, Sendable, Equatable {
    // MARK: - Properties

    /// Unique identifier (Notion Page ID)
    let id: String

    /// Description/title of the moment
    let title: String

    /// Type of moment (e.g., Gedanke, Erlebnis, Aktivität)
    let type: MomentType

    /// Timestamp when the moment occurred (stored as UTC, displayed as local)
    let timestamp: Date

    /// Category assignment (project, life area, or none)
    let category: MomentCategory

    // MARK: - Review Properties

    /// Marked as daily favorite (⭐ Tagesfavorit)
    let isDailyFavorite: Bool

    /// Marked as weekly favorite (⭐ Wochenfavorit)
    let isWeeklyFavorite: Bool

    /// Marked as monthly favorite (⭐ Monatsfavorit)
    let isMonthlyFavorite: Bool

    /// Marked as yearly favorite (⭐ Jahresfavorit)
    let isYearlyFavorite: Bool

    /// Marked as lifetime moment (Moment meines Lebens)
    let isLifetimeMoment: Bool

    /// Computed highest review level ("01-leben", "02-jahr", "03-monat", "04-woche", "05-tag", or empty)
    let highestReviewLevel: String

    // MARK: - Initialization

    /// Initialize a Moment with all properties
    /// - Parameters:
    ///   - id: Unique identifier from Notion
    ///   - title: Description of the moment
    ///   - type: Type categorization
    ///   - timestamp: When the moment occurred (UTC)
    ///   - category: Category assignment (default: .none)
    ///   - isDailyFavorite: Daily review marker (default: false)
    ///   - isWeeklyFavorite: Weekly review marker (default: false)
    ///   - isMonthlyFavorite: Monthly review marker (default: false)
    ///   - isYearlyFavorite: Yearly review marker (default: false)
    ///   - isLifetimeMoment: Lifetime moment marker (default: false)
    ///   - highestReviewLevel: Computed highest review level (default: "")
    init(
        id: String,
        title: String,
        type: MomentType,
        timestamp: Date,
        category: MomentCategory = .none,
        isDailyFavorite: Bool = false,
        isWeeklyFavorite: Bool = false,
        isMonthlyFavorite: Bool = false,
        isYearlyFavorite: Bool = false,
        isLifetimeMoment: Bool = false,
        highestReviewLevel: String = ""
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.timestamp = timestamp
        self.category = category
        self.isDailyFavorite = isDailyFavorite
        self.isWeeklyFavorite = isWeeklyFavorite
        self.isMonthlyFavorite = isMonthlyFavorite
        self.isYearlyFavorite = isYearlyFavorite
        self.isLifetimeMoment = isLifetimeMoment
        self.highestReviewLevel = highestReviewLevel
    }
}

// MARK: - Test Helpers

#if DEBUG
extension Moment {
    /// Create a mock Moment for testing
    static func mock(
        id: String = "mock-moment-id",
        title: String = "Test Moment",
        type: MomentType = .gedanke,
        timestamp: Date = Date(),
        category: MomentCategory = .none,
        isDailyFavorite: Bool = false,
        isWeeklyFavorite: Bool = false,
        isMonthlyFavorite: Bool = false,
        isYearlyFavorite: Bool = false,
        isLifetimeMoment: Bool = false,
        highestReviewLevel: String = ""
    ) -> Moment {
        Moment(
            id: id,
            title: title,
            type: type,
            timestamp: timestamp,
            category: category,
            isDailyFavorite: isDailyFavorite,
            isWeeklyFavorite: isWeeklyFavorite,
            isMonthlyFavorite: isMonthlyFavorite,
            isYearlyFavorite: isYearlyFavorite,
            isLifetimeMoment: isLifetimeMoment,
            highestReviewLevel: highestReviewLevel
        )
    }
}
#endif
