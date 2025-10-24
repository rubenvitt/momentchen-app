//
//  MomentType.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation

/// Represents a type of moment with name and color
/// Maps to Notion Select property options
struct MomentType: Identifiable, Sendable, Equatable, Hashable {
    // MARK: - Properties

    /// Unique identifier (same as name for now)
    var id: String { name }

    /// Name of the moment type (e.g., "Gedanke", "Erlebnis")
    let name: String

    /// Associated Notion color for UI display
    let color: NotionColor

    // MARK: - Initialization

    /// Initialize a MomentType
    /// - Parameters:
    ///   - name: The type name
    ///   - color: The Notion color for this type
    init(name: String, color: NotionColor) {
        self.name = name
        self.color = color
    }
}

// MARK: - Common Types

extension MomentType {
    /// Predefined common moment types
    static let gedanke = MomentType(name: "Gedanke", color: .blue)
    static let erlebnis = MomentType(name: "Erlebnis", color: .green)
    static let aktivität = MomentType(name: "Aktivität", color: .orange)
    static let idee = MomentType(name: "Idee", color: .yellow)
    static let emotion = MomentType(name: "Emotion", color: .pink)
    static let lernen = MomentType(name: "Lernen", color: .purple)
}

// MARK: - Test Helpers

#if DEBUG
extension MomentType {
    /// Create a mock MomentType for testing
    static func mock(name: String = "Test Type", color: NotionColor = .gray) -> MomentType {
        MomentType(name: name, color: color)
    }
}
#endif
