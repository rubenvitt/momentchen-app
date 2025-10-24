//
//  LifeArea.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation

/// Domain model representing a Life Area (Lebensbereich) from Notion
/// Life areas are used to categorize moments by life themes
struct LifeArea: Identifiable, Sendable, Equatable, Hashable {
    // MARK: - Properties

    /// Unique identifier (Notion Page ID)
    let id: String

    /// Life area name/title (e.g., "Gesundheit", "Karriere")
    let title: String

    // MARK: - Initialization

    /// Initialize a LifeArea
    /// - Parameters:
    ///   - id: Unique identifier from Notion
    ///   - title: Life area name
    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

// MARK: - Test Helpers

#if DEBUG
extension LifeArea {
    /// Create a mock LifeArea for testing
    static func mock(
        id: String = "mock-lifearea-id",
        title: String = "Test Life Area"
    ) -> LifeArea {
        LifeArea(id: id, title: title)
    }
}
#endif
