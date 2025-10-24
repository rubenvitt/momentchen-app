//
//  MomentTypeCache.swift
//  Momentchen
//
//  Created by Developer Agent on 23.10.2025.
//

import Foundation
import SwiftData

/// SwiftData model for caching MomentType data from Notion API
/// Implements a 24-hour TTL caching strategy to reduce API calls
@Model
final class MomentTypeCache {
    // MARK: - Properties

    /// Unique identifier (same as type name)
    @Attribute(.unique) var id: String

    /// Type name (e.g., "Gedanke", "Erlebnis")
    var name: String

    /// Notion color as raw string value
    var colorRaw: String

    /// Timestamp when this cache entry was last fetched from API
    var lastFetched: Date

    // MARK: - Constants

    /// Cache Time-To-Live: 24 hours
    static let cacheTTL: TimeInterval = 86400

    // MARK: - Initialization

    /// Initialize a new MomentTypeCache entry
    /// - Parameters:
    ///   - id: Unique identifier (type name)
    ///   - name: Type name
    ///   - colorRaw: Notion color raw value
    ///   - lastFetched: Timestamp of cache creation
    init(id: String, name: String, colorRaw: String, lastFetched: Date = Date()) {
        self.id = id
        self.name = name
        self.colorRaw = colorRaw
        self.lastFetched = lastFetched
    }

    // MARK: - Computed Properties

    /// Check if cache entry is stale (older than 24 hours)
    var isStale: Bool {
        Date().timeIntervalSince(lastFetched) > Self.cacheTTL
    }

    // MARK: - Domain Conversion

    /// Convert cached entry to domain entity
    /// - Returns: MomentType domain entity
    func toDomain() -> MomentType {
        let color = NotionColor(rawValue: colorRaw) ?? .default
        return MomentType(name: name, color: color)
    }
}

// MARK: - Factory Methods

extension MomentTypeCache {
    /// Create cache entry from domain entity
    /// - Parameter momentType: Domain entity to cache
    /// - Returns: New cache entry
    static func fromDomain(_ momentType: MomentType) -> MomentTypeCache {
        MomentTypeCache(
            id: momentType.id,
            name: momentType.name,
            colorRaw: momentType.color.rawValue
        )
    }
}

// MARK: - Test Helpers

#if DEBUG
extension MomentTypeCache {
    /// Create a mock cache entry for testing
    static func mock(
        id: String = "Test",
        name: String = "Test Type",
        colorRaw: String = "blue",
        lastFetched: Date = Date()
    ) -> MomentTypeCache {
        MomentTypeCache(id: id, name: name, colorRaw: colorRaw, lastFetched: lastFetched)
    }

    /// Create a stale cache entry for testing
    static func stale() -> MomentTypeCache {
        let staleDate = Date().addingTimeInterval(-MomentTypeCache.cacheTTL - 3600) // 25 hours ago
        return MomentTypeCache(
            id: "Stale",
            name: "Stale Type",
            colorRaw: "gray",
            lastFetched: staleDate
        )
    }
}
#endif
