//
//  NotionPropertyTypes.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import Foundation

/// Enum representing all Notion property types
/// Uses associated values to carry type-specific data
enum NotionProperty: Codable, Sendable {
    // MARK: - Cases

    case title([NotionRichText])
    case richText([NotionRichText])
    case select(NotionSelectOption?)
    case multiSelect([NotionSelectOption])
    case date(NotionDate?)
    case people([NotionUser])
    case files([NotionFile])
    case checkbox(Bool)
    case url(String?)
    case email(String?)
    case phoneNumber(String?)
    case number(Double?)
    case status(NotionStatus?)
    case relation([NotionRelation])
    case rollup(NotionRollup?)
    case createdTime(String)
    case createdBy(NotionUser)
    case lastEditedTime(String)
    case lastEditedBy(NotionUser)
    case formula(NotionFormula?)
    case unsupported

    // MARK: - Coding

    enum CodingKeys: String, CodingKey {
        case type
        case title
        case richText = "rich_text"
        case select
        case multiSelect = "multi_select"
        case date
        case people
        case files
        case checkbox
        case url
        case email
        case phoneNumber = "phone_number"
        case number
        case status
        case relation
        case rollup
        case createdTime = "created_time"
        case createdBy = "created_by"
        case lastEditedTime = "last_edited_time"
        case lastEditedBy = "last_edited_by"
        case formula
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "title":
            let value = try container.decode([NotionRichText].self, forKey: .title)
            self = .title(value)
        case "rich_text":
            let value = try container.decode([NotionRichText].self, forKey: .richText)
            self = .richText(value)
        case "select":
            let value = try container.decodeIfPresent(NotionSelectOption.self, forKey: .select)
            self = .select(value)
        case "multi_select":
            let value = try container.decode([NotionSelectOption].self, forKey: .multiSelect)
            self = .multiSelect(value)
        case "date":
            let value = try container.decodeIfPresent(NotionDate.self, forKey: .date)
            self = .date(value)
        case "people":
            let value = try container.decode([NotionUser].self, forKey: .people)
            self = .people(value)
        case "files":
            let value = try container.decode([NotionFile].self, forKey: .files)
            self = .files(value)
        case "checkbox":
            let value = try container.decode(Bool.self, forKey: .checkbox)
            self = .checkbox(value)
        case "url":
            let value = try container.decodeIfPresent(String.self, forKey: .url)
            self = .url(value)
        case "email":
            let value = try container.decodeIfPresent(String.self, forKey: .email)
            self = .email(value)
        case "phone_number":
            let value = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
            self = .phoneNumber(value)
        case "number":
            let value = try container.decodeIfPresent(Double.self, forKey: .number)
            self = .number(value)
        case "status":
            let value = try container.decodeIfPresent(NotionStatus.self, forKey: .status)
            self = .status(value)
        case "relation":
            let value = try container.decode([NotionRelation].self, forKey: .relation)
            self = .relation(value)
        case "created_time":
            let value = try container.decode(String.self, forKey: .createdTime)
            self = .createdTime(value)
        case "created_by":
            let value = try container.decode(NotionUser.self, forKey: .createdBy)
            self = .createdBy(value)
        case "last_edited_time":
            let value = try container.decode(String.self, forKey: .lastEditedTime)
            self = .lastEditedTime(value)
        case "last_edited_by":
            let value = try container.decode(NotionUser.self, forKey: .lastEditedBy)
            self = .lastEditedBy(value)
        default:
            self = .unsupported
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .title(let value):
            try container.encode("title", forKey: .type)
            try container.encode(value, forKey: .title)
        case .richText(let value):
            try container.encode("rich_text", forKey: .type)
            try container.encode(value, forKey: .richText)
        case .select(let value):
            try container.encode("select", forKey: .type)
            try container.encodeIfPresent(value, forKey: .select)
        case .multiSelect(let value):
            try container.encode("multi_select", forKey: .type)
            try container.encode(value, forKey: .multiSelect)
        case .date(let value):
            try container.encode("date", forKey: .type)
            try container.encodeIfPresent(value, forKey: .date)
        case .relation(let value):
            try container.encode("relation", forKey: .type)
            try container.encode(value, forKey: .relation)
        case .checkbox(let value):
            try container.encode("checkbox", forKey: .type)
            try container.encode(value, forKey: .checkbox)
        case .number(let value):
            try container.encode("number", forKey: .type)
            try container.encodeIfPresent(value, forKey: .number)
        default:
            // Other types not needed for encoding in this app
            break
        }
    }
}

