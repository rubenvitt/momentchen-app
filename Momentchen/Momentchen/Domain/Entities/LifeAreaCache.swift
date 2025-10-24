//
//  LifeAreaCache.swift
//  Momentchen
//
//  Created by Developer Agent on 24.10.2025.
//

import Foundation
import SwiftData

/// SwiftData model for caching LifeArea data from Notion API
/// Implements a 24-hour TTL caching strategy to reduce API calls
@Model
final class LifeAreaCache {
    // MARK: - Properties

    /// Unique identifier (same as Notion Page ID)
    @Attribute(.unique) var id: String

    /// Life area name/title
    var title: String

    /// Timestamp when this cache entry was last fetched from API
    var lastFetched: Date

    // MARK: - Constants

    /// Cache Time-To-Live: 24 hours
    static let cacheTTL: TimeInterval = 86400

    // MARK: - Initialization

    /// Initialize a new LifeAreaCache entry
    /// - Parameters:
    ///   - id: Unique identifier (Notion Page ID)
    ///   - title: Life area name
    ///   - lastFetched: Timestamp of cache creation
    init(id: String, title: String, lastFetched: Date = Date()) {
        self.id = id
        self.title = title
        self.lastFetched = lastFetched
    }

    // MARK: - Computed Properties

    /// Check if cache entry is stale (older than 24 hours)
    var isStale: Bool {
        Date().timeIntervalSince(lastFetched) > Self.cacheTTL
    }

    // MARK: - Domain Conversion

    /// Convert cached entry to domain entity
    /// - Returns: LifeArea domain entity
    func toDomain() -> LifeArea {
        LifeArea(id: id, title: title)
    }
}

// MARK: - Factory Methods

extension LifeAreaCache {
    /// Create cache entry from domain entity
    /// - Parameter lifeArea: Domain entity to cache
    /// - Returns: New cache entry
    static func fromDomain(_ lifeArea: LifeArea) -> LifeAreaCache {
        LifeAreaCache(
            id: lifeArea.id,
            title: lifeArea.title
        )
    }
}

// MARK: - Test Helpers

#if DEBUG
extension LifeAreaCache {
    /// Create a mock cache entry for testing
    static func mock(
        id: String = "mock-lifearea-id",
        title: String = "Test Life Area",
        lastFetched: Date = Date()
    ) -> LifeAreaCache {
        LifeAreaCache(id: id, title: title, lastFetched: lastFetched)
    }

    /// Create a stale cache entry for testing
    static func stale() -> LifeAreaCache {
        let staleDate = Date().addingTimeInterval(-LifeAreaCache.cacheTTL - 3600) // 25 hours ago
        return LifeAreaCache(
            id: "stale-lifearea-id",
            title: "Stale Life Area",
            lastFetched: staleDate
        )
    }
}
#endif
