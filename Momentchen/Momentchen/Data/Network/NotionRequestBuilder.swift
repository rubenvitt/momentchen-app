//
//  NotionRequestBuilder.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation

/// Constructs URLRequests for Notion API with proper headers and body encoding
struct NotionRequestBuilder: Sendable {
    // MARK: - Properties

    private let baseURL: URL
    private let notionVersion: String
    private let token: String

    // MARK: - Initialization

    /// Creates a new request builder
    /// - Parameters:
    ///   - baseURL: Notion API base URL (default: https://api.notion.com/v1)
    ///   - notionVersion: API version (default: 2022-06-28)
    ///   - token: Bearer token for authentication
    init(
        baseURL: URL = URL(string: "https://api.notion.com/v1")!,
        notionVersion: String = "2022-06-28",
        token: String
    ) {
        self.baseURL = baseURL
        self.notionVersion = notionVersion
        self.token = token
    }

    // MARK: - Request Building

    /// Builds a URLRequest for a GET endpoint
    /// - Parameters:
    ///   - endpoint: API endpoint (e.g., "/users/me")
    ///   - queryParameters: Optional query parameters
    /// - Returns: Configured URLRequest
    /// - Throws: NotionAPIError if URL is invalid
    func buildGETRequest(
        endpoint: String,
        queryParameters: [String: String]? = nil
    ) throws -> URLRequest {
        let url = try buildURL(endpoint: endpoint, queryParameters: queryParameters)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addCommonHeaders(to: &request)
        return request
    }

    /// Builds a URLRequest for a POST endpoint
    /// - Parameters:
    ///   - endpoint: API endpoint (e.g., "/pages")
    ///   - body: Request body (must be Encodable)
    /// - Returns: Configured URLRequest
    /// - Throws: NotionAPIError if URL is invalid or encoding fails
    func buildPOSTRequest<T: Encodable>(
        endpoint: String,
        body: T
    ) throws -> URLRequest {
        let url = try buildURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addCommonHeaders(to: &request)
        request.httpBody = try encodeBody(body)
        return request
    }

    /// Builds a URLRequest for a PATCH endpoint
    /// - Parameters:
    ///   - endpoint: API endpoint (e.g., "/pages/{id}")
    ///   - body: Request body (must be Encodable)
    /// - Returns: Configured URLRequest
    /// - Throws: NotionAPIError if URL is invalid or encoding fails
    func buildPATCHRequest<T: Encodable>(
        endpoint: String,
        body: T
    ) throws -> URLRequest {
        let url = try buildURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        addCommonHeaders(to: &request)
        request.httpBody = try encodeBody(body)
        return request
    }

    /// Builds a URLRequest for a DELETE endpoint
    /// - Parameter endpoint: API endpoint
    /// - Returns: Configured URLRequest
    /// - Throws: NotionAPIError if URL is invalid
    func buildDELETERequest(endpoint: String) throws -> URLRequest {
        let url = try buildURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        addCommonHeaders(to: &request)
        return request
    }

    // MARK: - Private Helpers

    /// Builds URL with endpoint and optional query parameters
    private func buildURL(
        endpoint: String,
        queryParameters: [String: String]? = nil
    ) throws -> URL {
        let cleanEndpoint = endpoint.hasPrefix("/") ? String(endpoint.dropFirst()) : endpoint
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(cleanEndpoint),
            resolvingAgainstBaseURL: true
        ) else {
            throw NotionAPIError.invalidURL(endpoint: endpoint)
        }

        // Add query parameters if provided
        if let queryParameters = queryParameters, !queryParameters.isEmpty {
            components.queryItems = queryParameters.map { key, value in
                URLQueryItem(name: key, value: value)
            }
        }

        guard let url = components.url else {
            throw NotionAPIError.invalidURL(endpoint: endpoint)
        }

        return url
    }

    /// Adds common headers to request
    private func addCommonHeaders(to request: inout URLRequest) {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(notionVersion, forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
    }

    /// Encodes body to JSON
    private func encodeBody<T: Encodable>(_ body: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        do {
            return try encoder.encode(body)
        } catch {
            throw NotionAPIError.encodingError(underlying: error)
        }
    }
}

// MARK: - Request Body Types

