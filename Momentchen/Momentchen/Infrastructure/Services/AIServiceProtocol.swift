//
//  AIServiceProtocol.swift
//  Momentchen
//
//  Protocol for AI-powered moment property inference
//

import Foundation

/// Protocol for AI-powered moment property inference
protocol AIServiceProtocol: Sendable {
    /// Infers the most appropriate MomentType based on the title
    /// - Parameters:
    ///   - title: The moment description
    ///   - availableTypes: Available moment types to choose from
    /// - Returns: The inferred MomentType or nil if inference fails
    func inferMomentType(from title: String, availableTypes: [MomentType]) async throws -> MomentType?

    /// Infers the most appropriate category (project or life area) based on title and type
    /// - Parameters:
    ///   - title: The moment description
    ///   - type: The moment type
    ///   - projects: Available projects
    ///   - lifeAreas: Available life areas
    /// - Returns: The inferred MomentCategory or nil if inference fails
    func inferCategory(from title: String, type: MomentType?, projects: [Project], lifeAreas: [LifeArea]) async throws -> MomentCategory?
}

// Type alias for backward compatibility
typealias GeminiServiceProtocol = AIServiceProtocol
