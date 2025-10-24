//
//  NotionAPIService.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation
import OSLog

/// Protocol defining the Notion API service interface
/// Enables mocking for testing and dependency injection
protocol NotionAPIServiceProtocol: Sendable {
    /// Validates the Notion token and returns user information
    /// - Parameter token: Notion integration token
    /// - Returns: User information if token is valid
    /// - Throws: NotionAPIError if validation fails
    func validateToken(token: String) async throws -> NotionUser

    /// Searches for databases accessible by the integration
    /// - Parameter token: Notion integration token
    /// - Returns: Array of databases
    /// - Throws: NotionAPIError if search fails
    func searchDatabases(token: String) async throws -> [NotionDatabaseResponse]

    /// Queries a database with optional filtering and sorting
    /// - Parameters:
    ///   - token: Notion integration token
    ///   - databaseId: Database ID to query
    ///   - filter: Optional filter criteria
    ///   - sorts: Optional sort criteria
    ///   - pageSize: Results per page (default: 100)
    /// - Returns: Array of pages matching the query
    /// - Throws: NotionAPIError if query fails
    func queryDatabase(
        token: String,
        databaseId: String,
        filter: NotionFilter?,
        sorts: [NotionSort]?,
        pageSize: Int
    ) async throws -> [NotionPageResponse]

    /// Creates a new page in a database
    /// - Parameters:
    ///   - token: Notion integration token
    ///   - databaseId: Target database ID
    ///   - properties: Page properties
    /// - Returns: Created page
    /// - Throws: NotionAPIError if creation fails
    func createPage(
        token: String,
        databaseId: String,
        properties: [String: NotionProperty]
    ) async throws -> NotionPageResponse

    /// Updates an existing page
    /// - Parameters:
    ///   - token: Notion integration token
    ///   - pageId: Page ID to update
    ///   - properties: Updated properties
    /// - Returns: Updated page
    /// - Throws: NotionAPIError if update fails
    func updatePage(
        token: String,
        pageId: String,
        properties: [String: NotionProperty]
    ) async throws -> NotionPageResponse

    /// Gets select options for a database property
    /// - Parameters:
    ///   - token: Notion integration token
    ///   - databaseId: Database ID
    ///   - propertyName: Name of the select property
    /// - Returns: Array of select options
    /// - Throws: NotionAPIError if retrieval fails
    func getSelectOptions(
        token: String,
        databaseId: String,
        propertyName: String
    ) async throws -> [NotionSelectOption]

    /// Archives a page (soft delete)
    /// - Parameters:
    ///   - token: Notion integration token
    ///   - pageId: Page ID to archive
    /// - Throws: NotionAPIError if archive fails
    func archivePage(token: String, pageId: String) async throws
}

