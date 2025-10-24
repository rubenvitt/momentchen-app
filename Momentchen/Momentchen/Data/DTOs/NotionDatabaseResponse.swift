//
//  NotionDatabaseResponse.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation

/// Represents a Notion Database response from the API
/// Used for search results and database metadata
struct NotionDatabaseResponse: Codable, Sendable, Hashable {
    // MARK: - Properties

    /// Object type (always "database")
    let object: String

    /// Unique database identifier
    let id: String

    /// Database title
    let title: [NotionRichText]

    /// Database properties schema
    let properties: [String: NotionPropertySchema]?

    /// Creation timestamp (ISO8601)
    let createdTime: String?

    /// Last edited timestamp (ISO8601)
    let lastEditedTime: String?

    /// Whether the database is archived
    let archived: Bool?

    /// Cover image
    let cover: NotionCover?

    /// Icon
    let icon: NotionIcon?

    /// Created by user
    let createdBy: NotionUser?

    /// Last edited by user
    let lastEditedBy: NotionUser?

    /// Parent container
    let parent: NotionParent?

    /// Notion URL
    let url: String?

    /// Public URL (if published)
    let publicUrl: String?

    /// Database description
    let description: [NotionRichText]?

    /// Whether database is inline
    let isInline: Bool?

    /// Whether database is in trash
    let inTrash: Bool?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case object
        case id
        case title
        case properties
        case createdTime = "created_time"
        case lastEditedTime = "last_edited_time"
        case archived
        case cover
        case icon
        case createdBy = "created_by"
        case lastEditedBy = "last_edited_by"
        case parent
        case url
        case publicUrl = "public_url"
        case description
        case isInline = "is_inline"
        case inTrash = "in_trash"
    }

    // MARK: - Helper Methods

    /// Get database title as plain string
    var plainTitle: String {
        // Debug logging
        if let firstTitle = title.first {
            print("DEBUG: Database \(id) - type: \(firstTitle.type), plainText: \(String(describing: firstTitle.plainText)), text.content: \(String(describing: firstTitle.text?.content))")
        }

        // Try plainText first, then fall back to text.content, then ID
        if let plainText = (title.first?.plainText).flatMap({ $0 }), !plainText.isEmpty {
            return plainText
        }
        if let textContent = title.first?.text?.content, !textContent.isEmpty {
            return textContent
        }
        return "Untitled (\(id.prefix(8)))"
    }
}

// MARK: - Property Schema

/// Represents the schema of a database property
struct NotionPropertySchema: Codable, Sendable, Hashable {
    /// Property ID
    let id: String

    /// Property name
    let name: String?

    /// Property description
    let description: String?

    /// Property type (title, select, date, relation, etc.)
    let type: String

    /// Select options (if type is select)
    let select: SelectOptions?

    /// Multi-select options (if type is multi_select)
    let multiSelect: MultiSelectOptions?

    /// Status options (if type is status)
    let status: StatusOptions?

    /// Relation configuration (if type is relation)
    let relation: RelationConfig?

