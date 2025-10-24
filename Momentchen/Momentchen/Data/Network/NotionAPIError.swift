//
//  NotionAPIError.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation

/// Comprehensive error types for Notion API operations
/// Provides user-friendly German error messages and retry logic detection
enum NotionAPIError: Error, LocalizedError, Sendable {
    // MARK: - Error Cases

    /// Token is invalid or missing
    case invalidToken

    /// Token is valid but lacks necessary permissions
    case unauthorized

    /// Access forbidden to specific resource
    case forbidden(resource: String)

    /// Resource not found
    case notFound(resource: String)

    /// Rate limit exceeded (429)
    case rateLimited(retryAfter: TimeInterval?)

    /// Bad request with validation details
    case badRequest(message: String)

    /// Server error with status code
    case serverError(statusCode: Int, message: String?)

    /// Network connectivity error
    case networkError(underlying: Error)

    /// JSON decoding failed
    case decodingError(underlying: Error, data: Data?)

    /// JSON encoding failed
    case encodingError(underlying: Error)

    /// Validation error (client-side)
    case validationError(message: String)

    /// Invalid URL construction
    case invalidURL(endpoint: String)

    /// Unknown error
    case unknown(underlying: Error)

    // MARK: - LocalizedError Implementation

    var errorDescription: String? {
        userMessage
    }

    /// User-friendly German error message
    var userMessage: String {
        switch self {
        case .invalidToken:
            return "Ungültiger Notion Token. Bitte überprüfe deinen Token."

        case .unauthorized:
            return "Token ungültig oder abgelaufen. Bitte melde dich neu an."

        case .forbidden(let resource):
            return "Keine Berechtigung für \(resource). Bitte überprüfe die Integration-Berechtigungen."

        case .notFound(let resource):
            return "\(resource) nicht gefunden. Die Datenbank existiert möglicherweise nicht mehr."

        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Zu viele Anfragen. Bitte warte \(Int(seconds)) Sekunden."
            }
            return "Zu viele Anfragen. Bitte warte einen Moment."

        case .badRequest(let message):
            return "Ungültige Anfrage: \(message)"

        case .serverError(let code, let message):
            if let msg = message {
                return "Notion Server-Fehler (\(code)): \(msg)"
            }
            return "Notion Server-Fehler (\(code)). Bitte versuche es später erneut."

        case .networkError:
            return "Netzwerkfehler. Bitte überprüfe deine Internetverbindung."

        case .decodingError:
            return "Fehler beim Verarbeiten der Antwort von Notion."

        case .encodingError:
            return "Fehler beim Erstellen der Anfrage."

        case .validationError(let message):
            return message

        case .invalidURL(let endpoint):
            return "Ungültiger API-Endpoint: \(endpoint)"

        case .unknown:
            return "Ein unerwarteter Fehler ist aufgetreten."
        }
    }

    // MARK: - Retry Logic

    /// Indicates whether this error should trigger a retry
    var isRetryable: Bool {
        switch self {
        case .rateLimited:
            return true
        case .networkError:
            return true
        case .serverError(let code, _):
            // Retry on 5xx server errors or code 429 (though rateLimited case should catch 429)
            return code >= 500 || code == 429
        default:
            return false
        }
    }

    /// Suggested delay before retry (in seconds)
    var retryDelay: TimeInterval {
        switch self {
        case .rateLimited(let retryAfter):
            return retryAfter ?? 2.0
        case .serverError:
            return 1.0
        case .networkError:
            return 0.5
        default:
            return 0
        }
    }

    // MARK: - HTTP Status Code Mapping

    /// Creates error from HTTP response
    /// - Parameters:
    ///   - statusCode: HTTP status code
    ///   - data: Response data (for parsing error message)
    ///   - headers: HTTP headers (for rate limit info)
    /// - Returns: Appropriate NotionAPIError
    static func fromHTTPResponse(
        statusCode: Int,
        data: Data?,
        headers: [AnyHashable: Any]?
    ) -> NotionAPIError {
        // Parse error message from response body
        var errorMessage: String?
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String {
            errorMessage = message
        }

        switch statusCode {
        case 400:
            return .badRequest(message: errorMessage ?? "Ungültige Anfrage")

        case 401:
            return .unauthorized

        case 403:
            let resource = errorMessage ?? "diese Ressource"
            return .forbidden(resource: resource)

        case 404:
            let resource = errorMessage ?? "Ressource"
            return .notFound(resource: resource)

        case 429:
            // Check for Retry-After header
            var retryAfter: TimeInterval?
            if let headers = headers,
               let retryAfterHeader = headers["Retry-After"] as? String,
               let seconds = TimeInterval(retryAfterHeader) {
                retryAfter = seconds
            }
            return .rateLimited(retryAfter: retryAfter)

        case 500...599:
            return .serverError(statusCode: statusCode, message: errorMessage)

        default:
            return .serverError(statusCode: statusCode, message: errorMessage)
        }
    }

    // MARK: - Logging Support

    /// Technical details for logging (not shown to user)
    var technicalDetails: String {
        switch self {
        case .invalidToken:
            return "Invalid Notion token provided"

        case .unauthorized:
            return "HTTP 401: Unauthorized"

        case .forbidden(let resource):
            return "HTTP 403: Forbidden access to \(resource)"

        case .notFound(let resource):
            return "HTTP 404: \(resource) not found"

        case .rateLimited(let retryAfter):
            return "HTTP 429: Rate limited (retry after \(retryAfter ?? 0)s)"

        case .badRequest(let message):
            return "HTTP 400: \(message)"

        case .serverError(let code, let message):
            return "HTTP \(code): \(message ?? "Unknown server error")"

        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"

        case .decodingError(let error, let data):
            var details = "Decoding error: \(error.localizedDescription)"
            if let data = data, let string = String(data: data, encoding: .utf8) {
                details += "\nResponse data: \(string.prefix(200))"
            }
            return details

        case .encodingError(let error):
            return "Encoding error: \(error.localizedDescription)"

        case .validationError(let message):
            return "Validation error: \(message)"

        case .invalidURL(let endpoint):
            return "Invalid URL for endpoint: \(endpoint)"

        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Equatable (for testing)

extension NotionAPIError: Equatable {
    static func == (lhs: NotionAPIError, rhs: NotionAPIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidToken, .invalidToken),
             (.unauthorized, .unauthorized):
            return true

        case (.forbidden(let lResource), .forbidden(let rResource)):
            return lResource == rResource

        case (.notFound(let lResource), .notFound(let rResource)):
            return lResource == rResource

        case (.rateLimited(let lRetry), .rateLimited(let rRetry)):
            return lRetry == rRetry

        case (.badRequest(let lMsg), .badRequest(let rMsg)):
            return lMsg == rMsg

        case (.serverError(let lCode, let lMsg), .serverError(let rCode, let rMsg)):
            return lCode == rCode && lMsg == rMsg

        case (.validationError(let lMsg), .validationError(let rMsg)):
            return lMsg == rMsg

        case (.invalidURL(let lEndpoint), .invalidURL(let rEndpoint)):
            return lEndpoint == rEndpoint

        default:
            return false
        }
    }
}