/// Main implementation of Notion API service
/// Handles all HTTP communication with Notion REST API v1
actor NotionAPIService: NotionAPIServiceProtocol {
    // MARK: - Properties

    private let baseURL: URL
    private let notionVersion: String
    private let session: URLSession
    private let logger: Logger
    private let maxRetries: Int

    // MARK: - Initialization

    /// Creates a new Notion API service
    /// - Parameters:
    ///   - baseURL: Notion API base URL (default: https://api.notion.com/v1)
    ///   - notionVersion: API version (default: 2022-06-28)
    ///   - session: URLSession for network calls (default: custom configured session)
    ///   - maxRetries: Maximum retry attempts for failed requests (default: 3)
    init(
        baseURL: URL = URL(string: "https://api.notion.com/v1")!,
        notionVersion: String = "2022-06-28",
        session: URLSession? = nil,
        maxRetries: Int = 3
    ) {
        self.baseURL = baseURL
        self.notionVersion = notionVersion
        self.maxRetries = maxRetries
        self.logger = Logger(subsystem: "com.momentchen.app", category: "NotionAPI")

        // Configure session if not provided
        if let session = session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 15.0
            config.timeoutIntervalForResource = 30.0
            config.httpMaximumConnectionsPerHost = 5
            config.waitsForConnectivity = true
            self.session = URLSession(configuration: config)
        }
    }

    // MARK: - Public API Methods

    func validateToken(token: String) async throws -> NotionUser {
        logger.info("Validating Notion token")

        let requestBuilder = NotionRequestBuilder(
            baseURL: baseURL,
            notionVersion: notionVersion,
            token: token
        )

        let request = try requestBuilder.buildGETRequest(endpoint: "/users/me")

        let user: NotionUser = try await performRequest(request, retryCount: 0)

        logger.info("Token validated successfully for user: \(user.id)")
        return user
    }

    func searchDatabases(token: String) async throws -> [NotionDatabaseResponse] {
        logger.info("Searching for databases")

        let requestBuilder = NotionRequestBuilder(
            baseURL: baseURL,
            notionVersion: notionVersion,
            token: token
        )

        let body = SearchDatabasesRequest(pageSize: 100)
        let request = try requestBuilder.buildPOSTRequest(endpoint: "/search", body: body)

        let response: NotionSearchResponse = try await performRequest(request, retryCount: 0)

        logger.info("Found \(response.results.count) databases")

        // Handle pagination if needed
        var allDatabases = response.results
        if response.hasMore, let cursor = response.nextCursor {
            let additionalDatabases = try await searchDatabasesWithCursor(
                token: token,
                cursor: cursor
            )
            allDatabases.append(contentsOf: additionalDatabases)
        }

        return allDatabases
    }

    func queryDatabase(
        token: String,
        databaseId: String,
        filter: NotionFilter? = nil,
        sorts: [NotionSort]? = nil,
        pageSize: Int = 100
    ) async throws -> [NotionPageResponse] {
        logger.info("Querying database: \(databaseId)")

        let requestBuilder = NotionRequestBuilder(
            baseURL: baseURL,
            notionVersion: notionVersion,
            token: token
        )

        let body = QueryDatabaseRequest(
            filter: filter,
            sorts: sorts,
            pageSize: pageSize
        )

        let request = try requestBuilder.buildPOSTRequest(
            endpoint: "/databases/\(databaseId)/query",
            body: body
        )

        let response: NotionQueryResponse = try await performRequest(request, retryCount: 0)

        logger.info("Query returned \(response.results.count) pages")

        // Handle pagination
        var allPages = response.results
        if response.hasMore, let cursor = response.nextCursor {
            let additionalPages = try await queryDatabaseWithCursor(
                token: token,
                databaseId: databaseId,
                filter: filter,
                sorts: sorts,
                cursor: cursor
            )
            allPages.append(contentsOf: additionalPages)
        }

        return allPages
    }

    func createPage(
        token: String,
        databaseId: String,
        properties: [String: NotionProperty]
    ) async throws -> NotionPageResponse {
        logger.info("Creating page in database: \(databaseId)")

        let requestBuilder = NotionRequestBuilder(
            baseURL: baseURL,
            notionVersion: notionVersion,
            token: token
        )

        let body = CreatePageRequest(databaseId: databaseId, properties: properties)
        let request = try requestBuilder.buildPOSTRequest(endpoint: "/pages", body: body)

        let page: NotionPageResponse = try await performRequest(request, retryCount: 0)

        logger.info("Page created successfully: \(page.id)")
        return page
    }

    func updatePage(
        token: String,
        pageId: String,
        properties: [String: NotionProperty]
    ) async throws -> NotionPageResponse {
        logger.info("Updating page: \(pageId)")

        let requestBuilder = NotionRequestBuilder(
            baseURL: baseURL,
            notionVersion: notionVersion,
            token: token
        )

        let body = UpdatePageRequest(properties: properties)
        let request = try requestBuilder.buildPATCHRequest(
            endpoint: "/pages/\(pageId)",
            body: body
        )

        let page: NotionPageResponse = try await performRequest(request, retryCount: 0)

        logger.info("Page updated successfully: \(page.id)")
        return page
    }

    // MARK: - Private Helper Methods

    /// Performs a URLRequest with retry logic and error handling
    private func performRequest<T: Decodable>(
        _ request: URLRequest,
        retryCount: Int
    ) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NotionAPIError.networkError(
                    underlying: NSError(
                        domain: "NotionAPIService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response type"]
                    )
                )
            }

            // Log request details
            logger.debug("Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
            logger.debug("Status: \(httpResponse.statusCode)")

            // Check for successful status code
            guard (200...299).contains(httpResponse.statusCode) else {
                let error = NotionAPIError.fromHTTPResponse(
                    statusCode: httpResponse.statusCode,
                    data: data,
                    headers: httpResponse.allHeaderFields
                )

                logger.error("API error: \(error.technicalDetails)")

                // Retry logic for retryable errors
                if error.isRetryable && retryCount < maxRetries {
                    logger.info("Retrying request (attempt \(retryCount + 1)/\(self.maxRetries))")

                    // Calculate exponential backoff delay
                    let delay = error.retryDelay * pow(2.0, Double(retryCount))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                    return try await performRequest(request, retryCount: retryCount + 1)
                }

                throw error
            }

            // DEBUG: Log response size for troubleshooting (avoiding full JSON logging for large responses)
            logger.debug("Response data size: \(data.count) bytes")

            // Decode response
            let decoder = JSONDecoder()
            // NOTE: We use explicit CodingKeys instead of convertFromSnakeCase to avoid conflicts
            decoder.dateDecodingStrategy = .iso8601

            do {
                let result = try decoder.decode(T.self, from: data)
                return result
            } catch let DecodingError.keyNotFound(key, context) {
                logger.error("Decoding error - Missing key: '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                logger.error("Context: \(context.debugDescription)")
                throw NotionAPIError.decodingError(underlying: DecodingError.keyNotFound(key, context), data: data)
            } catch let DecodingError.typeMismatch(type, context) {
                logger.error("Decoding error - Type mismatch for type: \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                logger.error("Context: \(context.debugDescription)")
                throw NotionAPIError.decodingError(underlying: DecodingError.typeMismatch(type, context), data: data)
            } catch let DecodingError.valueNotFound(type, context) {
                logger.error("Decoding error - Value not found for type: \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                logger.error("Context: \(context.debugDescription)")
                throw NotionAPIError.decodingError(underlying: DecodingError.valueNotFound(type, context), data: data)
            } catch let DecodingError.dataCorrupted(context) {
                logger.error("Decoding error - Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                logger.error("Context: \(context.debugDescription)")
                throw NotionAPIError.decodingError(underlying: DecodingError.dataCorrupted(context), data: data)
            } catch {
                logger.error("Decoding error: \(error.localizedDescription)")
                logger.error("Error type: \(type(of: error))")
                throw NotionAPIError.decodingError(underlying: error, data: data)
            }

        } catch let error as NotionAPIError {
            throw error
        } catch {
            logger.error("Network error: \(error.localizedDescription)")
            throw NotionAPIError.networkError(underlying: error)
        }
    }

    /// Continues database search with pagination cursor
    private func searchDatabasesWithCursor(
        token: String,
        cursor: String
    ) async throws -> [NotionDatabaseResponse] {
        logger.debug("Fetching next page of databases with cursor")

        let requestBuilder = NotionRequestBuilder(
            baseURL: baseURL,
            notionVersion: notionVersion,
            token: token
        )

        // Create request with cursor (manual construction needed)
        var request = try requestBuilder.buildPOSTRequest(
            endpoint: "/search",
            body: SearchDatabasesRequest(pageSize: 100)
        )

        // Add cursor to body
        let bodyDict: [String: Any] = [
            "filter": ["property": "object", "value": "database"],
            "page_size": 100,
            "start_cursor": cursor
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict)

        let response: NotionSearchResponse = try await performRequest(request, retryCount: 0)

        var results = response.results

        if response.hasMore, let nextCursor = response.nextCursor {
            let moreResults = try await searchDatabasesWithCursor(token: token, cursor: nextCursor)
            results.append(contentsOf: moreResults)
        }

        return results
    }

    /// Continues database query with pagination cursor
    private func queryDatabaseWithCursor(
        token: String,
        databaseId: String,
        filter: NotionFilter?,
        sorts: [NotionSort]?,
        cursor: String
    ) async throws -> [NotionPageResponse] {
        logger.debug("Fetching next page of results with cursor")

        let requestBuilder = NotionRequestBuilder(
            baseURL: baseURL,
            notionVersion: notionVersion,
            token: token
        )

        let body = QueryDatabaseRequest(
            filter: filter,
            sorts: sorts,
            startCursor: cursor,
            pageSize: 100
        )

        let request = try requestBuilder.buildPOSTRequest(
            endpoint: "/databases/\(databaseId)/query",
            body: body
        )

        let response: NotionQueryResponse = try await performRequest(request, retryCount: 0)

        var results = response.results

        if response.hasMore, let nextCursor = response.nextCursor {
            let moreResults = try await queryDatabaseWithCursor(
                token: token,
                databaseId: databaseId,
                filter: filter,
                sorts: sorts,
                cursor: nextCursor
            )
            results.append(contentsOf: moreResults)
        }

        return results
    }
}

// MARK: - Convenience Extensions

extension NotionAPIService {
    /// Helper to extract select options from database schema
    /// - Parameters:
    ///   - token: Notion integration token
    ///   - databaseId: Database ID
    ///   - propertyName: Select property name (e.g., "Typ")
    /// - Returns: Array of select options
    /// - Throws: NotionAPIError if database fetch fails
    func getSelectOptions(
        token: String,
        databaseId: String,
        propertyName: String
    ) async throws -> [NotionSelectOption] {
        logger.info("Fetching select options for property: \(propertyName)")

        // Search for the specific database to get its schema
        let databases = try await searchDatabases(token: token)

        guard let database = databases.first(where: { $0.id == databaseId }),
              let properties = database.properties,
              let propertySchema = properties[propertyName],
              let selectOptions = propertySchema.select else {
            throw NotionAPIError.notFound(resource: "Property '\(propertyName)' in database")
        }

        return selectOptions.options
    }

    /// Archives a page (soft delete)
    /// - Parameters:
    ///   - token: Notion integration token
    ///   - pageId: Page ID to archive
    /// - Throws: NotionAPIError if archive fails
    func archivePage(token: String, pageId: String) async throws {
        logger.info("Archiving page: \(pageId)")

        let requestBuilder = NotionRequestBuilder(
            baseURL: baseURL,
            notionVersion: notionVersion,
            token: token
        )

        struct ArchiveRequest: Codable {
            let archived: Bool
        }

        let body = ArchiveRequest(archived: true)
        let request = try requestBuilder.buildPATCHRequest(
            endpoint: "/pages/\(pageId)",
            body: body
        )

        // We don't care about the response, just that it succeeded
        let _: NotionPageResponse = try await performRequest(request, retryCount: 0)

        logger.info("Page archived successfully: \(pageId)")
    }
}

// MARK: - Test Helpers

#if DEBUG
extension NotionAPIService {
    /// Creates a mock service for testing
    static func mock(session: URLSession? = nil) -> NotionAPIService {
        NotionAPIService(session: session)
    }
}
#endif
