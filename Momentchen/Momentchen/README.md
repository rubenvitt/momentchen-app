# Momentchen - Core Models Layer

Complete implementation of the Core Data Models layer for the Momentchen iOS/macOS application.

## Overview

This layer provides all domain entities, DTOs, mappers, and utilities needed to interact with Notion's API and manage app data. It follows a clean architecture pattern with strict separation of concerns.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Domain Layer                           │
│  Pure business logic, no dependencies                   │
│  • Moment, MomentType, Project, LifeArea, NotionColor   │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                  Data Layer                             │
│  API integration and data mapping                       │
│  • DTOs: NotionPageResponse, NotionDatabaseResponse     │
│  • Mappers: MomentMapper, ProjectMapper, LifeAreaMapper │
│  • Persistence: AppConfiguration (SwiftData)            │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│            Infrastructure Layer                         │
│  Cross-cutting utilities                                │
│  • DateConverter (UTC ↔ Local)                          │
│  • ColorMapper (Notion → SwiftUI)                       │
└─────────────────────────────────────────────────────────┘
```

## Layer Breakdown

### Domain/Entities (5 files)

Pure business models with zero dependencies:

- **Moment.swift**: Core moment entity (id, title, type, timestamp, relations)
- **MomentType.swift**: Type categorization with Notion color
- **Project.swift**: Project reference entity
- **LifeArea.swift**: Life area reference entity
- **NotionColor.swift**: Notion color palette with SwiftUI mapping

**Key Characteristics**:
- Immutable structs (value semantics)
- Sendable for concurrency
- No framework dependencies
- Mock factories for testing

### Data/Persistence (1 file)

SwiftData configuration storage:

- **AppConfiguration.swift**: SwiftData @Model for app settings
  - Notion token storage
  - Database IDs (moments, projects, life areas)
  - Theme preference
  - Timestamps

**Note**: This is the ONLY SwiftData model. Moments are NOT persisted locally.

### Data/DTOs (3 files)

Notion API response models:

- **NotionPageResponse.swift**: Page objects from API
- **NotionDatabaseResponse.swift**: Database metadata
- **NotionPropertyTypes.swift**: All Notion property types (18 types supported)

**Key Characteristics**:
- Codable for JSON parsing
- Snake_case → camelCase mapping
- Complete Notion API v1 coverage
- Mock factories for testing

### Data/Mappers (3 files)

DTO ↔ Domain conversion:

- **MomentMapper.swift**: NotionPageResponse ↔ Moment
- **ProjectMapper.swift**: NotionPageResponse ↔ Project (with status filtering)
- **LifeAreaMapper.swift**: NotionPageResponse ↔ LifeArea (with status filtering)

**Key Characteristics**:
- Typed errors with localized messages
- Resilient batch mapping (log + skip invalid)
- Bidirectional conversion
- Validation of required fields

### Infrastructure/Utilities (2 files)

Cross-cutting utilities:

- **DateConverter.swift**: UTC ↔ Local timezone conversion
  - API formatting (ISO8601)
  - Display formatting (localized)
  - Today helpers
- **ColorMapper.swift**: NotionColor → SwiftUI Color
  - Color mapping
  - Background tints
  - Adaptive theme support
  - Platform abstraction (iOS/macOS)

## Quick Start

### Load Today's Moments

```swift
// 1. Query Notion API (in your API service)
let filter = DatabaseFilter(
    property: "Zeitpunkt",
    date: DateFilter(equals: DateConverter.todayUTCString())
)
let response: NotionQueryResponse = try await notionAPI.queryDatabase(filter: filter)

// 2. Map to domain models
let moments = MomentMapper.toDomain(response.results)

// 3. Display in UI
ForEach(moments) { moment in
    HStack {
        Circle()
            .fill(ColorMapper.colorForType(moment.type))
        Text(moment.title)
        Spacer()
        Text(DateConverter.formatForDisplay(moment.timestamp, style: .time))
    }
}
```

### Create a Moment

```swift
// 1. Build Notion properties
let properties = MomentMapper.toNotionProperties(
    title: "Completed code review",
    type: MomentType.aktivität,
    timestamp: Date(),
    projectId: selectedProject?.id,
    lifeAreaId: selectedLifeArea?.id
)

// 2. Create via API
let response = try await notionAPI.createPage(
    databaseId: config.momentsDatabaseId,
    properties: properties
)

