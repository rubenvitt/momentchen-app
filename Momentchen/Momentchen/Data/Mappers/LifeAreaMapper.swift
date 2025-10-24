//
//  LifeAreaMapper.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation

/// Mapper to convert between NotionPageResponse and LifeArea domain model
enum LifeAreaMapper {
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

    /// Map NotionPageResponse to LifeArea domain model
    /// - Parameter response: Notion API page response
    /// - Returns: Mapped LifeArea entity
    /// - Throws: MappingError if required fields are missing or invalid
    static func toDomain(_ response: NotionPageResponse) throws -> LifeArea {
        // Extract title (required)
        // Life area database uses "Thema" as the title property
        guard let titleProperty = response.properties["Thema"],
              case .title(let richTexts) = titleProperty,
              let title = (richTexts.first?.plainText).flatMap({ $0 }), !title.isEmpty else {
            throw MappingError.missingRequiredProperty("Thema")
        }

        return LifeArea(id: response.id, title: title)
    }

    /// Map array of NotionPageResponse to array of LifeAreas
    /// - Parameter responses: Array of Notion API page responses
    /// - Returns: Array of mapped LifeArea entities
    /// - Note: Skips invalid entries and logs errors
    static func toDomain(_ responses: [NotionPageResponse]) -> [LifeArea] {
        responses.compactMap { response in
            do {
                return try toDomain(response)
            } catch {
                // Log error but continue mapping other entries
                print("⚠️ Failed to map life area \(response.id): \(error.localizedDescription)")
                return nil
            }
        }
    }

    // MARK: - Filtering Helpers

    /// Filter life areas by status "Aktiv" (Active)
    /// - Parameter responses: Array of Notion API page responses
    /// - Returns: Filtered array of LifeAreas with status "Aktiv"
    static func filterActiveLifeAreas(_ responses: [NotionPageResponse]) -> [LifeArea] {
        let activeResponses = responses.filter { response in
            guard let statusProperty = response.properties["Status"],
                  case .status(let statusValue) = statusProperty,
                  let status = statusValue else {
                return false
            }
            return status.name == "Aktiv"
        }

        return toDomain(activeResponses)
    }
}

// MARK: - Test Helpers

#if DEBUG
extension LifeAreaMapper {
    /// Create a mock NotionPageResponse with life area data for testing
    static func mockNotionPage(
        id: String = "mock-lifearea-id",
        title: String = "Test Life Area",
        status: String = "Aktiv"
    ) -> NotionPageResponse {
        let properties: [String: NotionProperty] = [
            "Thema": .title([NotionRichText.mock(content: title)]),
            "Status": .status(NotionStatus(id: "status-id", name: status, color: "green"))
        ]

        return NotionPageResponse.mock(id: id, properties: properties)
    }
}
#endif
