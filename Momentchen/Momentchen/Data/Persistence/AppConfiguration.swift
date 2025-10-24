//
//  AppConfiguration.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation
import SwiftData

/// SwiftData model for storing app configuration
/// This is the ONLY SwiftData model - all other data lives in Notion
@Model
final class AppConfiguration {
    // MARK: - Properties

    /// Unique identifier
    @Attribute(.unique) var id: UUID

    /// Notion Integration Token (should be stored in Keychain for security)
    var notionToken: String

    /// Database ID for Moments
    var momentsDatabaseId: String

    /// Database ID for Projects
    var projectsDatabaseId: String

    /// Database ID for Life Areas
    var lifeAreasDatabaseId: String

    /// Theme preference (stored as raw string value)
    var themePreference: String

    /// Creation timestamp
    var createdAt: Date

    /// Last update timestamp
    var updatedAt: Date

    // MARK: - Initialization

    /// Initialize AppConfiguration with all required properties
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated)
    ///   - notionToken: Notion API integration token
    ///   - momentsDatabaseId: Database ID for moments
    ///   - projectsDatabaseId: Database ID for projects
    ///   - lifeAreasDatabaseId: Database ID for life areas
    ///   - themePreference: Theme preference (light/dark/system)
    ///   - createdAt: Creation timestamp
    ///   - updatedAt: Last update timestamp
    init(
        id: UUID = UUID(),
        notionToken: String,
        momentsDatabaseId: String,
        projectsDatabaseId: String,
        lifeAreasDatabaseId: String,
        themePreference: ThemePreference = .system,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.notionToken = notionToken
        self.momentsDatabaseId = momentsDatabaseId
        self.projectsDatabaseId = projectsDatabaseId
        self.lifeAreasDatabaseId = lifeAreasDatabaseId
        self.themePreference = themePreference.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Get theme preference as enum
    var theme: ThemePreference {
        get {
            ThemePreference(rawValue: themePreference) ?? .system
        }
        set {
            themePreference = newValue.rawValue
        }
    }
}

// MARK: - Theme Preference Enum

/// Theme preference options
enum ThemePreference: String, Codable, CaseIterable, Sendable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    /// Get SwiftUI ColorScheme (nil for system)
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }

    /// Human-readable name
    var displayName: String {
        switch self {
        case .light:
            return "Hell"
        case .dark:
            return "Dunkel"
        case .system:
            return "System"
        }
    }
}

// MARK: - SwiftUI Import (only for ColorScheme)

import SwiftUI

// MARK: - ModelContainer Setup

extension AppConfiguration {
    /// Shared ModelContainer for the app
    /// This is used in the App entry point
    static var modelContainer: ModelContainer = {
        let schema = Schema([AppConfiguration.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer for AppConfiguration: \(error)")
        }
    }()
}

// MARK: - Test Helpers

#if DEBUG
extension AppConfiguration {
    /// Create a mock configuration for testing
    static func mock(
        id: UUID = UUID(),
        notionToken: String = "secret_test_token",
        momentsDatabaseId: String = "moments-db-id",
        projectsDatabaseId: String = "projects-db-id",
        lifeAreasDatabaseId: String = "lifeareas-db-id",
        theme: ThemePreference = .system
    ) -> AppConfiguration {
        AppConfiguration(
            id: id,
            notionToken: notionToken,
            momentsDatabaseId: momentsDatabaseId,
            projectsDatabaseId: projectsDatabaseId,
            lifeAreasDatabaseId: lifeAreasDatabaseId,
            themePreference: theme
        )
    }
}
#endif
