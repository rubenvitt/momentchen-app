//
//  NotionProperties.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation

/// Helper struct for building Notion properties
/// Simplifies the creation of property dictionaries for pages
struct NotionProperties: Sendable {
    // MARK: - Property Builders

    /// Creates a title property
    /// - Parameter content: Title text content
    /// - Returns: Title property
    static func title(_ content: String) -> NotionProperty {
        .title([
            NotionRichText(
                type: "text",
                text: NotionRichText.TextContent(content: content, link: nil),
                annotations: nil,
                plainText: content,
                href: nil
            )
        ])
    }

    /// Creates a rich text property
    /// - Parameter content: Rich text content
    /// - Returns: Rich text property
    static func richText(_ content: String) -> NotionProperty {
        .richText([
            NotionRichText(
                type: "text",
                text: NotionRichText.TextContent(content: content, link: nil),
                annotations: nil,
                plainText: content,
                href: nil
            )
        ])
    }

    /// Creates a select property
    /// - Parameter option: Option name
    /// - Returns: Select property
    static func select(_ option: String) -> NotionProperty {
        .select(NotionSelectOption(id: nil, name: option, color: nil, description: nil))
    }

    /// Creates a date property
    /// - Parameters:
    ///   - date: Date to set
    ///   - includeTime: Whether to include time (default: true)
    /// - Returns: Date property
    static func date(_ date: Date, includeTime: Bool = true) -> NotionProperty {
        let formatter = ISO8601DateFormatter()
        if !includeTime {
            formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        }

        let dateString = formatter.string(from: date)

        return .date(NotionDate(start: dateString, end: nil, timeZone: nil))
    }

    /// Creates a date property from ISO8601 string
    /// - Parameter isoString: ISO8601 date string
    /// - Returns: Date property
    static func date(isoString: String) -> NotionProperty {
        .date(NotionDate(start: isoString, end: nil, timeZone: nil))
    }

    /// Creates a date range property
    /// - Parameters:
    ///   - start: Start date
    ///   - end: End date
    /// - Returns: Date property with range
    static func dateRange(start: Date, end: Date) -> NotionProperty {
        let formatter = ISO8601DateFormatter()
        let startString = formatter.string(from: start)
        let endString = formatter.string(from: end)

        return .date(NotionDate(start: startString, end: endString, timeZone: nil))
    }

    /// Creates a relation property
    /// - Parameter pageIds: Related page IDs
    /// - Returns: Relation property
    static func relation(_ pageIds: [String]) -> NotionProperty {
        .relation(pageIds.map { NotionRelation(id: $0) })
    }

    /// Creates a relation property with single page
    /// - Parameter pageId: Related page ID
    /// - Returns: Relation property
    static func relation(_ pageId: String) -> NotionProperty {
        .relation([NotionRelation(id: pageId)])
    }

    /// Creates a checkbox property
    /// - Parameter checked: Checkbox state
    /// - Returns: Checkbox property
    static func checkbox(_ checked: Bool) -> NotionProperty {
        .checkbox(checked)
    }

    /// Creates a number property
    /// - Parameter value: Number value
    /// - Returns: Number property
    static func number(_ value: Double) -> NotionProperty {
        .number(value)
    }

    /// Creates a URL property
    /// - Parameter url: URL string
    /// - Returns: URL property
    static func url(_ url: String) -> NotionProperty {
        .url(url)
    }

    /// Creates an email property
    /// - Parameter email: Email address
    /// - Returns: Email property
    static func email(_ email: String) -> NotionProperty {
        .email(email)
    }

    /// Creates a phone number property
    /// - Parameter phone: Phone number
    /// - Returns: Phone number property
    static func phoneNumber(_ phone: String) -> NotionProperty {
        .phoneNumber(phone)
    }

    /// Creates a multi-select property
    /// - Parameter options: Array of option names
    /// - Returns: Multi-select property
    static func multiSelect(_ options: [String]) -> NotionProperty {
        .multiSelect(options.map { NotionSelectOption(id: nil, name: $0, color: nil, description: nil) })
    }

    /// Creates a status property
    /// - Parameter status: Status name
    /// - Returns: Status property
    static func status(_ status: String) -> NotionProperty {
        .status(NotionStatus(id: nil, name: status, color: nil))
    }
}

// MARK: - Moment-Specific Helpers

extension NotionProperties {
    /// Creates properties for a Moment page
    /// - Parameters:
    ///   - description: Moment description (title)
    ///   - type: Moment type (select option)
    ///   - timestamp: Moment timestamp
    ///   - projectId: Optional project relation ID
    ///   - lifeAreaId: Optional life area relation ID
    /// - Returns: Properties dictionary ready for Notion API
    static func momentProperties(
        description: String,
        type: String,
        timestamp: Date,
        projectId: String? = nil,
        lifeAreaId: String? = nil
    ) -> [String: NotionProperty] {
        var properties: [String: NotionProperty] = [
            "Name": title(description),
            "Typ": select(type),
            "Zeitpunkt": date(timestamp)
        ]

        if let projectId = projectId {
            properties["Projekt"] = relation(projectId)
        }

        if let lifeAreaId = lifeAreaId {
            properties["Lebensbereich"] = relation(lifeAreaId)
        }

        return properties
    }

