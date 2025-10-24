//
//  MomentTypeRepository.swift
//  Momentchen
//
//  Created by Developer Agent on 23.10.2025.
//

import Foundation
import SwiftData

/// Repository for managing MomentType data with caching strategy
/// Implements cache-first pattern with 24-hour TTL and stale-while-revalidate fallback
actor MomentTypeRepository {
    // MARK: - Properties

    private let modelContext: ModelContext
    private let apiService: NotionAPIServiceProtocol

    // Default types to use as ultimate fallback
    private static let defaultTypes: [MomentType] = [
        .gedanke, .erlebnis, .aktivität, .idee, .emotion, .lernen
    ]

    // MARK: - Initialization

    /// Initialize repository with dependencies
    /// - Parameters:
    ///   - modelContext: SwiftData context for cache operations
    ///   - apiService: Notion API service for fetching types
    init(modelContext: ModelContext, apiService: NotionAPIServiceProtocol) {
        self.modelContext = modelContext
        self.apiService = apiService
    }

    // MARK: - Public Methods

    /// Get moment types using cache-first strategy
    /// Strategy:
    /// 1. Check cache - if fresh (<24h), return immediately
    /// 2. If stale, attempt API refresh
    /// 3. On network error, return stale cache as fallback
    /// 4. Ultimate fallback: return default types
    /// - Returns: Array of moment types
    func getTypes() async -> [MomentType] {
        // Step 1: Check cache
        let cachedTypes = fetchCachedTypes()

        // Step 2: If cache is fresh, return immediately
        if !cachedTypes.isEmpty && !isCacheStale(cachedTypes) {
            return cachedTypes.map { $0.toDomain() }
        }

        // Step 3: Cache is stale or missing - try API refresh
        do {
            let freshTypes = try await refreshTypes()
            return freshTypes
        } catch {
            // Step 4: Network error - return stale cache if available
            if !cachedTypes.isEmpty {
                return cachedTypes.map { $0.toDomain() }
            }

            // Step 5: Ultimate fallback - return defaults
            return Self.defaultTypes
        }
    }

    /// Force refresh types from API and update cache
    /// - Returns: Array of fresh moment types
    /// - Throws: NotionAPIError if API call fails
    func refreshTypes() async throws -> [MomentType] {
        // Load configuration
        let config = try loadConfiguration()

        // Fetch from API
        let options = try await apiService.getSelectOptions(
            token: config.notionToken,
            databaseId: config.momentsDatabaseId,
            propertyName: "Typ"
        )

        // Convert to domain entities
        let momentTypes = options.map { option in
            MomentType(
                name: option.name,
                color: NotionColor(rawValue: option.color ?? "default") ?? .default
            )
        }

        // Update cache
        await updateCache(with: momentTypes)

        return momentTypes
    }

    /// Clear all cached moment types
    func clearCache() async {
        do {
            // Fetch all cache entries
            let descriptor = FetchDescriptor<MomentTypeCache>()
            let cachedTypes = try modelContext.fetch(descriptor)

            // Delete all
            for cached in cachedTypes {
                modelContext.delete(cached)
            }

            // Save changes
            try modelContext.save()
        } catch {
            // Silent failure - cache will be recreated on next fetch
        }
    }

    // MARK: - Private Methods

    /// Fetch cached types from SwiftData
    /// - Returns: Array of cached moment types
    private func fetchCachedTypes() -> [MomentTypeCache] {
        do {
            let descriptor = FetchDescriptor<MomentTypeCache>(
                sortBy: [SortDescriptor(\.name)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }

    /// Check if any cached type is stale
    /// - Parameter cachedTypes: Cached types to check
    /// - Returns: true if cache is stale
    private func isCacheStale(_ cachedTypes: [MomentTypeCache]) -> Bool {
        // If any type is stale, consider whole cache stale
        cachedTypes.contains { $0.isStale }
    }

    /// Update cache with fresh types from API
    /// - Parameter types: Fresh moment types to cache
    private func updateCache(with types: [MomentType]) async {
        do {
            // Clear existing cache
            let descriptor = FetchDescriptor<MomentTypeCache>()
            let existingCache = try modelContext.fetch(descriptor)
            for cached in existingCache {
                modelContext.delete(cached)
            }

            // Insert new cache entries
            let now = Date()
            for type in types {
                let cached = MomentTypeCache(
                    id: type.id,
                    name: type.name,
                    colorRaw: type.color.rawValue,
                    lastFetched: now
                )
                modelContext.insert(cached)
            }

            // Save changes
            try modelContext.save()
        } catch {
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
            throw NotionAPIError.validationError(message: "Keine Konfiguration gefunden")
        }

        return config
    }
}

// MARK: - Test Helpers

#if DEBUG
extension MomentTypeRepository {
    /// Create a mock repository for testing
    static func mock(
        modelContext: ModelContext? = nil,
        apiService: NotionAPIServiceProtocol? = nil
    ) -> MomentTypeRepository {
        let mockContext = modelContext ?? (try! ModelContext(
            ModelContainer(
                for: MomentTypeCache.self, AppConfiguration.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        ))

        let mockService = apiService ?? NotionAPIService.mock()

        return MomentTypeRepository(modelContext: mockContext, apiService: mockService)
    }
}
#endif
