//
//  MomentMapper.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation

/// Mapper to convert between NotionPageResponse and Moment domain model
enum MomentMapper {
    // MARK: - Errors

    enum MappingError: Error, LocalizedError {
        case missingRequiredProperty(String)
        case invalidPropertyType(String, expected: String)
        case invalidDateFormat(String)

        var errorDescription: String? {
            switch self {
            case .missingRequiredProperty(let property):
                return "Pflichtfeld fehlt: \(property)"
            case .invalidPropertyType(let property, let expected):
                return "Ungültiger Typ für \(property), erwartet: \(expected)"
            case .invalidDateFormat(let value):
                return "Ungültiges Datumsformat: \(value)"
            }
        }
    }

    // MARK: - DTO to Domain

    /// Map NotionPageResponse to Moment domain model
    /// - Parameters:
    ///   - response: Notion API page response
    ///   - projects: Available projects to resolve relations
    ///   - lifeAreas: Available life areas to resolve relations
    /// - Returns: Mapped Moment entity
    /// - Throws: MappingError if required fields are missing or invalid
    static func toDomain(
        _ response: NotionPageResponse,
        projects: [Project] = [],
        lifeAreas: [LifeArea] = []
    ) throws -> Moment {
        // Extract title (required)
        guard let titleProperty = response.properties["Name"],
              case .title(let richTexts) = titleProperty,
              let title = (richTexts.first?.plainText).flatMap({ $0 }), !title.isEmpty else {
            throw MappingError.missingRequiredProperty("Name")
        }

        // Extract type (required)
        guard let typeProperty = response.properties["Typ"],
              case .select(let selectOption) = typeProperty,
              let selectValue = selectOption else {
            throw MappingError.missingRequiredProperty("Typ")
        }

        let momentType = MomentType(
            name: selectValue.name,
            color: NotionColor(rawValue: selectValue.color ?? "default") ?? .default
        )

        // Extract timestamp (required)
        guard let dateProperty = response.properties["Zeitpunkt"],
              case .date(let notionDate) = dateProperty,
              let dateValue = notionDate else {
            throw MappingError.missingRequiredProperty("Zeitpunkt")
        }

        guard let timestamp = DateConverter.parseFromAPI(dateValue.start) else {
            throw MappingError.invalidDateFormat(dateValue.start)
        }

        // Extract optional project relation
        var projectId: String?
        if let projectProperty = response.properties["Projekt"],
           case .relation(let relations) = projectProperty,
           let firstRelation = relations.first {
            projectId = firstRelation.id
        }

        // Extract optional life area relation
        var lifeAreaId: String?
        if let lifeAreaProperty = response.properties["Lebensbereich"],
           case .relation(let relations) = lifeAreaProperty,
           let firstRelation = relations.first {
            lifeAreaId = firstRelation.id
        }

        // Build category from relation IDs
        // Priority: Project > Life Area > None
        let category: MomentCategory
        if let projectId = projectId,
           let project = projects.first(where: { $0.id == projectId }) {
            category = .project(project)
        } else if let lifeAreaId = lifeAreaId,
                  let lifeArea = lifeAreas.first(where: { $0.id == lifeAreaId }) {
            category = .lifeArea(lifeArea)
        } else {
            category = .none
        }

        // Extract review checkboxes (optional, default to false)
        let isDailyFavorite = extractCheckbox(from: response.properties["⭐ Tagesfavorit"])
        let isWeeklyFavorite = extractCheckbox(from: response.properties["⭐ Wochenfavorit"])
        let isMonthlyFavorite = extractCheckbox(from: response.properties["⭐ Monatsfavorit"])
        let isYearlyFavorite = extractCheckbox(from: response.properties["⭐ Jahresfavorit"])
        let isLifetimeMoment = extractCheckbox(from: response.properties["Moment meines Lebens"])

        // Extract highest review level (computed formula)
        var highestReviewLevel = ""
        if let formulaProperty = response.properties["Relevantester Favorit"],
           case .formula(let formulaResult) = formulaProperty,
           let value = formulaResult?.string {
            highestReviewLevel = value
        }

        return Moment(
            id: response.id,
            title: title,
            type: momentType,
            timestamp: timestamp,
            category: category,
            isDailyFavorite: isDailyFavorite,
            isWeeklyFavorite: isWeeklyFavorite,
            isMonthlyFavorite: isMonthlyFavorite,
            isYearlyFavorite: isYearlyFavorite,
            isLifetimeMoment: isLifetimeMoment,
            highestReviewLevel: highestReviewLevel
        )
    }

    // MARK: - Helper Methods

    /// Extract boolean value from checkbox property
    /// - Parameter property: Notion property (expected to be checkbox)
    /// - Returns: Boolean value (default false if property missing or wrong type)
    private static func extractCheckbox(from property: NotionProperty?) -> Bool {
        guard let property = property,
              case .checkbox(let value) = property else {
            return false
        }
        return value
    }

