//
//  ProjectCache.swift
//  Momentchen
//
//  Created by Developer Agent on 24.10.2025.
//

import Foundation
import SwiftData

/// SwiftData model for caching Project data from Notion API
/// Implements a 24-hour TTL caching strategy to reduce API calls
@Model
final class ProjectCache {
    // MARK: - Properties

    /// Unique identifier (same as Notion Page ID)
    @Attribute(.unique) var id: String

    /// Project name/title
    var title: String

    /// Timestamp when this cache entry was last fetched from API
    var lastFetched: Date

    // MARK: - Constants

    /// Cache Time-To-Live: 24 hours
    static let cacheTTL: TimeInterval = 86400

    // MARK: - Initialization

    /// Initialize a new ProjectCache entry
    /// - Parameters:
    ///   - id: Unique identifier (Notion Page ID)
    ///   - title: Project name
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
    /// - Returns: Project domain entity
    func toDomain() -> Project {
        Project(id: id, title: title)
    }
}

// MARK: - Factory Methods

extension ProjectCache {
    /// Create cache entry from domain entity
    /// - Parameter project: Domain entity to cache
    /// - Returns: New cache entry
    static func fromDomain(_ project: Project) -> ProjectCache {
        ProjectCache(
            id: project.id,
            title: project.title
        )
    }
}

// MARK: - Test Helpers

#if DEBUG
extension ProjectCache {
    /// Create a mock cache entry for testing
    static func mock(
        id: String = "mock-project-id",
        title: String = "Test Project",
        lastFetched: Date = Date()
    ) -> ProjectCache {
        ProjectCache(id: id, title: title, lastFetched: lastFetched)
    }

    /// Create a stale cache entry for testing
    static func stale() -> ProjectCache {
        let staleDate = Date().addingTimeInterval(-ProjectCache.cacheTTL - 3600) // 25 hours ago
        return ProjectCache(
            id: "stale-project-id",
            title: "Stale Project",
            lastFetched: staleDate
        )
    }
}
#endif
