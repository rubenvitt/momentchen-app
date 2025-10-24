//
//  LifeAreaRepository.swift
//  Momentchen
//
//  Created by Developer Agent on 24.10.2025.
//

import Foundation
import SwiftData
import OSLog

/// Repository for managing LifeArea data with caching strategy
/// Implements cache-first pattern with 24-hour TTL and stale-while-revalidate fallback
actor LifeAreaRepository {
    // MARK: - Properties

    private let modelContext: ModelContext
    private let apiService: NotionAPIServiceProtocol
    private let logger = Logger(subsystem: "com.momentchen.app", category: "LifeAreaRepository")

    // MARK: - Initialization

    /// Initialize repository with dependencies
    /// - Parameters:
    ///   - modelContext: SwiftData context for cache operations
    ///   - apiService: Notion API service for fetching life areas
    init(modelContext: ModelContext, apiService: NotionAPIServiceProtocol) {
        self.modelContext = modelContext
        self.apiService = apiService
    }

    // MARK: - Public Methods

    /// Get life areas using cache-first strategy with active filter
    /// Strategy:
    /// 1. Check cache - if fresh (<24h), return immediately
    /// 2. If stale, attempt API refresh with "Aktiv" filter
    /// 3. On network error, return stale cache as fallback
    /// 4. Ultimate fallback: return empty array
    /// - Parameter filterActive: If true, only return active life areas (default: true)
    /// - Returns: Array of life areas
    func getLifeAreas(filterActive: Bool = true) async -> [LifeArea] {
        logger.info("📥 Getting life areas (filterActive: \(filterActive))")

        // Step 1: Check cache
        let cachedLifeAreas = fetchCachedLifeAreas()

        // Step 2: If cache is fresh, return immediately
        if !cachedLifeAreas.isEmpty && !isCacheStale(cachedLifeAreas) {
            logger.info("✅ Cache hit: returning \(cachedLifeAreas.count) cached life areas")
            return cachedLifeAreas.map { $0.toDomain() }
        }

        // Step 3: Cache is stale or missing - try API refresh
        do {
            let freshLifeAreas = try await refreshLifeAreas(filterActive: filterActive)
            logger.info("✅ API refresh successful: \(freshLifeAreas.count) life areas")
            return freshLifeAreas
        } catch {
            logger.warning("⚠️ API refresh failed: \(error.localizedDescription)")

            // Step 4: Network error - return stale cache if available
            if !cachedLifeAreas.isEmpty {
                logger.info("📦 Returning stale cache as fallback: \(cachedLifeAreas.count) life areas")
                return cachedLifeAreas.map { $0.toDomain() }
            }

            // Step 5: Ultimate fallback - return empty array
            logger.warning("❌ No cache available, returning empty array")
            return []
        }
    }

    /// Force refresh life areas from API and update cache
    /// - Parameter filterActive: If true, only fetch active life areas (default: true)
    /// - Returns: Array of fresh life areas
    /// - Throws: NotionAPIError if API call fails
    func refreshLifeAreas(filterActive: Bool = true) async throws -> [LifeArea] {
        logger.info("🔄 Refreshing life areas from API (filterActive: \(filterActive))")

        // Load configuration
        let config = try loadConfiguration()

        // Prepare filter for active life areas
        let filter: NotionFilter? = filterActive ? .activeLifeAreas() : nil

        // Fetch from API
        let pages = try await apiService.queryDatabase(
            token: config.notionToken,
            databaseId: config.lifeAreasDatabaseId,
            filter: filter,
            sorts: nil,
            pageSize: 100
        )

        logger.info("📡 Fetched \(pages.count) pages from Notion API")

        // Convert to domain entities
        let lifeAreas = LifeAreaMapper.toDomain(pages)
        logger.info("🔄 Mapped to \(lifeAreas.count) life area entities")

        // Update cache
        await updateCache(with: lifeAreas)

        return lifeAreas
    }

    /// Clear all cached life areas
    func clearCache() async {
        logger.info("🗑️ Clearing life area cache")

        do {
            // Fetch all cache entries
            let descriptor = FetchDescriptor<LifeAreaCache>()
            let cachedLifeAreas = try modelContext.fetch(descriptor)

            logger.info("Found \(cachedLifeAreas.count) cached entries to delete")

            // Delete all
            for cached in cachedLifeAreas {
                modelContext.delete(cached)
            }

            // Save changes
            try modelContext.save()
            logger.info("✅ Cache cleared successfully")
        } catch {
            logger.error("❌ Failed to clear cache: \(error.localizedDescription)")
            // Silent failure - cache will be recreated on next fetch
        }
    }

    // MARK: - Private Methods

    /// Fetch cached life areas from SwiftData
    /// - Returns: Array of cached life areas
    private func fetchCachedLifeAreas() -> [LifeAreaCache] {
        do {
            let descriptor = FetchDescriptor<LifeAreaCache>(
                sortBy: [SortDescriptor(\.title)]
            )
            let cached = try modelContext.fetch(descriptor)
            logger.debug("📦 Fetched \(cached.count) life areas from cache")
            return cached
        } catch {
            logger.error("❌ Failed to fetch cached life areas: \(error.localizedDescription)")
            return []
        }
    }

    /// Check if any cached life area is stale
    /// - Parameter cachedLifeAreas: Cached life areas to check
    /// - Returns: true if cache is stale
    private func isCacheStale(_ cachedLifeAreas: [LifeAreaCache]) -> Bool {
        // If any life area is stale, consider whole cache stale
        let isStale = cachedLifeAreas.contains { $0.isStale }
        if isStale {
            logger.debug("⏰ Cache is stale")
        }
        return isStale
    }

    /// Update cache with fresh life areas from API
    /// - Parameter lifeAreas: Fresh life areas to cache
    private func updateCache(with lifeAreas: [LifeArea]) async {
        logger.info("💾 Updating cache with \(lifeAreas.count) life areas")

        do {
            // Clear existing cache
            let descriptor = FetchDescriptor<LifeAreaCache>()
            let existingCache = try modelContext.fetch(descriptor)
            for cached in existingCache {
                modelContext.delete(cached)
            }

            // Insert new cache entries
            let now = Date()
            for lifeArea in lifeAreas {
                let cached = LifeAreaCache(
                    id: lifeArea.id,
                    title: lifeArea.title,
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
            logger.error("❌ No configuration found in database")
            throw NotionAPIError.validationError(message: "Keine Konfiguration gefunden")
        }

        return config
    }
}

// MARK: - Test Helpers

#if DEBUG
extension LifeAreaRepository {
    /// Create a mock repository for testing
    static func mock(
        modelContext: ModelContext? = nil,
        apiService: NotionAPIServiceProtocol? = nil
    ) -> LifeAreaRepository {
        let mockContext = modelContext ?? (try! ModelContext(
            ModelContainer(
                for: LifeAreaCache.self, AppConfiguration.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        ))

        let mockService = apiService ?? NotionAPIService.mock()

        return LifeAreaRepository(modelContext: mockContext, apiService: mockService)
    }
}
#endif