/// Request body for creating a page
struct CreatePageRequest: Codable, Sendable {
    let parent: Parent
    let properties: [String: NotionProperty]

    struct Parent: Codable, Sendable {
        let databaseId: String

        enum CodingKeys: String, CodingKey {
            case databaseId = "database_id"
        }
    }

    /// Convenience initializer
    /// - Parameters:
    ///   - databaseId: Target database ID
    ///   - properties: Page properties
    init(databaseId: String, properties: [String: NotionProperty]) {
        self.parent = Parent(databaseId: databaseId)
        self.properties = properties
    }
}

/// Request body for updating a page
struct UpdatePageRequest: Codable, Sendable {
    let properties: [String: NotionProperty]
}

/// Request body for querying a database
struct QueryDatabaseRequest: Codable, Sendable {
    let filter: NotionFilter?
    let sorts: [NotionSort]?
    let startCursor: String?
    let pageSize: Int

    enum CodingKeys: String, CodingKey {
        case filter
        case sorts
        case startCursor = "start_cursor"
        case pageSize = "page_size"
    }

    /// Convenience initializer
    /// - Parameters:
    ///   - filter: Optional filter
    ///   - sorts: Optional sorts
    ///   - startCursor: Pagination cursor
    ///   - pageSize: Results per page (default: 100)
    init(
        filter: NotionFilter? = nil,
        sorts: [NotionSort]? = nil,
        startCursor: String? = nil,
        pageSize: Int = 100
    ) {
        self.filter = filter
        self.sorts = sorts
        self.startCursor = startCursor
        self.pageSize = pageSize
    }
}

/// Request body for searching databases
struct SearchDatabasesRequest: Codable, Sendable {
    let filter: Filter
    let pageSize: Int

    struct Filter: Codable, Sendable {
        let property: String
        let value: String
    }

    enum CodingKeys: String, CodingKey {
        case filter
        case pageSize = "page_size"
    }

    /// Default initializer for searching databases only
    init(pageSize: Int = 100) {
        self.filter = Filter(property: "object", value: "database")
        self.pageSize = pageSize
    }
}

// MARK: - Sort Types

/// Sort configuration for database queries
struct NotionSort: Codable, Sendable {
    let property: String?
    let timestamp: String?
    let direction: Direction

    enum Direction: String, Codable, Sendable {
        case ascending
        case descending
    }

    /// Creates a property-based sort
    /// - Parameters:
    ///   - property: Property name to sort by
    ///   - direction: Sort direction (default: ascending)
    /// - Returns: Property sort
    static func property(_ property: String, direction: Direction = .ascending) -> NotionSort {
        NotionSort(property: property, timestamp: nil, direction: direction)
    }

    /// Creates a timestamp-based sort
    /// - Parameters:
    ///   - timestamp: Timestamp type ("created_time" or "last_edited_time")
    ///   - direction: Sort direction (default: descending)
    /// - Returns: Timestamp sort
    static func timestamp(_ timestamp: String, direction: Direction = .descending) -> NotionSort {
        NotionSort(property: nil, timestamp: timestamp, direction: direction)
    }

    /// Sort by created time (newest first)
    static var createdTimeDescending: NotionSort {
        .timestamp("created_time", direction: .descending)
    }

    /// Sort by last edited time (newest first)
    static var lastEditedTimeDescending: NotionSort {
        .timestamp("last_edited_time", direction: .descending)
    }
}

// MARK: - Test Helpers

#if DEBUG
extension NotionRequestBuilder {
    /// Creates a mock builder for testing
    static func mock(token: String = "mock-token") -> NotionRequestBuilder {
        NotionRequestBuilder(token: token)
    }
}

extension CreatePageRequest {
    /// Creates a mock request for testing
    static func mock(
        databaseId: String = "mock-db-id",
        properties: [String: NotionProperty] = [:]
    ) -> CreatePageRequest {
        CreatePageRequest(databaseId: databaseId, properties: properties)
    }
}

extension QueryDatabaseRequest {
    /// Creates a mock request for testing
    static func mock(
        filter: NotionFilter? = nil,
        pageSize: Int = 100
    ) -> QueryDatabaseRequest {
        QueryDatabaseRequest(filter: filter, pageSize: pageSize)
    }
}
#endif
