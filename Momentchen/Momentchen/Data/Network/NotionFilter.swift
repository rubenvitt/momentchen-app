//
//  NotionFilter.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation

/// Type-safe filter builder for Notion database queries
/// Supports date filters, status filters, and compound filters
struct NotionFilter: Codable, Sendable {
    // MARK: - Filter Types

    private let filterType: FilterType

    private enum FilterType: Codable, Sendable {
        case date(property: String, condition: DateCondition)
        case status(property: String, condition: StatusCondition)
        case select(property: String, condition: SelectCondition)
        case checkbox(property: String, condition: CheckboxCondition)
        case and([NotionFilter])
        case or([NotionFilter])
    }

    // MARK: - Initialization

    private init(filterType: FilterType) {
        self.filterType = filterType
    }

    // MARK: - Date Filters

    /// Creates a date filter
    /// - Parameters:
    ///   - property: Property name (e.g., "Zeitpunkt")
    ///   - condition: Date condition
    /// - Returns: Date filter
    static func date(_ property: String, _ condition: DateCondition) -> NotionFilter {
        NotionFilter(filterType: .date(property: property, condition: condition))
    }

    /// Date filter conditions
    enum DateCondition: Codable, Sendable {
        case equals(String)
        case before(String)
        case after(String)
        case onOrBefore(String)
        case onOrAfter(String)
        case isNotEmpty
        case isEmpty

        var key: String {
            switch self {
            case .equals: return "equals"
            case .before: return "before"
            case .after: return "after"
            case .onOrBefore: return "on_or_before"
            case .onOrAfter: return "on_or_after"
            case .isNotEmpty: return "is_not_empty"
            case .isEmpty: return "is_empty"
            }
        }

        var value: ConditionValue? {
            switch self {
            case .equals(let date): return .string(date)
            case .before(let date): return .string(date)
            case .after(let date): return .string(date)
            case .onOrBefore(let date): return .string(date)
            case .onOrAfter(let date): return .string(date)
            case .isNotEmpty: return .bool(true)
            case .isEmpty: return .bool(true)
            }
        }
    }

    // MARK: - Status Filters

    /// Creates a status filter
    /// - Parameters:
    ///   - property: Property name (e.g., "Status")
    ///   - condition: Status condition
    /// - Returns: Status filter
    static func status(_ property: String, _ condition: StatusCondition) -> NotionFilter {
        NotionFilter(filterType: .status(property: property, condition: condition))
    }

    /// Status filter conditions
    enum StatusCondition: Codable, Sendable {
        case equals(String)
        case doesNotEqual(String)
        case isNotEmpty
        case isEmpty

        var key: String {
            switch self {
            case .equals: return "equals"
            case .doesNotEqual: return "does_not_equal"
            case .isNotEmpty: return "is_not_empty"
            case .isEmpty: return "is_empty"
            }
        }

        var value: ConditionValue? {
            switch self {
            case .equals(let status): return .string(status)
            case .doesNotEqual(let status): return .string(status)
            case .isNotEmpty: return .bool(true)
            case .isEmpty: return .bool(true)
            }
        }
    }

    // MARK: - Select Filters

    /// Creates a select filter
    /// - Parameters:
    ///   - property: Property name (e.g., "Typ")
    ///   - condition: Select condition
    /// - Returns: Select filter
    static func select(_ property: String, _ condition: SelectCondition) -> NotionFilter {
        NotionFilter(filterType: .select(property: property, condition: condition))
    }

    /// Select filter conditions
    enum SelectCondition: Codable, Sendable {
        case equals(String)
        case doesNotEqual(String)
        case isNotEmpty
        case isEmpty

        var key: String {
            switch self {
            case .equals: return "equals"
            case .doesNotEqual: return "does_not_equal"
            case .isNotEmpty: return "is_not_empty"
            case .isEmpty: return "is_empty"
            }
        }

        var value: ConditionValue? {
            switch self {
            case .equals(let option): return .string(option)
            case .doesNotEqual(let option): return .string(option)
            case .isNotEmpty: return .bool(true)
            case .isEmpty: return .bool(true)
            }
        }
    }

    // MARK: - Checkbox Filters

    /// Creates a checkbox filter
    /// - Parameters:
    ///   - property: Property name (e.g., "⭐ Tagesfavorit")
    ///   - condition: Checkbox condition
    /// - Returns: Checkbox filter
    static func checkbox(_ property: String, _ condition: CheckboxCondition) -> NotionFilter {
        NotionFilter(filterType: .checkbox(property: property, condition: condition))
    }

    /// Checkbox filter conditions
    enum CheckboxCondition: Codable, Sendable {
        case equals(Bool)
        case doesNotEqual(Bool)

        var key: String {
            switch self {
            case .equals: return "equals"
            case .doesNotEqual: return "does_not_equal"
            }
        }

        var value: ConditionValue? {
            switch self {
            case .equals(let checked): return .bool(checked)
            case .doesNotEqual(let checked): return .bool(checked)
            }
        }
    }

