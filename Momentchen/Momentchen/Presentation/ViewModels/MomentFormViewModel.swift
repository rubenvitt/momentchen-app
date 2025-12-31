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

    /// Indicates if AI is inferring the type
    var isInferringType: Bool = false

    /// Indicates if the current type was suggested by AI
    var isAiSuggested: Bool = false

    /// Indicates if AI is inferring the category
    var isInferringCategory: Bool = false

    /// Indicates if the current category was suggested by AI
    var isCategoryAiSuggested: Bool = false

    // MARK: - Dependencies

    private let apiService: NotionAPIServiceProtocol
    private let modelContext: ModelContext
    private let typeRepository: MomentTypeRepository
    private let projectRepository: ProjectRepository
    private let lifeAreaRepository: LifeAreaRepository
    private let geminiService: GeminiServiceProtocol?

    // Debouncing
    private var inferenceTask: Task<Void, Never>?
    private var categoryInferenceTask: Task<Void, Never>?

    // MARK: - Initialization

    /// Initialize MomentFormViewModel with dependencies
    /// - Parameters:
    ///   - apiService: Notion API service
    ///   - modelContext: SwiftData context
    ///   - typeRepository: Repository for cached moment types (optional, will create if not provided)
    ///   - projectRepository: Repository for cached projects (optional, will create if not provided)
    ///   - lifeAreaRepository: Repository for cached life areas (optional, will create if not provided)
    ///   - geminiService: Gemini service for AI inference (optional)
    init(
        apiService: NotionAPIServiceProtocol,
        modelContext: ModelContext,
        typeRepository: MomentTypeRepository? = nil,
        projectRepository: ProjectRepository? = nil,
        lifeAreaRepository: LifeAreaRepository? = nil,
        geminiService: GeminiServiceProtocol? = nil
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
        self.geminiService = geminiService
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
        // When editing, the type and category are user-selected, not AI-suggested
        isAiSuggested = false
        isCategoryAiSuggested = false
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
        isInferringType = false
        isAiSuggested = false
        isInferringCategory = false
        isCategoryAiSuggested = false
    }

    /// Infers moment type using AI based on the title
    /// Runs if:
    /// - Title is not empty
    /// - No type is selected OR current type is an AI suggestion (allows re-inference)
    /// - Gemini service is available
    /// - Types are loaded
    func inferTypeFromTitle() {
        // Cancel any existing inference task
        inferenceTask?.cancel()

        // Debug: Check preconditions
        print("🔍 AI Inference Check:")
        print("  - Has Gemini Service: \(geminiService != nil)")
        print("  - Selected Type: \(selectedType?.name ?? "none")")
        print("  - Is AI Suggested: \(isAiSuggested)")
        print("  - Title: \"\(title)\"")
        print("  - Available Types: \(momentTypes.count)")

        // Only infer if:
        // - Title is not empty AND
        // - (No type selected OR current type is AI-suggested) AND
        // - Gemini service available AND
        // - Types are loaded
        let canInfer = (selectedType == nil || isAiSuggested) &&
                       !title.trimmingCharacters(in: .whitespaces).isEmpty &&
                       geminiService != nil &&
                       !momentTypes.isEmpty

        guard canInfer, let geminiService = geminiService else {
            print("  ❌ Preconditions not met")
            if selectedType != nil && !isAiSuggested {
                print("  ℹ️ User manually selected type - AI inference disabled")
            }
            return
        }

        print("  ✅ Starting inference task...")

        // Create new inference task with debouncing
        inferenceTask = Task { @MainActor in
            // Debounce: Wait before making API call
            try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds

            // Check if task was cancelled during sleep
            guard !Task.isCancelled else {
                print("  ⏭️ Inference cancelled (user still typing)")
                return
            }

            // Check again if conditions are still met after debounce
            // Allow inference if no type selected OR current type is AI-suggested
            let canStillInfer = (selectedType == nil || isAiSuggested) &&
                               !title.trimmingCharacters(in: .whitespaces).isEmpty

            guard canStillInfer else {
                print("  ❌ Conditions changed during debounce")
                if selectedType != nil && !isAiSuggested {
                    print("  ℹ️ User manually selected type during wait")
                }
                return
            }

            print("  🤖 Calling Gemini API...")
            isInferringType = true

            do {
                if let inferredType = try await geminiService.inferMomentType(
                    from: title,
                    availableTypes: momentTypes
                ) {
                    print("  ✨ AI suggested: \(inferredType.name)")
                    selectedType = inferredType
                    isAiSuggested = true

                    // Trigger category inference after type is inferred
                    inferCategoryFromTitleAndType()
                } else {
                    print("  ⚠️ AI returned no suggestion")
                }
            } catch {
                // Silently fail - AI inference is optional
                print("  ❌ AI inference failed: \(error.localizedDescription)")
            }

            isInferringType = false
        }
    }

    /// Called when user manually selects a type
    /// Clears the AI suggestion flag
    func selectType(_ type: MomentType) {
        selectedType = type
        isAiSuggested = false

        // Trigger category inference after type selection if enabled
        inferCategoryFromTitleAndType()
    }

    /// Infers category (project/life area) using AI based on title and type
    /// Only runs if:
    /// - Title and type are set
    /// - No category selected OR current category is AI-suggested
    /// - Gemini service is available
    /// - AI category suggestions are enabled in settings
    /// - Projects/life areas are loaded
    func inferCategoryFromTitleAndType() {
        // Cancel any existing category inference task
        categoryInferenceTask?.cancel()

        // Check if category suggestions are enabled
        guard let config = try? loadConfiguration(),
              config.aiCategorySuggestionsEnabled else {
            return
        }

        // Debug logging
        print("🔍 AI Category Inference Check:")
        print("  - Has Gemini Service: \(geminiService != nil)")
        print("  - Selected Category: \(selectedCategory)")
        print("  - Is Category AI Suggested: \(isCategoryAiSuggested)")
        print("  - Title: \"\(title)\"")
        print("  - Type: \(selectedType?.name ?? "none")")
        print("  - Projects: \(projects.count), Life Areas: \(lifeAreas.count)")

        // Only infer if:
        // - Title and type are set AND
        // - (No category selected OR current category is AI-suggested) AND
        // - Gemini service available AND
        // - Projects or life areas available
        let canInfer = !title.trimmingCharacters(in: .whitespaces).isEmpty &&
                       selectedType != nil &&
                       (selectedCategory == .none || isCategoryAiSuggested) &&
                       geminiService != nil &&
                       (!projects.isEmpty || !lifeAreas.isEmpty)

        guard canInfer, let geminiService = geminiService else {
            print("  ❌ Category inference preconditions not met")
            if selectedCategory != .none && !isCategoryAiSuggested {
                print("  ℹ️ User manually selected category - AI inference disabled")
            }
            return
        }

        print("  ✅ Starting category inference task...")

        // Create new inference task with debouncing
        categoryInferenceTask = Task { @MainActor in
            // Debounce: Wait before making API call
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

            // Check if task was cancelled during sleep
            guard !Task.isCancelled else {
                print("  ⏭️ Category inference cancelled")
                return
            }

            // Check again if conditions are still met
            let canStillInfer = !title.trimmingCharacters(in: .whitespaces).isEmpty &&
                               selectedType != nil &&
                               (selectedCategory == .none || isCategoryAiSuggested)

            guard canStillInfer else {
                print("  ❌ Category conditions changed during debounce")
                return
            }

            print("  🤖 Calling Gemini API for category...")
            isInferringCategory = true

            do {
                if let inferredCategory = try await geminiService.inferCategory(
                    from: title,
                    type: selectedType,
                    projects: projects,
                    lifeAreas: lifeAreas
                ) {
                    print("  ✨ AI suggested category: \(inferredCategory)")
                    selectedCategory = inferredCategory
                    isCategoryAiSuggested = true
                } else {
                    print("  ⚠️ AI returned no category suggestion")
                }
            } catch {
                print("  ❌ AI category inference failed: \(error.localizedDescription)")
            }

            isInferringCategory = false
        }
    }

    /// Called when user manually selects a category
    /// Clears the AI suggestion flag
    func selectCategory(_ category: MomentCategory) {
        selectedCategory = category
        isCategoryAiSuggested = false
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
        lifeAreaRepository: LifeAreaRepository? = nil,
        geminiService: GeminiServiceProtocol? = nil
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
            lifeAreaRepository: lifeAreaRepository,
            geminiService: geminiService
        )
        vm.momentTypes = [.gedanke, .erlebnis, .aktivität, .idee]
        return vm
    }
}
#endif