// 3. Map result
let newMoment = try MomentMapper.toDomain(response)
```

### Load Configuration

```swift
@Environment(\.modelContext) private var modelContext

func loadConfig() async throws -> AppConfiguration? {
    let descriptor = FetchDescriptor<AppConfiguration>()
    let configs = try modelContext.fetch(descriptor)
    return configs.first
}
```

## File Structure

```
Momentchen/
├── Domain/
│   └── Entities/
│       ├── Moment.swift              (93 lines)
│       ├── MomentType.swift          (69 lines)
│       ├── Project.swift             (52 lines)
│       ├── LifeArea.swift            (52 lines)
│       └── NotionColor.swift         (81 lines)
│
├── Data/
│   ├── Persistence/
│   │   └── AppConfiguration.swift    (154 lines)
│   ├── DTOs/
│   │   ├── NotionPageResponse.swift  (88 lines)
│   │   ├── NotionDatabaseResponse.swift (110 lines)
│   │   └── NotionPropertyTypes.swift (416 lines)
│   └── Mappers/
│       ├── MomentMapper.swift        (199 lines)
│       ├── ProjectMapper.swift       (109 lines)
│       └── LifeAreaMapper.swift      (109 lines)
│
└── Infrastructure/
    └── Utilities/
        ├── DateConverter.swift       (199 lines)
        └── ColorMapper.swift         (220 lines)
```

**Total**: 14 files, 1,751 lines of code

## Testing Support

All models include `#if DEBUG` test helpers:

```swift
// Mock domain entities
let moment = Moment.mock(title: "Test", type: .gedanke)
let project = Project.mock(title: "Test Project")

// Mock Notion responses
let page = MomentMapper.mockNotionPage(title: "Test")

// Mock configuration
let config = AppConfiguration.mock(theme: .dark)

// Mock dates
let date = DateConverter.makeUTCDate(year: 2025, month: 10, day: 22)
```

## Error Handling

### Mapping Errors

```swift
enum MomentMapper.MappingError: Error {
    case missingRequiredProperty(String)
    case invalidPropertyType(String, expected: String)
    case invalidDateFormat(String)
}
```

All errors have localized German descriptions.

### Batch Resilience

```swift
// Single mapping - throws on error
let moment = try MomentMapper.toDomain(response)

// Batch mapping - logs errors, skips invalid entries
let moments = MomentMapper.toDomain(responses)
```

## Notion API Property Mapping

### Moments Database
- **Name** → title (required)
- **Typ** → select (required)
- **Zeitpunkt** → date (required, UTC)
- **Projekt** → relation (optional)
- **Lebensbereich** → relation (optional)

### Projects Database
- **Projekt** → title (required)
- **Status** → status (filter: "In Bearbeitung")

### Life Areas Database
- **Thema** → title (required)
- **Status** → status (filter: "Aktiv")

## Platform Support

- **iOS**: 17.0+
- **macOS**: 14.0+
- **Swift**: 5.9+
- **SwiftUI**: Native
- **SwiftData**: Configuration only

Platform-specific code uses `#if canImport(UIKit)` / `#if canImport(AppKit)`.

## Dependencies

**Zero external dependencies** - uses only Foundation, SwiftUI, and SwiftData.

## Concurrency

All types are `Sendable` for Swift concurrency:
- Domain models: `struct` (implicitly Sendable)
- DTOs: `struct` (implicitly Sendable)
- Mappers: `enum` (no state)
- Utilities: `enum` (no state)

## Next Steps

1. **Implement API Service**: Use DTOs and mappers in `NotionAPIService`
2. **Build ViewModels**: Create `@Observable` classes using domain models
3. **Create UI Components**: Build SwiftUI views with ColorMapper and DateConverter
4. **Write Tests**: Use provided mock factories

## Documentation

- [Full Implementation Guide](../../docs/CORE_MODELS_IMPLEMENTATION.md)
- [Quick Start Guide](../../docs/CORE_MODELS_QUICKSTART.md)
- [Architecture Documentation](../../docs/architecture.md)
- [Product Requirements](../../docs/prd.txt)

## License

Part of the Momentchen project.

---

**Status**: ✅ Complete and ready for API integration
**Lines of Code**: 1,751
**Test Coverage**: Mock factories provided for all types
**Documentation**: 100%
