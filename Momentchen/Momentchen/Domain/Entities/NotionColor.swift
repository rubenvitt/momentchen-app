//
//  NotionColor.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation
import SwiftUI

/// Enum representing Notion's color palette for Select options
/// Maps to SwiftUI Color for UI rendering
enum NotionColor: String, Sendable, Codable, CaseIterable, Equatable, Hashable {
    // MARK: - Cases (Notion Color Names)

    case blue = "blue"
    case brown = "brown"
    case gray = "gray"
    case green = "green"
    case orange = "orange"
    case pink = "pink"
    case purple = "purple"
    case red = "red"
    case yellow = "yellow"
    case `default` = "default"

    // MARK: - UI Mapping

    /// Convert Notion color to SwiftUI Color
    var color: Color {
        switch self {
        case .blue:
            return .blue
        case .brown:
            return .brown
        case .gray:
            return .gray
        case .green:
            return .green
        case .orange:
            return .orange
        case .pink:
            return .pink
        case .purple:
            return .purple
        case .red:
            return .red
        case .yellow:
            return .yellow
        case .default:
            return .primary
        }
    }

    /// Get a lighter shade for backgrounds
    var backgroundTint: Color {
        color.opacity(0.2)
    }
}

// MARK: - Test Helpers

#if DEBUG
extension NotionColor {
    /// All available colors for testing UI
    static var allUIColors: [NotionColor] {
        NotionColor.allCases
    }
}
#endif