    /// Type-safe wrapper for filter condition values
    enum ConditionValue: Encodable, Sendable {
        case string(String)
        case bool(Bool)

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let s): try container.encode(s)
            case .bool(let b): try container.encode(b)
            }
        }
    }

    // MARK: - Compound Filters

    /// Creates an AND compound filter
    /// - Parameter filters: Filters to combine with AND
    /// - Returns: AND filter
    static func and(_ filters: [NotionFilter]) -> NotionFilter {
        NotionFilter(filterType: .and(filters))
    }

    /// Creates an OR compound filter
    /// - Parameter filters: Filters to combine with OR
    /// - Returns: OR filter
    static func or(_ filters: [NotionFilter]) -> NotionFilter {
        NotionFilter(filterType: .or(filters))
    }

    // MARK: - Helper Methods

    /// Filter for today's moments (UTC date equals today)
    /// - Parameter datePropertyName: Name of the date property (default: "Zeitpunkt")
    /// - Returns: Filter for today's moments
    static func todayMoments(datePropertyName: String = "Zeitpunkt") -> NotionFilter {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        return .date(datePropertyName, .equals(String(today)))
    }

    /// Filter for active projects (Status equals "In Bearbeitung")
    /// - Parameter statusPropertyName: Name of the status property (default: "Status")
    /// - Returns: Filter for active projects
    static func activeProjects(statusPropertyName: String = "Status") -> NotionFilter {
        .status(statusPropertyName, .equals("In Bearbeitung"))
    }

    /// Filter for active life areas (Status equals "Aktiv")
    /// - Parameter statusPropertyName: Name of the status property (default: "Status")
    /// - Returns: Filter for active life areas
    static func activeLifeAreas(statusPropertyName: String = "Status") -> NotionFilter {
        .status(statusPropertyName, .equals("Aktiv"))
    }

    /// Filter for moments on or after a specific date
    /// - Parameters:
    ///   - date: Start date
    ///   - propertyName: Date property name (default: "Zeitpunkt")
    /// - Returns: Date range filter
    static func momentsOnOrAfter(_ date: Date, propertyName: String = "Zeitpunkt") -> NotionFilter {
        let dateString = ISO8601DateFormatter().string(from: date).prefix(10)
        return .date(propertyName, .onOrAfter(String(dateString)))
    }

    /// Filter for moments before a specific date
    /// - Parameters:
    ///   - date: End date
    ///   - propertyName: Date property name (default: "Zeitpunkt")
    /// - Returns: Date range filter
    static func momentsBefore(_ date: Date, propertyName: String = "Zeitpunkt") -> NotionFilter {
        let dateString = ISO8601DateFormatter().string(from: date).prefix(10)
        return .date(propertyName, .before(String(dateString)))
    }

    /// Filter for moments between two dates
    /// - Parameters:
    ///   - startDate: Start date (inclusive)
    ///   - endDate: End date (exclusive)
    ///   - propertyName: Date property name (default: "Zeitpunkt")
    /// - Returns: Date range filter
    static func momentsBetween(
        _ startDate: Date,
        and endDate: Date,
        propertyName: String = "Zeitpunkt"
    ) -> NotionFilter {
        .and([
            .momentsOnOrAfter(startDate, propertyName: propertyName),
            .momentsBefore(endDate, propertyName: propertyName)
        ])
    }

    // MARK: - Codable Implementation

    enum CodingKeys: String, CodingKey {
        case property
        case date
        case status
        case select
        case checkbox
        case and
        case or
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.contains(.and) {
            let filters = try container.decode([NotionFilter].self, forKey: .and)
            self.filterType = .and(filters)
        } else if container.contains(.or) {
            let filters = try container.decode([NotionFilter].self, forKey: .or)
            self.filterType = .or(filters)
        } else {
            // Default to date filter for simplicity
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unknown filter type"
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch filterType {
        case .date(let property, let condition):
            try container.encode(property, forKey: .property)
            var dateContainer = container.nestedContainer(
                keyedBy: DynamicCodingKey.self,
                forKey: .date
            )
            if let value = condition.value {
                try dateContainer.encode(
                    AnyEncodable(value),
                    forKey: DynamicCodingKey(stringValue: condition.key)
                )
            }

        case .status(let property, let condition):
            try container.encode(property, forKey: .property)
            var statusContainer = container.nestedContainer(
                keyedBy: DynamicCodingKey.self,
                forKey: .status
            )
            if let value = condition.value {
                try statusContainer.encode(
                    AnyEncodable(value),
                    forKey: DynamicCodingKey(stringValue: condition.key)
                )
            }

        case .select(let property, let condition):
            try container.encode(property, forKey: .property)
            var selectContainer = container.nestedContainer(
                keyedBy: DynamicCodingKey.self,
                forKey: .select
            )
            if let value = condition.value {
                try selectContainer.encode(
                    AnyEncodable(value),
                    forKey: DynamicCodingKey(stringValue: condition.key)
                )
            }

        case .checkbox(let property, let condition):
            try container.encode(property, forKey: .property)
            var checkboxContainer = container.nestedContainer(
                keyedBy: DynamicCodingKey.self,
                forKey: .checkbox
            )
            if let value = condition.value {
                try checkboxContainer.encode(
                    AnyEncodable(value),
                    forKey: DynamicCodingKey(stringValue: condition.key)
                )
            }

        case .and(let filters):
            try container.encode(filters, forKey: .and)

        case .or(let filters):
            try container.encode(filters, forKey: .or)
        }
    }
}

// MARK: - Supporting Types

/// Dynamic coding key for encoding filter conditions
private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        return nil
    }
}

/// Type-erased encodable wrapper
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

// MARK: - Test Helpers

#if DEBUG
extension NotionFilter {
    /// Create a mock filter for testing
    static func mock() -> NotionFilter {
        .todayMoments()
    }
}
#endif
