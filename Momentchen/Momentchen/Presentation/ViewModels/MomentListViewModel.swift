//
//  MomentListViewModel.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation
import SwiftData
import Observation
import OSLog

/// ViewModel for the moment list view (today's moments)
/// Manages fetching, refreshing, and displaying moments
@Observable
@MainActor
final class MomentListViewModel {
    // MARK: - Properties

    /// List of moments for today
    var moments: [Moment] = []

    /// Loading state
    var isLoading: Bool = false

    /// Refresh state (for pull-to-refresh without full loading indicator)
    var isRefreshing: Bool = false

    /// Error message to display
    var errorMessage: String?

    /// Last successful refresh timestamp
    var lastRefreshDate: Date?

    /// Recently deleted moment (for undo)
    var deletedMoment: Moment?

    /// Task handling delayed delete
    private var deleteTask: Task<Void, Never>?

    // MARK: - Dependencies

    private let apiService: NotionAPIServiceProtocol
    private let modelContext: ModelContext
    private var refreshTimer: Timer?
    private let logger = Logger(subsystem: "com.momentchen.app", category: "MomentListViewModel")
    private let projectRepository: ProjectRepository
    private let lifeAreaRepository: LifeAreaRepository

    // MARK: - Initialization

    /// Initialize MomentListViewModel with dependencies
    /// - Parameters:
    ///   - apiService: Notion API service
    ///   - modelContext: SwiftData context for configuration
    ///   - projectRepository: Repository for projects (defaults to new instance)
    ///   - lifeAreaRepository: Repository for life areas (defaults to new instance)
    init(
        apiService: NotionAPIServiceProtocol,
        modelContext: ModelContext,
        projectRepository: ProjectRepository? = nil,
        lifeAreaRepository: LifeAreaRepository? = nil
    ) {
        self.apiService = apiService
        self.modelContext = modelContext

        // Use provided repositories or create new ones
        self.projectRepository = projectRepository ?? ProjectRepository(
            modelContext: modelContext,
            apiService: apiService
        )
        self.lifeAreaRepository = lifeAreaRepository ?? LifeAreaRepository(
            modelContext: modelContext,
            apiService: apiService
        )
    }

    // MARK: - Public Methods

    /// Loads today's moments from Notion
    /// Uses full loading indicator
    func loadTodaysMoments() async {
        isLoading = true
        errorMessage = nil

        await fetchMoments()

        isLoading = false
    }

    /// Refreshes moments without loading indicator (for auto-refresh)
    /// Silent failure to avoid disrupting user
    func refreshMoments() async {
        isRefreshing = true

        await fetchMoments(silent: true)

        isRefreshing = false
    }

