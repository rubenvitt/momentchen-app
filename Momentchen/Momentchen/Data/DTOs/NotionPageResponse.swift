//
//  NotionPageResponse.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation

/// Represents a Notion Page response from the API
/// Used for both query results and create/update responses
struct NotionPageResponse: Codable, Sendable {
    // MARK: - Properties

    /// Object type (always "page")
    let object: String

    /// Unique page identifier
    let id: String

    /// Creation timestamp (ISO8601)
    let createdTime: String

    /// Last edited timestamp (ISO8601)
    let lastEditedTime: String

    /// Page properties (dynamic based on database schema)
    let properties: [String: NotionProperty]

    /// Parent reference (database or page)
    let parent: Parent?

    /// Whether the page is archived
    let archived: Bool

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case object
        case id
        case createdTime = "created_time"
        case lastEditedTime = "last_edited_time"
        case properties
        case parent
        case archived
    }

    // MARK: - Nested Types

    /// Parent reference for the page
    struct Parent: Codable, Sendable {
        let type: String
        let databaseId: String?

        enum CodingKeys: String, CodingKey {
            case type
            case databaseId = "database_id"
        }
    }
}

// MARK: - Response Wrapper

/// Wrapper for paginated query responses
struct NotionQueryResponse: Codable, Sendable {
    /// Result pages
    let results: [NotionPageResponse]

    /// Whether there are more results
    let hasMore: Bool

    /// Cursor for next page
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case results
        case hasMore = "has_more"
        case nextCursor = "next_cursor"
    }
}

// MARK: - Test Helpers

#if DEBUG
extension NotionPageResponse {
    /// Create a mock page response for testing
    static func mock(
        id: String = "mock-page-id",
        properties: [String: NotionProperty] = [:]
    ) -> NotionPageResponse {
        NotionPageResponse(
            object: "page",
            id: id,
            createdTime: "2025-10-22T12:00:00.000Z",
            lastEditedTime: "2025-10-22T12:00:00.000Z",
            properties: properties,
            parent: Parent(type: "database_id", databaseId: "mock-db-id"),
            archived: false
        )
    }
}
#endif
