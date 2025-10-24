//
//  ProjectRepository.swift
//  Momentchen
//
//  Created by Developer Agent on 24.10.2025.
//

import Foundation
import SwiftData
import OSLog

/// Repository for managing Project data with caching strategy
/// Implements cache-first pattern with 24-hour TTL for active projects
actor ProjectRepository {
    // MARK: - Properties

    private let modelContext: ModelContext
    private let apiService: NotionAPIServiceProtocol
    private let logger = Logger(subsystem: "com.momentchen.app", category: "ProjectRepository")

    // MARK: - Initialization

    /// Initialize repository with dependencies
    /// - Parameters:
    ///   - modelContext: SwiftData context for cache operations
    ///   - apiService: Notion API service for fetching projects
    init(modelContext: ModelContext, apiService: NotionAPIServiceProtocol) {
        self.modelContext = modelContext
        self.apiService = apiService
    }

    // MARK: - Public Methods

    /// Get projects using cache-first strategy
    /// Strategy:
    /// 1. Check cache - if fresh (<24h), return immediately
    /// 2. If stale, attempt API refresh with "In Bearbeitung" filter
    /// 3. On network error, return stale cache as fallback
    /// 4. Ultimate fallback: return empty array
    /// - Parameter filterActive: When true, only return projects with status "In Bearbeitung" (default: true)
    /// - Returns: Array of projects
    func getProjects(filterActive: Bool = true) async -> [Project] {
        logger.info("📂 Getting projects (filterActive: \(filterActive))")

        // Step 1: Check cache
        let cachedProjects = fetchCachedProjects()
        logger.debug("Found \(cachedProjects.count) cached projects")

        // Step 2: If cache is fresh, return immediately
        if !cachedProjects.isEmpty && !isCacheStale(cachedProjects) {
            logger.info("✅ Using fresh cache (\(cachedProjects.count) projects)")
            return cachedProjects.map { $0.toDomain() }
        }

        // Step 3: Cache is stale or missing - try API refresh
        logger.info("⚠️ Cache stale or missing, fetching from API")
        do {
            let freshProjects = try await refreshProjects(filterActive: filterActive)
            logger.info("✅ Successfully fetched \(freshProjects.count) projects from API")
            return freshProjects
        } catch {
            logger.error("❌ API fetch failed: \(error.localizedDescription)")

            // Step 4: Network error - return stale cache if available
            if !cachedProjects.isEmpty {
                logger.info("📦 Falling back to stale cache (\(cachedProjects.count) projects)")
                return cachedProjects.map { $0.toDomain() }
            }

            // Step 5: Ultimate fallback - return empty array
            logger.warning("⚠️ No cache available, returning empty array")
            return []
        }
    }

    /// Force refresh projects from API and update cache
    /// - Parameter filterActive: When true, only fetch projects with status "In Bearbeitung" (default: true)
    /// - Returns: Array of fresh projects
    /// - Throws: NotionAPIError if API call fails
    func refreshProjects(filterActive: Bool = true) async throws -> [Project] {
        logger.info("🔄 Force refreshing projects from API (filterActive: \(filterActive))")

        // Load configuration
        let config = try loadConfiguration()

        // Build filter for active projects
        let filter: NotionFilter? = filterActive ? .activeProjects() : nil

        // Fetch from API
        logger.debug("Calling API with databaseId: \(config.projectsDatabaseId)")
        let pages = try await apiService.queryDatabase(
            token: config.notionToken,
            databaseId: config.projectsDatabaseId,
            filter: filter,
            sorts: nil,
            pageSize: 100
        )
        logger.debug("Received \(pages.count) pages from API")

        // Convert to domain entities
        let projects = ProjectMapper.toDomain(pages)
        logger.info("✅ Mapped \(projects.count) projects from \(pages.count) pages")

        // Update cache
        await updateCache(with: projects)

        return projects
    }

    /// Clear all cached projects
    func clearCache() async {
        logger.info("🗑️ Clearing project cache")
        do {
            // Fetch all cache entries
            let descriptor = FetchDescriptor<ProjectCache>()
            let cachedProjects = try modelContext.fetch(descriptor)

            // Delete all
            for cached in cachedProjects {
                modelContext.delete(cached)
            }

            // Save changes
            try modelContext.save()
            logger.info("✅ Cache cleared successfully (\(cachedProjects.count) entries removed)")
        } catch {
            logger.error("❌ Failed to clear cache: \(error.localizedDescription)")
            // Silent failure - cache will be recreated on next fetch
        }
    }

    // MARK: - Private Methods

    /// Fetch cached projects from SwiftData
    /// - Returns: Array of cached projects
    private func fetchCachedProjects() -> [ProjectCache] {
        do {
            let descriptor = FetchDescriptor<ProjectCache>(
                sortBy: [SortDescriptor(\.title)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("❌ Failed to fetch cache: \(error.localizedDescription)")
            return []
        }
    }

    /// Check if any cached project is stale
    /// - Parameter cachedProjects: Cached projects to check
    /// - Returns: true if cache is stale
    private func isCacheStale(_ cachedProjects: [ProjectCache]) -> Bool {
        // If any project is stale, consider whole cache stale
        let isStale = cachedProjects.contains { $0.isStale }
        if isStale {
            logger.debug("Cache is stale")
        }
        return isStale
    }

    /// Update cache with fresh projects from API
    /// - Parameter projects: Fresh projects to cache
    private func updateCache(with projects: [Project]) async {
        logger.info("💾 Updating cache with \(projects.count) projects")
        do {
            // Clear existing cache
            let descriptor = FetchDescriptor<ProjectCache>()
            let existingCache = try modelContext.fetch(descriptor)
            for cached in existingCache {
                modelContext.delete(cached)
            }
            logger.debug("Cleared \(existingCache.count) old cache entries")

            // Insert new cache entries
            let now = Date()
            for project in projects {
                let cached = ProjectCache(
                    id: project.id,
                    title: project.title,
                    lastFetched: now
                )
                modelContext.insert(cached)
            }

            // Save changes
            try modelContext.save()
            logger.info("✅ Cache updated successfully")
        } catch {
            logger.error("❌ Failed to update cache: \(error.localizedDescription)")
            // Silent failure - next fetch will retry
        }
    }

    /// Load app configuration from SwiftData
    /// - Returns: App configuration
    /// - Throws: NotionAPIError if configuration not found
    private func loadConfiguration() throws -> AppConfiguration {
        let descriptor = FetchDescriptor<AppConfiguration>()
        let configs = try modelContext.fetch(descriptor)

        guard let config = configs.first else {
            logger.error("❌ No configuration found")
            throw NotionAPIError.validationError(message: "Keine Konfiguration gefunden")
        }

        return config
    }
}

// MARK: - Test Helpers

#if DEBUG
extension ProjectRepository {
    /// Create a mock repository for testing
    static func mock(
        modelContext: ModelContext? = nil,
        apiService: NotionAPIServiceProtocol? = nil
    ) -> ProjectRepository {
        let mockContext = modelContext ?? (try! ModelContext(
            ModelContainer(
                for: ProjectCache.self, AppConfiguration.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        ))

        let mockService = apiService ?? NotionAPIService.mock()

        return ProjectRepository(modelContext: mockContext, apiService: mockService)
    }
}
#endif