    /// Starts auto-refresh timer (15 seconds interval)
    func startAutoRefresh() {
        stopAutoRefresh() // Ensure no duplicate timers

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshMoments()
            }
        }
    }

    /// Stops auto-refresh timer
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    /// Deletes a moment with undo support
    /// The moment is removed from the list immediately, but the API call is delayed by 5 seconds
    /// Call cancelDelete() within 5 seconds to undo the deletion
    /// - Parameter moment: Moment to delete
    func deleteMoment(_ moment: Moment) {
        // Cancel any pending delete
        deleteTask?.cancel()

        // Store for undo
        deletedMoment = moment

        // Remove from list immediately (optimistic UI)
        moments.removeAll { $0.id == moment.id }

        // Trigger haptic warning (use warning convenience method)
        HapticManager.warning()

        // Schedule actual deletion after 5 seconds
        deleteTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(5))

                guard !Task.isCancelled else {
                    return
                }

                // Perform actual deletion
                await self?.performDelete(moment)

            } catch {
                // Task was cancelled (undo) or sleep was interrupted
            }
        }
    }

    /// Cancels a pending delete and restores the moment
    func cancelDelete() {
        guard let moment = deletedMoment else { return }

        // Cancel the API call
        deleteTask?.cancel()
        deleteTask = nil

        // Restore moment to list
        moments.append(moment)
        moments.sort { $0.timestamp > $1.timestamp } // Re-sort by timestamp

        // Clear deleted state
        deletedMoment = nil

        // Haptic feedback (use buttonTap convenience method to avoid UIKit import)
        HapticManager.buttonTap()
    }

    /// Performs the actual delete API call
    private func performDelete(_ moment: Moment) async {
        do {
            let config = try loadConfiguration()

            // Archive the page in Notion
            try await apiService.archivePage(
                token: config.notionToken,
                pageId: moment.id
            )

            // Clear deleted state
            await MainActor.run {
                deletedMoment = nil
                deleteTask = nil
            }

            logger.info("Moment deleted successfully: \(moment.id)")

        } catch {
            // Deletion failed - restore the moment
            await MainActor.run {
                handleDeleteError(moment, error: error)
            }
        }
    }

    /// Handles delete errors by restoring the moment and showing error
    private func handleDeleteError(_ moment: Moment, error: Error) {
        // Restore moment to list
        moments.append(moment)
        moments.sort { $0.timestamp > $1.timestamp }

        // Set error message
        if let apiError = error as? NotionAPIError {
            errorMessage = "Löschen fehlgeschlagen: \(apiError.userMessage)"
        } else {
            errorMessage = "Moment konnte nicht gelöscht werden"
        }

        // Clear deleted state
        deletedMoment = nil
        deleteTask = nil
    }

    // MARK: - Private Methods

    /// Fetches moments from Notion API
    /// - Parameter silent: If true, errors won't update errorMessage
    private func fetchMoments(silent: Bool = false) async {
        do {
            let config = try loadConfiguration()

            // Load projects and life areas for category resolution
            let projects = await loadProjects(config: config)
            let lifeAreas = await loadLifeAreas(config: config)

            // Create filter for today's date (UTC)
            let dateFilter = NotionFilter.todayMoments()

            // Sort by timestamp descending (newest first)
            let sorts = [NotionSort(property: "Zeitpunkt", timestamp: nil, direction: .descending)]

            // Query database
            let pages = try await apiService.queryDatabase(
                token: config.notionToken,
                databaseId: config.momentsDatabaseId,
                filter: dateFilter,
                sorts: sorts,
                pageSize: 100
            )

            // Map to domain models with category resolution
            let fetchedMoments = MomentMapper.toDomain(pages, projects: projects, lifeAreas: lifeAreas)

            moments = fetchedMoments
            lastRefreshDate = Date()

        } catch {
            if !silent {
                handleError(error)
            }
        }
    }

    /// Loads all projects from Notion (for category resolution)
    /// Uses cache-first pattern via repository
    /// - Parameter config: App configuration (kept for signature compatibility)
    /// - Returns: Array of projects (empty on error)
    private func loadProjects(config: AppConfiguration) async -> [Project] {
        // Use cache-first pattern via repository
        // Will return instantly from cache if available and fresh (< 24h)
        return await projectRepository.getProjects(filterActive: true)
    }

    /// Loads all life areas from Notion (for category resolution)
    /// Uses cache-first pattern via repository
    /// - Parameter config: App configuration (kept for signature compatibility)
    /// - Returns: Array of life areas (empty on error)
    private func loadLifeAreas(config: AppConfiguration) async -> [LifeArea] {
        // Use cache-first pattern via repository
        // Will return instantly from cache if available and fresh (< 24h)
        return await lifeAreaRepository.getLifeAreas(filterActive: true)
    }

    /// Loads configuration from SwiftData
    private func loadConfiguration() throws -> AppConfiguration {
        let descriptor = FetchDescriptor<AppConfiguration>()
        let configs = try modelContext.fetch(descriptor)

        guard let config = configs.first else {
            throw NotionAPIError.validationError(message: "Keine Konfiguration gefunden")
        }

        return config
    }

    /// Handles errors by converting to user-friendly messages
    private func handleError(_ error: Error) {
        if let apiError = error as? NotionAPIError {
            errorMessage = apiError.userMessage
        } else {
            errorMessage = "Fehler beim Laden der Momente"
        }
    }

    // MARK: - Cleanup

    deinit {
        MainActor.assumeIsolated {
            stopAutoRefresh()
        }
    }
}

// MARK: - Test Helpers

#if DEBUG
extension MomentListViewModel {
    /// Create a mock ViewModel for previews
    static func mock(
        apiService: NotionAPIServiceProtocol? = nil,
        modelContext: ModelContext? = nil
    ) -> MomentListViewModel {
        let mockService = apiService ?? NotionAPIService.mock()
        let mockContext = modelContext ?? (try! ModelContext(
            ModelContainer(for: AppConfiguration.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        ))

        return MomentListViewModel(apiService: mockService, modelContext: mockContext)
    }
}
#endif
