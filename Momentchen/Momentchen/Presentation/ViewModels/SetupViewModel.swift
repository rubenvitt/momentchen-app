//
//  SetupViewModel.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation
import SwiftData
import Observation

/// ViewModel for the setup flow (token validation and database selection)
/// Manages the onboarding process for connecting to Notion
@Observable
@MainActor
final class SetupViewModel {
    // MARK: - Properties

    /// Notion integration token entered by user
    var notionToken: String = ""

    /// Available databases from Notion workspace
    var availableDatabases: [NotionDatabaseResponse] = []

    /// Selected database for Moments
    var selectedMomentsDB: NotionDatabaseResponse?

    /// Selected database for Projects
    var selectedProjectsDB: NotionDatabaseResponse?

    /// Selected database for Life Areas
    var selectedLifeAreasDB: NotionDatabaseResponse?

    /// Loading state
    var isLoading: Bool = false

    /// Error message to display to user
    var errorMessage: String?

    /// Indicates if token has been validated successfully
    var isTokenValid: Bool = false

    /// Indicates if configuration has been saved
    var isSetupComplete: Bool = false

    // MARK: - Dependencies

    private let apiService: NotionAPIServiceProtocol
    private let modelContext: ModelContext

    // MARK: - Initialization

    /// Initialize SetupViewModel with dependencies
    /// - Parameters:
    ///   - apiService: Notion API service for backend communication
    ///   - modelContext: SwiftData context for saving configuration
    init(
        apiService: NotionAPIServiceProtocol,
        modelContext: ModelContext
    ) {
        self.apiService = apiService
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// Validates the entered Notion token
    /// Calls the Notion API to verify token validity
    func validateToken() async {
        guard !notionToken.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Bitte gib einen Token ein"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await apiService.validateToken(token: notionToken)
            isTokenValid = true

            // Automatically load databases after successful validation
            await loadDatabases()
        } catch {
            handleError(error)
            isTokenValid = false
        }

        isLoading = false
    }

    /// Loads available databases from Notion
    /// Should be called after token validation succeeds
    func loadDatabases() async {
        guard isTokenValid else {
            errorMessage = "Bitte validiere zuerst deinen Token"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let databases = try await apiService.searchDatabases(token: notionToken)

            // Sort databases alphabetically by title
            availableDatabases = databases.sorted { db1, db2 in
                let title1 = (db1.title.first?.plainText).flatMap { $0 } ?? db1.id
                let title2 = (db2.title.first?.plainText).flatMap { $0 } ?? db2.id
                return title1.localizedCaseInsensitiveCompare(title2) == .orderedAscending
            }

        } catch {
            handleError(error)
        }

        isLoading = false
    }

    /// Saves the configuration to SwiftData
    /// Creates or updates AppConfiguration entity
    func saveConfiguration() async throws {
        guard let momentsDB = selectedMomentsDB,
              let projectsDB = selectedProjectsDB,
              let lifeAreasDB = selectedLifeAreasDB else {
            errorMessage = "Bitte wähle alle drei Datenbanken aus"
            throw NotionAPIError.validationError(message: "Alle drei Datenbanken müssen ausgewählt sein")
        }

        isLoading = true
        errorMessage = nil

        do {
            // Delete existing configuration
            let descriptor = FetchDescriptor<AppConfiguration>()
            let existingConfigs = try modelContext.fetch(descriptor)
            for config in existingConfigs {
                modelContext.delete(config)
            }

            // Create new configuration
            let config = AppConfiguration(
                notionToken: notionToken,
                momentsDatabaseId: momentsDB.id,
                projectsDatabaseId: projectsDB.id,
                lifeAreasDatabaseId: lifeAreasDB.id,
                themePreference: .system
            )

            modelContext.insert(config)
            try modelContext.save()

            isSetupComplete = true
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
            throw error
        }

        isLoading = false
    }

    /// Resets the setup flow to initial state
    func reset() {
        notionToken = ""
        availableDatabases = []
        selectedMomentsDB = nil
        selectedProjectsDB = nil
        selectedLifeAreasDB = nil
        isTokenValid = false
        isSetupComplete = false
        errorMessage = nil
        isLoading = false
    }

    // MARK: - Computed Properties

    /// Indicates if all databases have been selected
    var canSaveConfiguration: Bool {
        selectedMomentsDB != nil &&
        selectedProjectsDB != nil &&
        selectedLifeAreasDB != nil
    }

    // MARK: - Private Methods

    /// Handles errors by converting them to user-friendly messages
    private func handleError(_ error: Error) {
        if let apiError = error as? NotionAPIError {
            errorMessage = apiError.userMessage
        } else {
            errorMessage = "Ein unerwarteter Fehler ist aufgetreten"
        }
    }
}

// MARK: - Test Helpers

#if DEBUG
extension SetupViewModel {
    /// Create a mock ViewModel for previews
    static func mock(
        apiService: NotionAPIServiceProtocol? = nil,
        modelContext: ModelContext? = nil
    ) -> SetupViewModel {
        let mockService = apiService ?? NotionAPIService.mock()
        let mockContext = modelContext ?? (try! ModelContext(
            ModelContainer(for: AppConfiguration.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        ))

        return SetupViewModel(apiService: mockService, modelContext: mockContext)
    }
}
#endif
