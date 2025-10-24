//
//  MomentFormViewModel.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation
import SwiftData
import Observation

/// ViewModel for moment creation and editing form
/// Manages form state, validation, and save operations
@Observable
@MainActor
final class MomentFormViewModel {
    // MARK: - Properties

    /// Moment description/title
    var title: String = ""

    /// Selected moment type
    var selectedType: MomentType?

    /// Timestamp when the moment occurred
    var timestamp: Date = Date()

    /// Selected category (project, life area, or none)
    var selectedCategory: MomentCategory = .none

    /// Available moment types from database schema
    var momentTypes: [MomentType] = []

    /// Available projects (filtered by "In Bearbeitung" status)
    var projects: [Project] = []

    /// Available life areas (filtered by "Aktiv" status)
    var lifeAreas: [LifeArea] = []

    /// Loading state
    var isLoading: Bool = false

    /// Error message
    var errorMessage: String?

    /// Success state
    var saveSuccessful: Bool = false

    /// Edit mode (editing existing moment vs. creating new)
    var isEditing: Bool = false

    /// ID of moment being edited (if in edit mode)
    var editingMomentId: String?

    // MARK: - Dependencies

    private let apiService: NotionAPIServiceProtocol
    private let modelContext: ModelContext
    private let typeRepository: MomentTypeRepository
    private let projectRepository: ProjectRepository
    private let lifeAreaRepository: LifeAreaRepository

    // MARK: - Initialization

    /// Initialize MomentFormViewModel with dependencies
    /// - Parameters:
    ///   - apiService: Notion API service
    ///   - modelContext: SwiftData context
    ///   - typeRepository: Repository for cached moment types (optional, will create if not provided)
    ///   - projectRepository: Repository for cached projects (optional, will create if not provided)
    ///   - lifeAreaRepository: Repository for cached life areas (optional, will create if not provided)
    init(
        apiService: NotionAPIServiceProtocol,
        modelContext: ModelContext,
        typeRepository: MomentTypeRepository? = nil,
        projectRepository: ProjectRepository? = nil,
        lifeAreaRepository: LifeAreaRepository? = nil
    ) {
        self.apiService = apiService
        self.modelContext = modelContext
        // Create repositories if not provided (dependency injection for testing)
        self.typeRepository = typeRepository ?? MomentTypeRepository(
            modelContext: modelContext,
            apiService: apiService
        )
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

    /// Loads available options from Notion (types, projects, life areas)
    func loadAvailableOptions() async {
        isLoading = true
        errorMessage = nil

        do {
            let config = try loadConfiguration()

            // Load moment types from database schema
            await loadMomentTypes(config: config)

            // Load projects
            await loadProjects(config: config)

            // Load life areas
            await loadLifeAreas(config: config)

        } catch {
            handleError(error)
        }

        isLoading = false
    }

    /// Sets up form for editing an existing moment
    /// - Parameter moment: Moment to edit
    func setupForEditing(moment: Moment) {
        isEditing = true
        editingMomentId = moment.id
        title = moment.title
        selectedType = moment.type
        timestamp = moment.timestamp
        selectedCategory = moment.category
    }

    /// Saves the moment (create or update based on edit mode)
    func saveMoment() async {
        guard validate() else {
            return
        }

        isLoading = true
        errorMessage = nil
        saveSuccessful = false

        do {
            let config = try loadConfiguration()

            let properties = MomentMapper.toNotionProperties(
                title: title,
                type: selectedType!,
                timestamp: timestamp,
                category: selectedCategory
            )

            if isEditing, let momentId = editingMomentId {
                _ = try await apiService.updatePage(
                    token: config.notionToken,
                    pageId: momentId,
                    properties: properties
                )
            } else {
                _ = try await apiService.createPage(
                    token: config.notionToken,
                    databaseId: config.momentsDatabaseId,
                    properties: properties
                )
            }

            saveSuccessful = true

        } catch {
            handleError(error)
        }

        isLoading = false
    }

    /// Sets timestamp to current time
    func setToNow() {
        timestamp = Date()
    }

    /// Resets form to initial state
    func reset() {
        title = ""
        selectedType = nil
        timestamp = Date()
        selectedCategory = .none
        errorMessage = nil
        saveSuccessful = false
        isEditing = false
        editingMomentId = nil
    }

    // MARK: - Validation

    /// Validates form inputs
    /// - Returns: true if valid, false otherwise
    private func validate() -> Bool {
        // Title is required
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Bitte gib eine Beschreibung ein"
            return false
        }

        // Type is required
        if selectedType == nil {
            errorMessage = "Bitte wähle einen Typ aus"
            return false
        }

        return true
    }

    // MARK: - Private Methods

    /// Loads moment types using cache-first strategy via repository
    /// Cache-first approach: Returns cached types instantly if fresh (<24h)
    /// Falls back to API fetch if cache is stale or missing
    /// - Parameter config: App configuration (not used, kept for API compatibility)
    private func loadMomentTypes(config: AppConfiguration) async {
        // Use repository's cache-first strategy
        // This will return instantly from cache if available and fresh
        // Otherwise fetches from API and updates cache
        momentTypes = await typeRepository.getTypes()
    }

    /// Loads projects using cache-first strategy via repository
    /// Cache-first approach: Returns cached projects instantly if fresh (<24h)
    /// Falls back to API fetch if cache is stale or missing
    /// - Parameter config: App configuration (not used, kept for API compatibility)
    private func loadProjects(config: AppConfiguration) async {
        // Use repository's cache-first strategy with active filter
        projects = await projectRepository.getProjects()
    }

    /// Loads life areas using cache-first strategy via repository
    /// Cache-first approach: Returns cached life areas instantly if fresh (<24h)
    /// Falls back to API fetch if cache is stale or missing
    /// - Parameter config: App configuration (not used, kept for API compatibility)
    private func loadLifeAreas(config: AppConfiguration) async {
        // Use repository's cache-first strategy with active filter
        lifeAreas = await lifeAreaRepository.getLifeAreas()
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

    /// Handles errors
    private func handleError(_ error: Error) {
        if let apiError = error as? NotionAPIError {
            errorMessage = apiError.userMessage
        } else {
            errorMessage = "Fehler beim Speichern"
        }
    }
}

// MARK: - Test Helpers

#if DEBUG
extension MomentFormViewModel {
    /// Create a mock ViewModel for previews
    static func mock(
        apiService: NotionAPIServiceProtocol? = nil,
        modelContext: ModelContext? = nil,
        typeRepository: MomentTypeRepository? = nil,
        projectRepository: ProjectRepository? = nil,
        lifeAreaRepository: LifeAreaRepository? = nil
    ) -> MomentFormViewModel {
        let mockService = apiService ?? NotionAPIService.mock()
        let mockContext = modelContext ?? (try! ModelContext(
            ModelContainer(
                for: AppConfiguration.self, MomentTypeCache.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        ))

        let vm = MomentFormViewModel(
            apiService: mockService,
            modelContext: mockContext,
            typeRepository: typeRepository,
            projectRepository: projectRepository,
            lifeAreaRepository: lifeAreaRepository
        )
        vm.momentTypes = [.gedanke, .erlebnis, .aktivität, .idee]
        return vm
    }
}
#endif
