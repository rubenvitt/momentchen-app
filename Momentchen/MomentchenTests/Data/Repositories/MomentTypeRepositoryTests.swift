//
//  MomentTypeRepositoryTests.swift
//  MomentchenTests
//
//  Created by Test Architect on 23.10.2025.
//

import XCTest
import SwiftData
@testable import Momentchen

final class MomentTypeRepositoryTests: XCTestCase {
    // MARK: - Properties

    var repository: MomentTypeRepository!
    var modelContext: ModelContext!
    var mockAPIService: MockNotionAPIService!

    // MARK: - Setup/Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory model container for testing
        let container = try ModelContainer(
            for: MomentTypeCache.self, AppConfiguration.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        modelContext = ModelContext(container)

        // Create mock API service
        mockAPIService = MockNotionAPIService()

        // Create test configuration
        let config = AppConfiguration(
            notionToken: "test-token",
            momentsDatabaseId: "test-moments-db",
            projectsDatabaseId: "test-projects-db",
            lifeAreasDatabaseId: "test-lifeareas-db"
        )
        modelContext.insert(config)
        try modelContext.save()

        // Create repository
        repository = MomentTypeRepository(
            modelContext: modelContext,
            apiService: mockAPIService
        )
    }

    override func tearDown() async throws {
        repository = nil
        mockAPIService = nil
        modelContext = nil
        try await super.tearDown()
    }

    // MARK: - Test Cases

    /// AC1: Types load instantly from cache (<100ms) when available
    func testGetTypes_CacheHit_ReturnsImmediately() async throws {
        // Given: Fresh cached types
        let cachedTypes = [
            MomentTypeCache(id: "Gedanke", name: "Gedanke", colorRaw: "blue"),
            MomentTypeCache(id: "Erlebnis", name: "Erlebnis", colorRaw: "green")
        ]
        for cached in cachedTypes {
            modelContext.insert(cached)
        }
        try modelContext.save()

        // When: Measuring time to fetch
        let start = Date()
        let types = await repository.getTypes()
        let duration = Date().timeIntervalSince(start)

        // Then: Returns instantly (<100ms)
        XCTAssertLessThan(duration, 0.1, "Cache hit should return in <100ms")
        XCTAssertEqual(types.count, 2)
        XCTAssertEqual(types[0].name, "Gedanke")
        XCTAssertEqual(types[1].name, "Erlebnis")
        XCTAssertEqual(mockAPIService.getSelectOptionsCallCount, 0, "Should not call API on cache hit")
    }

    /// AC2: Cache miss triggers API fetch
    func testGetTypes_CacheMiss_FetchesFromAPI() async throws {
        // Given: No cached types
        // Mock API returns types
        mockAPIService.mockSelectOptions = [
            NotionSelectOption(name: "Gedanke", color: "blue"),
            NotionSelectOption(name: "Idee", color: "yellow")
        ]

        // When
        let types = await repository.getTypes()

        // Then: Calls API and returns types
        XCTAssertEqual(mockAPIService.getSelectOptionsCallCount, 1)
        XCTAssertEqual(types.count, 2)
        XCTAssertEqual(types[0].name, "Gedanke")
        XCTAssertEqual(types[1].name, "Idee")

        // Verify cache was populated
        let descriptor = FetchDescriptor<MomentTypeCache>()
        let cachedTypes = try modelContext.fetch(descriptor)
        XCTAssertEqual(cachedTypes.count, 2)
    }

    /// AC2: Stale cache triggers refresh in background
    func testGetTypes_StaleCache_RefetchesFromAPI() async throws {
        // Given: Stale cached types (>24h old)
        let staleDate = Date().addingTimeInterval(-MomentTypeCache.cacheTTL - 3600) // 25h ago
        let staleCached = MomentTypeCache(
            id: "OldType",
            name: "Old Type",
            colorRaw: "gray",
            lastFetched: staleDate
        )
        modelContext.insert(staleCached)
        try modelContext.save()

        // Mock API returns fresh types
        mockAPIService.mockSelectOptions = [
            NotionSelectOption(name: "NewType", color: "blue")
        ]

        // When
        let types = await repository.getTypes()

        // Then: Fetches fresh data from API
        XCTAssertEqual(mockAPIService.getSelectOptionsCallCount, 1)
        XCTAssertEqual(types.count, 1)
        XCTAssertEqual(types[0].name, "NewType")

        // Verify cache was updated
        let descriptor = FetchDescriptor<MomentTypeCache>()
        let cachedTypes = try modelContext.fetch(descriptor)
        XCTAssertEqual(cachedTypes.count, 1)
        XCTAssertEqual(cachedTypes[0].name, "NewType")
    }

    /// AC3: Network error returns stale cache as fallback
    func testGetTypes_NetworkError_ReturnsStaleCacheAsFallback() async throws {
        // Given: Stale cached types
        let staleDate = Date().addingTimeInterval(-MomentTypeCache.cacheTTL - 3600)
        let staleCached = [
            MomentTypeCache(id: "Cached1", name: "Cached Type 1", colorRaw: "blue", lastFetched: staleDate),
            MomentTypeCache(id: "Cached2", name: "Cached Type 2", colorRaw: "green", lastFetched: staleDate)
        ]
        for cached in staleCached {
            modelContext.insert(cached)
        }
        try modelContext.save()

        // Mock API throws error
        mockAPIService.shouldThrowError = true

        // When
        let types = await repository.getTypes()

        // Then: Returns stale cache as fallback
        XCTAssertEqual(types.count, 2)
        XCTAssertEqual(types[0].name, "Cached Type 1")
        XCTAssertEqual(types[1].name, "Cached Type 2")
    }

