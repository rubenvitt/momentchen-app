//
//  MomentCategory.swift
//  Momentchen
//
//  Created by Developer Agent on 23.10.2025.
//

import Foundation

/// Represents the category a moment belongs to
/// A moment can belong to either a project, a life area, or no category
enum MomentCategory: Equatable, Sendable, Hashable {
    case project(Project)
    case lifeArea(LifeArea)
    case none

    // MARK: - Computed Properties

    /// Display name for the category
    var displayName: String {
        switch self {
        case .project(let project):
            return project.title
        case .lifeArea(let lifeArea):
            return lifeArea.title
        case .none:
            return "Keine Zuordnung"
        }
    }

    /// Returns the project ID if this is a project category
    var projectId: String? {
        if case .project(let project) = self {
            return project.id
        }
        return nil
    }

    /// Returns the life area ID if this is a life area category
    var lifeAreaId: String? {
        if case .lifeArea(let lifeArea) = self {
            return lifeArea.id
        }
        return nil
    }

    /// Whether this represents "no category"
    var isNone: Bool {
        if case .none = self { return true }
        return false
    }
}

// MARK: - Identifiable for Picker

extension MomentCategory: Identifiable {
    var id: String {
        switch self {
        case .project(let project):
            return "project-\(project.id)"
        case .lifeArea(let lifeArea):
            return "lifearea-\(lifeArea.id)"
        case .none:
            return "none"
        }
    }
}

#if DEBUG
extension MomentCategory {
    static func mockProject() -> MomentCategory {
        .project(Project.mock())
    }

    static func mockLifeArea() -> MomentCategory {
        .lifeArea(LifeArea.mock())
    }
}
#endif