    /// Updates properties for a Moment page (only changed values)
    /// - Parameters:
    ///   - description: Optional new description
    ///   - type: Optional new type
    ///   - timestamp: Optional new timestamp
    ///   - projectId: Optional new project relation ID
    ///   - lifeAreaId: Optional new life area relation ID
    /// - Returns: Properties dictionary with only changed values
    static func momentUpdateProperties(
        description: String? = nil,
        type: String? = nil,
        timestamp: Date? = nil,
        projectId: String? = nil,
        lifeAreaId: String? = nil
    ) -> [String: NotionProperty] {
        var properties: [String: NotionProperty] = [:]

        if let description = description {
            properties["Name"] = title(description)
        }

        if let type = type {
            properties["Typ"] = select(type)
        }

        if let timestamp = timestamp {
            properties["Zeitpunkt"] = date(timestamp)
        }

        if let projectId = projectId {
            properties["Projekt"] = relation(projectId)
        }

        if let lifeAreaId = lifeAreaId {
            properties["Lebensbereich"] = relation(lifeAreaId)
        }

        return properties
    }
}

// MARK: - Property Extraction Helpers

extension NotionPageResponse {
    /// Extracts title property value
    /// - Parameter propertyName: Name of title property
    /// - Returns: Plain text title or nil
    func extractTitle(_ propertyName: String) -> String? {
        guard let property = properties[propertyName],
              case .title(let richTexts) = property else {
            return nil
        }
        return (richTexts.first?.plainText).flatMap { $0 }
    }

    /// Extracts select property value
    /// - Parameter propertyName: Name of select property
    /// - Returns: Selected option name or nil
    func extractSelect(_ propertyName: String) -> String? {
        guard let property = properties[propertyName],
              case .select(let option) = property else {
            return nil
        }
        return option?.name
    }

    /// Extracts date property value
    /// - Parameter propertyName: Name of date property
    /// - Returns: Date object or nil
    func extractDate(_ propertyName: String) -> Date? {
        guard let property = properties[propertyName],
              case .date(let notionDate) = property,
              let dateString = notionDate?.start else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }

    /// Extracts relation property IDs
    /// - Parameter propertyName: Name of relation property
    /// - Returns: Array of related page IDs
    func extractRelations(_ propertyName: String) -> [String] {
        guard let property = properties[propertyName],
              case .relation(let relations) = property else {
            return []
        }
        return relations.map { $0.id }
    }

    /// Extracts first relation ID
    /// - Parameter propertyName: Name of relation property
    /// - Returns: First related page ID or nil
    func extractRelation(_ propertyName: String) -> String? {
        extractRelations(propertyName).first
    }

    /// Extracts checkbox property value
    /// - Parameter propertyName: Name of checkbox property
    /// - Returns: Checkbox state or false
    func extractCheckbox(_ propertyName: String) -> Bool {
        guard let property = properties[propertyName],
              case .checkbox(let checked) = property else {
            return false
        }
        return checked
    }

    /// Extracts number property value
    /// - Parameter propertyName: Name of number property
    /// - Returns: Number value or nil
    func extractNumber(_ propertyName: String) -> Double? {
        guard let property = properties[propertyName],
              case .number(let value) = property else {
            return nil
        }
        return value
    }

    /// Extracts status property value
    /// - Parameter propertyName: Name of status property
    /// - Returns: Status name or nil
    func extractStatus(_ propertyName: String) -> String? {
        guard let property = properties[propertyName],
              case .status(let status) = property else {
            return nil
        }
        return status?.name
    }
}

// MARK: - Database Schema Helpers

extension NotionDatabaseResponse {
    /// Extracts select options from database schema
    /// - Parameter propertyName: Name of select property
    /// - Returns: Array of select options
    func extractSelectOptions(_ propertyName: String) -> [NotionSelectOption] {
        guard let properties = properties,
              let propertySchema = properties[propertyName],
              propertySchema.type == "select",
              let selectOptions = propertySchema.select else {
            return []
        }
        return selectOptions.options
    }

    /// Extracts multi-select options from database schema
    /// - Parameter propertyName: Name of multi-select property
    /// - Returns: Array of select options
    func extractMultiSelectOptions(_ propertyName: String) -> [NotionSelectOption] {
        // Multi-select uses same structure as select
        extractSelectOptions(propertyName)
    }

    /// Extracts status options from database schema
    /// - Parameter propertyName: Name of status property
    /// - Returns: Array of status names (extracted from select options)
    func extractStatusOptions(_ propertyName: String) -> [String] {
        extractSelectOptions(propertyName).map { $0.name }
    }

    /// Checks if database has a specific property
    /// - Parameters:
    ///   - propertyName: Property name to check
    ///   - type: Expected property type (optional)
    /// - Returns: True if property exists with matching type
    func hasProperty(_ propertyName: String, ofType type: String? = nil) -> Bool {
        guard let properties = properties,
              let propertySchema = properties[propertyName] else {
            return false
        }

        if let type = type {
            return propertySchema.type == type
        }

        return true
    }
}

// MARK: - Test Helpers

#if DEBUG
extension NotionProperties {
    /// Creates mock properties for testing
    static func mock() -> [String: NotionProperty] {
        momentProperties(
            description: "Test Moment",
            type: "Gedanke",
            timestamp: Date()
        )
    }
}
#endif