    // Custom decoding to handle all possible property types without defining each one
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required fields
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)

        // Optional fields
        name = try container.decodeIfPresent(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        select = try container.decodeIfPresent(SelectOptions.self, forKey: .select)
        multiSelect = try container.decodeIfPresent(MultiSelectOptions.self, forKey: .multiSelect)
        status = try container.decodeIfPresent(StatusOptions.self, forKey: .status)
        relation = try container.decodeIfPresent(RelationConfig.self, forKey: .relation)

        // All other property types are ignored - we only decode what we need
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(select, forKey: .select)
        try container.encodeIfPresent(multiSelect, forKey: .multiSelect)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(relation, forKey: .relation)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case type
        case select
        case multiSelect = "multi_select"
        case status
        case relation
    }

    // MARK: - Nested Types

    struct EmptyConfig: Codable, Sendable, Hashable {
        // Empty configuration for properties without options
    }

    struct SelectOptions: Codable, Sendable, Hashable {
        let options: [NotionSelectOption]
    }

    struct MultiSelectOptions: Codable, Sendable, Hashable {
        let options: [NotionSelectOption]
    }

    struct StatusOptions: Codable, Sendable, Hashable {
        let options: [NotionSelectOption]
        let groups: [StatusGroup]?

        struct StatusGroup: Codable, Sendable, Hashable {
            let id: String?
            let name: String?
            let color: String?
            let optionIds: [String]?

            enum CodingKeys: String, CodingKey {
                case id
                case name
                case color
                case optionIds = "option_ids"
            }
        }
    }

    struct RelationConfig: Codable, Sendable, Hashable {
        let databaseId: String?
        let dataSourceId: String?
        let type: String?
        let dualProperty: DualPropertyConfig?
        let singleProperty: SinglePropertyConfig?

        struct DualPropertyConfig: Codable, Sendable, Hashable {
            let syncedPropertyId: String?
            let syncedPropertyName: String?

            enum CodingKeys: String, CodingKey {
                case syncedPropertyId = "synced_property_id"
                case syncedPropertyName = "synced_property_name"
            }
        }

        struct SinglePropertyConfig: Codable, Sendable, Hashable {
            // Empty struct for single_property relations
        }

        enum CodingKeys: String, CodingKey {
            case databaseId = "database_id"
            case dataSourceId = "data_source_id"
            case type
            case dualProperty = "dual_property"
            case singleProperty = "single_property"
        }
    }
}

// MARK: - Search Response Wrapper

/// Wrapper for database search responses
struct NotionSearchResponse: Codable, Sendable {
    /// Result databases
    let results: [NotionDatabaseResponse]

    /// Whether there are more results (defaults to false if not provided)
    let hasMore: Bool

    /// Cursor for next page
    let nextCursor: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        results = try container.decode([NotionDatabaseResponse].self, forKey: .results)
        hasMore = try container.decodeIfPresent(Bool.self, forKey: .hasMore) ?? false
        nextCursor = try container.decodeIfPresent(String.self, forKey: .nextCursor)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(results, forKey: .results)
        try container.encode(hasMore, forKey: .hasMore)
        try container.encodeIfPresent(nextCursor, forKey: .nextCursor)
    }

    enum CodingKeys: String, CodingKey {
        case results
        case hasMore = "has_more"
        case nextCursor = "next_cursor"
    }
}

// MARK: - Supporting Types for Database Response

/// Notion cover image
struct NotionCover: Codable, Sendable, Hashable {
    let type: String
    let external: NotionExternalFile?

    struct NotionExternalFile: Codable, Sendable, Hashable {
        let url: String
    }
}

/// Notion icon
struct NotionIcon: Codable, Sendable, Hashable {
    let type: String
    let emoji: String?
    let external: NotionExternalFile?

    struct NotionExternalFile: Codable, Sendable, Hashable {
        let url: String
    }
}

/// Notion parent reference
struct NotionParent: Codable, Sendable, Hashable {
    let type: String
    let workspace: Bool?
    let blockId: String?
    let pageId: String?
    let databaseId: String?

    enum CodingKeys: String, CodingKey {
        case type
        case workspace
        case blockId = "block_id"
        case pageId = "page_id"
        case databaseId = "database_id"
    }
}

// MARK: - Test Helpers

#if DEBUG
extension NotionDatabaseResponse {
    /// Create a mock database response for testing
    static func mock(
        id: String = "mock-db-id",
        title: String = "Test Database"
    ) -> NotionDatabaseResponse {
        NotionDatabaseResponse(
            object: "database",
            id: id,
            title: [NotionRichText.mock(content: title)],
            properties: nil,
            createdTime: "2025-10-22T12:00:00.000Z",
            lastEditedTime: "2025-10-22T12:00:00.000Z",
            archived: false,
            cover: nil,
            icon: nil,
            createdBy: nil,
            lastEditedBy: nil,
            parent: nil,
            url: nil,
            publicUrl: nil,
            description: nil,
            isInline: nil,
            inTrash: nil
        )
    }
}
#endif