    /// Test: Network error with no cache returns defaults
    func testGetTypes_NetworkErrorWithNoCache_ReturnsDefaults() async throws {
        // Given: No cache, API throws error
        mockAPIService.shouldThrowError = true

        // When
        let types = await repository.getTypes()

        // Then: Returns default types
        XCTAssertEqual(types.count, 6)
        XCTAssertTrue(types.contains { $0.name == "Gedanke" })
        XCTAssertTrue(types.contains { $0.name == "Erlebnis" })
    }

    /// Test: RefreshTypes updates cache
    func testRefreshTypes_UpdatesCache() async throws {
        // Given: Existing cache
        let oldCached = MomentTypeCache(id: "Old", name: "Old Type", colorRaw: "gray")
        modelContext.insert(oldCached)
        try modelContext.save()

        // Mock API returns new types
        mockAPIService.mockSelectOptions = [
            NotionSelectOption(name: "New1", color: "blue"),
            NotionSelectOption(name: "New2", color: "green")
        ]

        // When
        let types = try await repository.refreshTypes()

        // Then: Returns fresh types
        XCTAssertEqual(types.count, 2)
        XCTAssertEqual(types[0].name, "New1")
        XCTAssertEqual(types[1].name, "New2")

        // Verify cache was replaced
        let descriptor = FetchDescriptor<MomentTypeCache>()
        let cachedTypes = try modelContext.fetch(descriptor)
        XCTAssertEqual(cachedTypes.count, 2)
        XCTAssertFalse(cachedTypes.contains { $0.name == "Old Type" })
        XCTAssertTrue(cachedTypes.contains { $0.name == "New1" })
    }

    /// Test: ClearCache removes all cached types
    func testClearCache_RemovesAllCachedTypes() async throws {
        // Given: Multiple cached types
        let cachedTypes = [
            MomentTypeCache(id: "Type1", name: "Type 1", colorRaw: "blue"),
            MomentTypeCache(id: "Type2", name: "Type 2", colorRaw: "green"),
            MomentTypeCache(id: "Type3", name: "Type 3", colorRaw: "yellow")
        ]
        for cached in cachedTypes {
            modelContext.insert(cached)
        }
        try modelContext.save()

        // When
        await repository.clearCache()

        // Then: Cache is empty
        let descriptor = FetchDescriptor<MomentTypeCache>()
        let remaining = try modelContext.fetch(descriptor)
        XCTAssertEqual(remaining.count, 0)
    }

    /// Performance test: Cache hit <100ms
    func testPerformance_CacheHit() async throws {
        // Given: Fresh cache
        let cached = MomentTypeCache(id: "Test", name: "Test Type", colorRaw: "blue")
        modelContext.insert(cached)
        try modelContext.save()

        // When/Then: Measure performance
        measure {
            Task {
                _ = await repository.getTypes()
            }
        }
    }

    /// Test: Color mapping preserves Notion colors
    func testGetTypes_PreservesColorMapping() async throws {
        // Given: Cache with various colors
        let cachedTypes = [
            MomentTypeCache(id: "Blue", name: "Blue Type", colorRaw: "blue"),
            MomentTypeCache(id: "Invalid", name: "Invalid Color", colorRaw: "invalid-color")
        ]
        for cached in cachedTypes {
            modelContext.insert(cached)
        }
        try modelContext.save()

        // When
        let types = await repository.getTypes()

        // Then: Colors are correctly mapped
        XCTAssertEqual(types[0].color, .blue)
        XCTAssertEqual(types[1].color, .default) // Invalid color defaults to .default
    }
}

// MARK: - Mock API Service

/// Mock NotionAPIService for testing
final class MockNotionAPIService: NotionAPIServiceProtocol, @unchecked Sendable {
    var getSelectOptionsCallCount = 0
    var mockSelectOptions: [NotionSelectOption] = []
    var shouldThrowError = false

    func validateToken(token: String) async throws -> NotionUser {
        fatalError("Not needed for these tests")
    }

    func searchDatabases(token: String) async throws -> [NotionDatabaseResponse] {
        fatalError("Not needed for these tests")
    }

    func queryDatabase(
        token: String,
        databaseId: String,
        filter: NotionFilter?,
        sorts: [NotionSort]?,
        pageSize: Int
    ) async throws -> [NotionPageResponse] {
        fatalError("Not needed for these tests")
    }

    func createPage(
        token: String,
        databaseId: String,
        properties: [String: NotionPropertyValue]
    ) async throws -> NotionPageResponse {
        fatalError("Not needed for these tests")
    }

    func updatePage(
        token: String,
        pageId: String,
        properties: [String: NotionPropertyValue]
    ) async throws -> NotionPageResponse {
        fatalError("Not needed for these tests")
    }

    func getSelectOptions(
        token: String,
        databaseId: String,
        propertyName: String
    ) async throws -> [NotionSelectOption] {
        getSelectOptionsCallCount += 1

        if shouldThrowError {
            throw NotionAPIError.networkError(message: "Mock network error")
        }

        return mockSelectOptions
    }
}