    /// Map array of NotionPageResponse to array of Moments
    /// - Parameters:
    ///   - responses: Array of Notion API page responses
    ///   - projects: Available projects to resolve relations
    ///   - lifeAreas: Available life areas to resolve relations
    /// - Returns: Array of mapped Moment entities
    /// - Note: Skips invalid entries and logs errors
    static func toDomain(
        _ responses: [NotionPageResponse],
        projects: [Project] = [],
        lifeAreas: [LifeArea] = []
    ) -> [Moment] {
        responses.compactMap { response in
            do {
                return try toDomain(response, projects: projects, lifeAreas: lifeAreas)
            } catch {
                // Log error but continue mapping other entries
                print("⚠️ Failed to map moment \(response.id): \(error.localizedDescription)")
                return nil
            }
        }
    }

    // MARK: - Domain to DTO Properties

    /// Create Notion properties dictionary from Moment data
    /// Used for creating and updating Notion pages
    /// - Parameters:
    ///   - title: Moment description
    ///   - type: Moment type
    ///   - timestamp: When the moment occurred (UTC)
    ///   - category: Category assignment (project, life area, or none)
    /// - Returns: Dictionary of Notion properties ready for API calls
    static func toNotionProperties(
        title: String,
        type: MomentType,
        timestamp: Date,
        category: MomentCategory
    ) -> [String: NotionProperty] {
        var properties: [String: NotionProperty] = [:]

        // Title (required)
        properties["Name"] = .title([
            NotionRichText(
                type: "text",
                text: NotionRichText.TextContent(content: title, link: nil),
                annotations: nil,
                plainText: title,
                href: nil
            )
        ])

        // Type select (required)
        properties["Typ"] = .select(NotionSelectOption(
            id: nil,
            name: type.name,
            color: type.color.rawValue,
            description: nil
        ))

        // Timestamp date (required)
        let formatter = ISO8601DateFormatter()
        properties["Zeitpunkt"] = .date(NotionDate(
            start: formatter.string(from: timestamp),
            end: nil,
            timeZone: nil
        ))

        // Extract projectId and lifeAreaId from category
        let projectId = category.projectId
        let lifeAreaId = category.lifeAreaId

        // Optional project relation
        if let projectId = projectId {
            properties["Projekt"] = .relation([NotionRelation(id: projectId)])
        }

        // Optional life area relation
        if let lifeAreaId = lifeAreaId {
            properties["Lebensbereich"] = .relation([NotionRelation(id: lifeAreaId)])
        }

        return properties
    }

    /// Create Notion properties dictionary for updating review checkboxes
    /// Used for setting moment review markers (daily, weekly, monthly, yearly, lifetime)
    /// - Parameters:
    ///   - isDailyFavorite: Mark as daily favorite
    ///   - isWeeklyFavorite: Mark as weekly favorite
    ///   - isMonthlyFavorite: Mark as monthly favorite
    ///   - isYearlyFavorite: Mark as yearly favorite
    ///   - isLifetimeMoment: Mark as lifetime moment
    /// - Returns: Dictionary of Notion checkbox properties ready for API update calls
    static func toReviewCheckboxProperties(
        isDailyFavorite: Bool? = nil,
        isWeeklyFavorite: Bool? = nil,
        isMonthlyFavorite: Bool? = nil,
        isYearlyFavorite: Bool? = nil,
        isLifetimeMoment: Bool? = nil
    ) -> [String: NotionProperty] {
        var properties: [String: NotionProperty] = [:]

        // Only include non-nil values (allows partial updates)
        if let isDailyFavorite = isDailyFavorite {
            properties["⭐ Tagesfavorit"] = .checkbox(isDailyFavorite)
        }

        if let isWeeklyFavorite = isWeeklyFavorite {
            properties["⭐ Wochenfavorit"] = .checkbox(isWeeklyFavorite)
        }

        if let isMonthlyFavorite = isMonthlyFavorite {
            properties["⭐ Monatsfavorit"] = .checkbox(isMonthlyFavorite)
        }

        if let isYearlyFavorite = isYearlyFavorite {
            properties["⭐ Jahresfavorit"] = .checkbox(isYearlyFavorite)
        }

        if let isLifetimeMoment = isLifetimeMoment {
            properties["Moment meines Lebens"] = .checkbox(isLifetimeMoment)
        }

        return properties
    }
}

// MARK: - Test Helpers

#if DEBUG
extension MomentMapper {
    /// Create a mock NotionPageResponse with moment data for testing
    static func mockNotionPage(
        id: String = "mock-id",
        title: String = "Test Moment",
        type: String = "Gedanke",
        timestamp: String = "2025-10-22T12:00:00Z"
    ) -> NotionPageResponse {
        let properties: [String: NotionProperty] = [
            "Name": .title([NotionRichText.mock(content: title)]),
            "Typ": .select(NotionSelectOption.mock(name: type)),
            "Zeitpunkt": .date(NotionDate.mock(start: timestamp))
        ]

        return NotionPageResponse.mock(id: id, properties: properties)
    }
}
#endif
