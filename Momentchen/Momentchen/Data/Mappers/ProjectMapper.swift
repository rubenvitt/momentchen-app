//
//  ProjectMapper.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation

/// Mapper to convert between NotionPageResponse and Project domain model
enum ProjectMapper {
    // MARK: - Errors

    enum MappingError: Error, LocalizedError {
        case missingRequiredProperty(String)
        case invalidPropertyType(String)

        var errorDescription: String? {
            switch self {
            case .missingRequiredProperty(let property):
                return "Pflichtfeld fehlt: \(property)"
            case .invalidPropertyType(let property):
                return "Ungültiger Typ für \(property)"
            }
        }
    }

    // MARK: - DTO to Domain

    /// Map NotionPageResponse to Project domain model
    /// - Parameter response: Notion API page response
    /// - Returns: Mapped Project entity
    /// - Throws: MappingError if required fields are missing or invalid
    static func toDomain(_ response: NotionPageResponse) throws -> Project {
        // Extract title (required)
        // Project database uses "Projekt" as the title property
        guard let titleProperty = response.properties["Projekt"],
              case .title(let richTexts) = titleProperty,
              let title = (richTexts.first?.plainText).flatMap({ $0 }), !title.isEmpty else {
            throw MappingError.missingRequiredProperty("Projekt")
        }

        return Project(id: response.id, title: title)
    }

    /// Map array of NotionPageResponse to array of Projects
    /// - Parameter responses: Array of Notion API page responses
    /// - Returns: Array of mapped Project entities
    /// - Note: Skips invalid entries and logs errors
    static func toDomain(_ responses: [NotionPageResponse]) -> [Project] {
        responses.compactMap { response in
            do {
                return try toDomain(response)
            } catch {
                // Log error but continue mapping other entries
                print("⚠️ Failed to map project \(response.id): \(error.localizedDescription)")
                return nil
            }
        }
    }

    // MARK: - Filtering Helpers

    /// Filter projects by status "In Bearbeitung" (In Progress)
    /// - Parameter responses: Array of Notion API page responses
    /// - Returns: Filtered array of Projects with status "In Bearbeitung"
    static func filterActiveProjects(_ responses: [NotionPageResponse]) -> [Project] {
        let activeResponses = responses.filter { response in
            guard let statusProperty = response.properties["Status"],
                  case .status(let statusValue) = statusProperty,
                  let status = statusValue else {
                return false
            }
            return status.name == "In Bearbeitung"
        }

        return toDomain(activeResponses)
    }
}

// MARK: - Test Helpers

#if DEBUG
extension ProjectMapper {
    /// Create a mock NotionPageResponse with project data for testing
    static func mockNotionPage(
        id: String = "mock-project-id",
        title: String = "Test Project",
        status: String = "In Bearbeitung"
    ) -> NotionPageResponse {
        let properties: [String: NotionProperty] = [
            "Projekt": .title([NotionRichText.mock(content: title)]),
            "Status": .status(NotionStatus(id: "status-id", name: status, color: "blue"))
        ]

        return NotionPageResponse.mock(id: id, properties: properties)
    }
}
#endif
