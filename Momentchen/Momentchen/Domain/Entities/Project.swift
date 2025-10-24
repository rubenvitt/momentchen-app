//
//  Project.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation

/// Domain model representing a Project from Notion
/// Projects are used to categorize moments by active projects
struct Project: Identifiable, Sendable, Equatable, Hashable {
    // MARK: - Properties

    /// Unique identifier (Notion Page ID)
    let id: String

    /// Project name/title
    let title: String

    // MARK: - Initialization

    /// Initialize a Project
    /// - Parameters:
    ///   - id: Unique identifier from Notion
    ///   - title: Project name
    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

// MARK: - Test Helpers

#if DEBUG
extension Project {
    /// Create a mock Project for testing
    static func mock(
        id: String = "mock-project-id",
        title: String = "Test Project"
    ) -> Project {
        Project(id: id, title: title)
    }
}
#endif