// MARK: - Supporting Types

/// Rich text content
struct NotionRichText: Codable, Sendable, Hashable {
    let type: String
    let text: TextContent?
    let annotations: Annotations?
    let plainText: String?
    let href: String?

    enum CodingKeys: String, CodingKey {
        case type
        case text
        case annotations
        case plainText = "plain_text"
        case href
    }

    struct TextContent: Codable, Sendable, Hashable {
        let content: String
        let link: Link?

        struct Link: Codable, Sendable, Hashable {
            let url: String
        }
    }

    struct Annotations: Codable, Sendable, Hashable {
        let bold: Bool
        let italic: Bool
        let strikethrough: Bool
        let underline: Bool
        let code: Bool
        let color: String
    }

    #if DEBUG
    static func mock(content: String = "Test") -> NotionRichText {
        NotionRichText(
            type: "text",
            text: TextContent(content: content, link: nil),
            annotations: nil,
            plainText: content,
            href: nil
        )
    }
    #endif
}

/// Select option
struct NotionSelectOption: Codable, Sendable, Equatable, Hashable {
    let id: String?
    let name: String
    let color: String?
    let description: String?

    #if DEBUG
    static func mock(name: String = "Test", color: String = "blue") -> NotionSelectOption {
        NotionSelectOption(id: "mock-id", name: name, color: color, description: nil)
    }
    #endif
}

/// Date property
struct NotionDate: Codable, Sendable {
    let start: String
    let end: String?
    let timeZone: String?

    enum CodingKeys: String, CodingKey {
        case start
        case end
        case timeZone = "time_zone"
    }

    #if DEBUG
    static func mock(start: String = "2025-10-22T12:00:00Z") -> NotionDate {
        NotionDate(start: start, end: nil, timeZone: nil)
    }
    #endif
}

/// User reference
struct NotionUser: Codable, Sendable, Hashable {
    let object: String
    let id: String
    let name: String?
    let avatarUrl: String?
    let type: String?
    let person: Person?
    let bot: Bot?

    enum CodingKeys: String, CodingKey {
        case object
        case id
        case name
        case avatarUrl = "avatar_url"
        case type
        case person
        case bot
    }

    struct Person: Codable, Sendable, Hashable {
        let email: String
    }

    struct Bot: Codable, Sendable, Hashable {
        let owner: BotOwner?
        let workspaceName: String?
        let workspaceId: String?
        let workspaceLimits: WorkspaceLimits?

        enum CodingKeys: String, CodingKey {
            case owner
            case workspaceName = "workspace_name"
            case workspaceId = "workspace_id"
            case workspaceLimits = "workspace_limits"
        }

        struct BotOwner: Codable, Sendable, Hashable {
            let type: String
            let workspace: Bool
        }

        struct WorkspaceLimits: Codable, Sendable, Hashable {
            let maxFileUploadSizeInBytes: Int?

            enum CodingKeys: String, CodingKey {
                case maxFileUploadSizeInBytes = "max_file_upload_size_in_bytes"
            }
        }
    }

    #if DEBUG
    static func mock(id: String = "mock-user-id", name: String = "Test User") -> NotionUser {
        NotionUser(object: "user", id: id, name: name, avatarUrl: nil, type: "person", person: nil, bot: nil)
    }
    #endif
}

/// File reference
struct NotionFile: Codable, Sendable {
    let name: String
    let type: String
    let file: FileDetails?
    let external: ExternalFile?

    struct FileDetails: Codable, Sendable {
        let url: String
        let expiryTime: String

        enum CodingKeys: String, CodingKey {
            case url
            case expiryTime = "expiry_time"
        }
    }

    struct ExternalFile: Codable, Sendable {
        let url: String
    }
}

/// Status property
struct NotionStatus: Codable, Sendable {
    let id: String?
    let name: String
    let color: String?
}

/// Relation reference
struct NotionRelation: Codable, Sendable {
    let id: String

    #if DEBUG
    static func mock(id: String = "mock-relation-id") -> NotionRelation {
        NotionRelation(id: id)
    }
    #endif
}

/// Rollup property (aggregated data)
struct NotionRollup: Codable, Sendable {
    let type: String
    let number: Double?
    let date: NotionDate?
    let array: [NotionProperty]?
}

/// Formula property
struct NotionFormula: Codable, Sendable {
    let type: String
    let string: String?
    let number: Double?
    let boolean: Bool?
    let date: NotionDate?
}
