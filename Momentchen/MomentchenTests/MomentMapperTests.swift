//
//  MomentMapperTests.swift
//  MomentchenTests
//
//  Created by Test Architect on 22.10.2025.
//

import XCTest
@testable import Momentchen

final class MomentMapperTests: XCTestCase {

    // MARK: - toDomain Tests (Single Object)

    func testToDomain_WithValidNotionResponse_SuccessfullyMaps() throws {
        // Given: Valid Notion response with all required fields
        let notionResponse = createValidNotionResponse()

        // When
        let moment = try MomentMapper.toDomain(notionResponse)

        // Then
        XCTAssertEqual(moment.id, "test-page-id")
        XCTAssertEqual(moment.title, "Test Moment")
        XCTAssertEqual(moment.type.name, "Gedanke")
        XCTAssertNotNil(moment.timestamp)
    }

    func testToDomain_WithTimezoneOffsetFormat_ParsesCorrectly() throws {
        // Given: Notion response with timezone offset format (the bug we fixed!)
        let dateString = "2025-10-22T14:59:00.000+00:00"
        let notionResponse = createNotionResponse(timestamp: dateString)

        // When
        let moment = try MomentMapper.toDomain(notionResponse)

        // Then
        XCTAssertNotNil(moment.timestamp, "Should parse timezone offset format")

        // Verify parsed date
        let calendar = Calendar(identifier: .gregorian)
        var utcCalendar = calendar
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!

        let components = utcCalendar.dateComponents([.year, .month, .day, .hour, .minute],
                                                    from: moment.timestamp)
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 10)
        XCTAssertEqual(components.day, 22)
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 59)
    }

    func testToDomain_WithZTimezoneFormat_ParsesCorrectly() throws {
        // Given: Notion response with Z timezone format
        let dateString = "2025-10-22T14:59:00.000Z"
        let notionResponse = createNotionResponse(timestamp: dateString)

        // When
        let moment = try MomentMapper.toDomain(notionResponse)

        // Then
        XCTAssertNotNil(moment.timestamp, "Should parse Z timezone format")
    }

    func testToDomain_WithoutFractionalSeconds_ParsesCorrectly() throws {
        // Given: Notion response without milliseconds
        let dateString = "2025-10-22T14:59:00Z"
        let notionResponse = createNotionResponse(timestamp: dateString)

        // When
        let moment = try MomentMapper.toDomain(notionResponse)

        // Then
        XCTAssertNotNil(moment.timestamp, "Should parse format without fractional seconds")
    }

    func testToDomain_WithMissingTitle_ThrowsError() {
        // Given: Notion response without title
        let notionResponse = createNotionResponseWithMissingField(.title)

        // When/Then
        XCTAssertThrowsError(try MomentMapper.toDomain(notionResponse)) { error in
            guard let mappingError = error as? MomentMapper.MappingError else {
                XCTFail("Expected MappingError")
                return
            }

            if case .missingRequiredProperty(let field) = mappingError {
                XCTAssertEqual(field, "Name")
            } else {
                XCTFail("Expected missingRequiredProperty error")
            }
        }
    }

    func testToDomain_WithMissingType_ThrowsError() {
        // Given: Notion response without type
        let notionResponse = createNotionResponseWithMissingField(.type)

        // When/Then
        XCTAssertThrowsError(try MomentMapper.toDomain(notionResponse)) { error in
            guard let mappingError = error as? MomentMapper.MappingError else {
                XCTFail("Expected MappingError")
                return
            }

            if case .missingRequiredProperty(let field) = mappingError {
                XCTAssertEqual(field, "Typ")
            } else {
                XCTFail("Expected missingRequiredProperty error")
            }
        }
    }

    func testToDomain_WithMissingTimestamp_ThrowsError() {
        // Given: Notion response without timestamp
        let notionResponse = createNotionResponseWithMissingField(.timestamp)

        // When/Then
        XCTAssertThrowsError(try MomentMapper.toDomain(notionResponse)) { error in
            guard let mappingError = error as? MomentMapper.MappingError else {
                XCTFail("Expected MappingError")
                return
            }

            if case .missingRequiredProperty(let field) = mappingError {
                XCTAssertEqual(field, "Zeitpunkt")
            } else {
                XCTFail("Expected missingRequiredProperty error")
            }
        }
    }

    func testToDomain_WithInvalidDateFormat_ThrowsError() {
        // Given: Notion response with invalid date format
        let notionResponse = createNotionResponse(timestamp: "not-a-valid-date")

        // When/Then
        XCTAssertThrowsError(try MomentMapper.toDomain(notionResponse)) { error in
            guard let mappingError = error as? MomentMapper.MappingError else {
                XCTFail("Expected MappingError")
                return
            }

            if case .invalidDateFormat(let value) = mappingError {
                XCTAssertEqual(value, "not-a-valid-date")
            } else {
                XCTFail("Expected invalidDateFormat error")
            }
        }
    }

    func testToDomain_WithOptionalProjectRelation_MapsCorrectly() throws {
        // Given: Notion response with project relation
        let project = Project(id: "project-123", title: "Test Project")
        let notionResponse = createNotionResponse(projectId: "project-123")

        // When
        let moment = try MomentMapper.toDomain(notionResponse, projects: [project], lifeAreas: [])

        // Then
        if case .project(let mappedProject) = moment.category {
            XCTAssertEqual(mappedProject.id, "project-123")
            XCTAssertEqual(mappedProject.title, "Test Project")
        } else {
            XCTFail("Expected project category")
        }
    }

    func testToDomain_WithOptionalLifeAreaRelation_MapsCorrectly() throws {
        // Given: Notion response with life area relation
        let lifeArea = LifeArea(id: "life-area-456", title: "Test Life Area")
        let notionResponse = createNotionResponse(lifeAreaId: "life-area-456")

        // When
        let moment = try MomentMapper.toDomain(notionResponse, projects: [], lifeAreas: [lifeArea])

        // Then
        if case .lifeArea(let mappedLifeArea) = moment.category {
            XCTAssertEqual(mappedLifeArea.id, "life-area-456")
            XCTAssertEqual(mappedLifeArea.title, "Test Life Area")
        } else {
            XCTFail("Expected life area category")
        }
    }

    func testToDomain_WithoutOptionalRelations_MapsCorrectly() throws {
        // Given: Notion response without optional relations
        let notionResponse = createValidNotionResponse()

        // When
        let moment = try MomentMapper.toDomain(notionResponse)

        // Then
        XCTAssertTrue(moment.category.isNone, "Expected .none category")
    }

    func testToDomain_WithBothRelations_PrefersProject() throws {
        // Given: Notion response with both project and life area (edge case)
        let project = Project(id: "project-123", title: "Test Project")
        let lifeArea = LifeArea(id: "life-area-456", title: "Test Life Area")
        let notionResponse = createNotionResponse(projectId: "project-123", lifeAreaId: "life-area-456")

        // When
        let moment = try MomentMapper.toDomain(notionResponse, projects: [project], lifeAreas: [lifeArea])

        // Then: Should prefer project over life area
        if case .project(let mappedProject) = moment.category {
            XCTAssertEqual(mappedProject.id, "project-123")
        } else {
            XCTFail("Expected project category (should have priority)")
        }
    }

    func testToDomain_WithUnknownProjectId_FallsBackToNone() throws {
        // Given: Notion response with project ID that doesn't exist in projects array
        let notionResponse = createNotionResponse(projectId: "unknown-project")

        // When
        let moment = try MomentMapper.toDomain(notionResponse, projects: [], lifeAreas: [])

        // Then
        XCTAssertTrue(moment.category.isNone, "Expected .none when project not found")
    }

    // MARK: - toDomain Tests (Array)

    func testToDomainArray_WithMultipleValidResponses_MapsAll() {
        // Given: Array of valid responses
        let responses = [
            createNotionResponse(id: "id-1", title: "Moment 1"),
            createNotionResponse(id: "id-2", title: "Moment 2"),
            createNotionResponse(id: "id-3", title: "Moment 3")
        ]

        // When
        let moments = MomentMapper.toDomain(responses)

        // Then
        XCTAssertEqual(moments.count, 3)
        XCTAssertEqual(moments[0].id, "id-1")
        XCTAssertEqual(moments[1].id, "id-2")
        XCTAssertEqual(moments[2].id, "id-3")
    }

    func testToDomainArray_WithSomeInvalidResponses_SkipsInvalid() {
        // Given: Array with mix of valid and invalid responses
        let responses = [
            createNotionResponse(id: "id-1", title: "Moment 1"),
            createNotionResponseWithMissingField(.title),  // Invalid
            createNotionResponse(id: "id-3", title: "Moment 3")
        ]

        // When
        let moments = MomentMapper.toDomain(responses)

        // Then
        XCTAssertEqual(moments.count, 2, "Should skip invalid entries")
        XCTAssertEqual(moments[0].id, "id-1")
        XCTAssertEqual(moments[1].id, "id-3")
    }

    func testToDomainArray_WithEmptyArray_ReturnsEmpty() {
        // Given: Empty array
        let responses: [NotionPageResponse] = []

        // When
        let moments = MomentMapper.toDomain(responses)

        // Then
        XCTAssertTrue(moments.isEmpty)
    }

    // MARK: - toNotionProperties Tests

    func testToNotionProperties_CreatesValidProperties() {
        // Given
        let title = "Test Moment"
        let type = MomentType(name: "Gedanke", color: .blue)
        let timestamp = Date()

        // When
        let properties = MomentMapper.toNotionProperties(
            title: title,
            type: type,
            timestamp: timestamp,
            category: .none
        )

        // Then
        XCTAssertNotNil(properties["Name"])
        XCTAssertNotNil(properties["Typ"])
        XCTAssertNotNil(properties["Zeitpunkt"])

        // Verify title
        if case .title(let richTexts) = properties["Name"] {
            XCTAssertEqual(richTexts.first?.plainText, title)
        } else {
            XCTFail("Expected title property")
        }

        // Verify type
        if case .select(let select) = properties["Typ"] {
            XCTAssertEqual(select?.name, type.name)
        } else {
            XCTFail("Expected select property")
        }

        // Verify date
        if case .date(let notionDate) = properties["Zeitpunkt"] {
            XCTAssertNotNil(notionDate?.start)
        } else {
            XCTFail("Expected date property")
        }
    }

    func testToNotionProperties_WithProjectCategory_IncludesProjectRelation() {
        // Given
        let title = "Test"
        let type = MomentType(name: "Gedanke", color: .blue)
        let timestamp = Date()
        let project = Project(id: "project-123", title: "Test Project")
        let category = MomentCategory.project(project)

        // When
        let properties = MomentMapper.toNotionProperties(
            title: title,
            type: type,
            timestamp: timestamp,
            category: category
        )

        // Then
        XCTAssertNotNil(properties["Projekt"])
        XCTAssertNil(properties["Lebensbereich"], "Should not include life area when category is project")

        if case .relation(let relations) = properties["Projekt"] {
            XCTAssertEqual(relations.first?.id, "project-123")
        } else {
            XCTFail("Expected project relation")
        }
    }

    func testToNotionProperties_WithLifeAreaCategory_IncludesLifeAreaRelation() {
        // Given
        let title = "Test"
        let type = MomentType(name: "Gedanke", color: .blue)
        let timestamp = Date()
        let lifeArea = LifeArea(id: "life-area-456", title: "Test Life Area")
        let category = MomentCategory.lifeArea(lifeArea)

        // When
        let properties = MomentMapper.toNotionProperties(
            title: title,
            type: type,
            timestamp: timestamp,
            category: category
        )

        // Then
        XCTAssertNotNil(properties["Lebensbereich"])
        XCTAssertNil(properties["Projekt"], "Should not include project when category is life area")

        if case .relation(let relations) = properties["Lebensbereich"] {
            XCTAssertEqual(relations.first?.id, "life-area-456")
        } else {
            XCTFail("Expected life area relation")
        }
    }

    func testToNotionProperties_WithNoneCategory_ExcludesRelations() {
        // Given
        let title = "Test"
        let type = MomentType(name: "Gedanke", color: .blue)
        let timestamp = Date()

        // When
        let properties = MomentMapper.toNotionProperties(
            title: title,
            type: type,
            timestamp: timestamp,
            category: .none
        )

        // Then
        XCTAssertNil(properties["Projekt"], "Should not include project when category is none")
        XCTAssertNil(properties["Lebensbereich"], "Should not include life area when category is none")
    }

    // MARK: - Helper Methods

    private func createValidNotionResponse() -> NotionPageResponse {
        return createNotionResponse()
    }

    private func createNotionResponse(
        id: String = "test-page-id",
        title: String = "Test Moment",
        type: String = "Gedanke",
        timestamp: String = "2025-10-22T12:00:00.000Z",
        projectId: String? = nil,
        lifeAreaId: String? = nil
    ) -> NotionPageResponse {
        var properties: [String: NotionProperty] = [
            "Name": .title([
                NotionRichText(
                    type: "text",
                    text: NotionRichText.TextContent(content: title, link: nil),
                    annotations: nil,
                    plainText: title,
                    href: nil
                )
            ]),
            "Typ": .select(NotionSelectOption(
                id: nil,
                name: type,
                color: "blue",
                description: nil
            )),
            "Zeitpunkt": .date(NotionDate(
                start: timestamp,
                end: nil,
                timeZone: nil
            ))
        ]

        // Add optional relations
        if let projectId = projectId {
            properties["Projekt"] = .relation([NotionRelation(id: projectId)])
        }

        if let lifeAreaId = lifeAreaId {
            properties["Lebensbereich"] = .relation([NotionRelation(id: lifeAreaId)])
        }

        return NotionPageResponse(
            object: "page",
            id: id,
            createdTime: "2025-10-22T12:00:00.000Z",
            lastEditedTime: "2025-10-22T12:00:00.000Z",
            archived: false,
            properties: properties,
            url: "https://notion.so/\(id)"
        )
    }

    private enum MissingField {
        case title
        case type
        case timestamp
    }

    private func createNotionResponseWithMissingField(_ missingField: MissingField) -> NotionPageResponse {
        var properties: [String: NotionProperty] = [:]

        // Add all fields except the missing one
        if missingField != .title {
            properties["Name"] = .title([
                NotionRichText(
                    type: "text",
                    text: NotionRichText.TextContent(content: "Test", link: nil),
                    annotations: nil,
                    plainText: "Test",
                    href: nil
                )
            ])
        }

        if missingField != .type {
            properties["Typ"] = .select(NotionSelectOption(
                id: nil,
                name: "Gedanke",
                color: "blue",
                description: nil
            ))
        }

        if missingField != .timestamp {
            properties["Zeitpunkt"] = .date(NotionDate(
                start: "2025-10-22T12:00:00.000Z",
                end: nil,
                timeZone: nil
            ))
        }

        return NotionPageResponse(
            object: "page",
            id: "test-id",
            createdTime: "2025-10-22T12:00:00.000Z",
            lastEditedTime: "2025-10-22T12:00:00.000Z",
            archived: false,
            properties: properties,
            url: "https://notion.so/test"
        )
    }
}
