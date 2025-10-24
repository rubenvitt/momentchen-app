# Core Models Quick Start Guide

Quick reference for working with Momentchen's Core Data Models.

## 📦 What's Included

- **5 Domain Entities**: Moment, MomentType, Project, LifeArea, NotionColor
- **1 SwiftData Model**: AppConfiguration
- **3 DTO Types**: NotionPageResponse, NotionDatabaseResponse, NotionPropertyTypes
- **3 Mappers**: MomentMapper, ProjectMapper, LifeAreaMapper
- **2 Utilities**: DateConverter, ColorMapper

## 🚀 Common Usage Patterns

### Working with Moments

```swift
// Create a domain moment
let moment = Moment(
    id: "page-123",
    title: "Completed code review",
    type: MomentType.aktivität,
    timestamp: Date(),
    projectId: "project-456",
    lifeAreaId: "career-789"
)

// Map from Notion API response
let apiResponse: NotionPageResponse = // ... from API
let moment = try MomentMapper.toDomain(apiResponse)

// Create Notion properties for API call
let properties = MomentMapper.toNotionProperties(
    title: "New moment",
    type: MomentType.gedanke,
    timestamp: Date(),
    projectId: "project-id",
    lifeAreaId: nil
)
```

### Working with Dates

```swift
// Convert to UTC for API
let utcString = DateConverter.formatForAPI(Date())
// → "2025-10-22T14:30:00.000Z"

// Date-only for filters
let dateFilter = DateConverter.formatDateOnly(Date())
// → "2025-10-22"

// Parse from API
let date = DateConverter.parseFromAPI("2025-10-22T14:30:00Z")

// Display in UI (local timezone)
let displayTime = DateConverter.formatForDisplay(date, style: .time)
// → "14:30"

// Check if today
if DateConverter.isToday(moment.timestamp) {
    // Show in today's list
}
```

### Working with Colors

```swift
// Get color for moment type
let typeColor = ColorMapper.colorForType(moment.type)

// Get background tint
let bgColor = ColorMapper.backgroundForType(moment.type)

// Direct NotionColor → Color
let blue = NotionColor.blue.color
let bgBlue = NotionColor.blue.backgroundTint

// All available colors
let colors = ColorMapper.allColors
```

### Working with AppConfiguration

```swift
// Load configuration
let context = modelContext // from @Environment(\.modelContext)
let descriptor = FetchDescriptor<AppConfiguration>()
let configs = try context.fetch(descriptor)
let config = configs.first

// Save configuration
let newConfig = AppConfiguration(
    notionToken: "secret_token",
    momentsDatabaseId: "db-moments",
    projectsDatabaseId: "db-projects",
    lifeAreasDatabaseId: "db-lifeareas",
    themePreference: .dark
)
context.insert(newConfig)
try context.save()

// Update theme
config?.theme = .light
config?.updatedAt = Date()
try context.save()
```

### Mapping Projects and Life Areas

```swift
// Map all projects
let projectPages: [NotionPageResponse] = // ... from API
let allProjects = ProjectMapper.toDomain(projectPages)

// Filter only active projects (status "In Bearbeitung")
let activeProjects = ProjectMapper.filterActiveProjects(projectPages)

// Map life areas
let lifeAreaPages: [NotionPageResponse] = // ... from API
let allLifeAreas = LifeAreaMapper.toDomain(lifeAreaPages)

// Filter active life areas (status "Aktiv")
let activeLifeAreas = LifeAreaMapper.filterActiveLifeAreas(lifeAreaPages)
```

## 🎨 UI Examples

### Moment Row Component

```swift
struct MomentRow: View {
    let moment: Moment

    var body: some View {
        HStack(spacing: 12) {
            // Type indicator circle
            Circle()
                .fill(ColorMapper.colorForType(moment.type))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(moment.title)
                    .font(.body)

                Text(DateConverter.formatForDisplay(moment.timestamp, style: .time))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}
```

### Type Selector

```swift
struct TypeSelectorView: View {
    @Binding var selectedType: MomentType?

    let types: [MomentType] = [
        .gedanke, .erlebnis, .aktivität,
        .idee, .emotion, .lernen
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 3)) {
            ForEach(types) { type in
                Button {
                    selectedType = type
                } label: {
                    VStack {
                        Circle()
                            .fill(ColorMapper.backgroundForType(type))
                            .overlay(
                                Circle()
                                    .strokeBorder(ColorMapper.colorForType(type), lineWidth: 2)
                            )
                            .frame(width: 50, height: 50)

                        Text(type.name)
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
```

### Theme Picker

```swift
struct ThemePickerView: View {
    @Binding var selectedTheme: ThemePreference

    var body: some View {
        Picker("Darstellung", selection: $selectedTheme) {
            ForEach(ThemePreference.allCases, id: \.self) { theme in
                Text(theme.displayName).tag(theme)
            }
        }
        .pickerStyle(.segmented)
    }
}
```

## 🔧 Error Handling

### Mapping Errors

```swift
do {
    let moment = try MomentMapper.toDomain(response)
} catch MomentMapper.MappingError.missingRequiredProperty(let field) {
    print("Missing field: \(field)")
} catch MomentMapper.MappingError.invalidDateFormat(let value) {
    print("Invalid date: \(value)")
} catch {
    print("Unexpected error: \(error)")
}

// Batch mapping (resilient - logs errors, returns valid entries)
let moments = MomentMapper.toDomain(responses)
// Invalid entries are skipped, errors logged to console
```

### Date Parsing Errors

```swift
// Safe parsing with fallback
if let date = DateConverter.parseFromAPI(apiDateString) {
    // Use date
} else {
    // Handle invalid format
    print("Invalid date format: \(apiDateString)")
}
```

## 🧪 Testing Helpers

### Mock Data

```swift
// Create test moment
let testMoment = Moment.mock(
    title: "Test Moment",
    type: .gedanke,
    timestamp: Date()
)

// Create test configuration
let testConfig = AppConfiguration.mock(
    notionToken: "test_token",
    momentsDatabaseId: "test-db-id",
    theme: .dark
)

// Create test Notion response
let testPage = MomentMapper.mockNotionPage(
    id: "page-123",
    title: "Test",
    type: "Gedanke",
    timestamp: "2025-10-22T12:00:00Z"
)

// Create test date in UTC
let testDate = DateConverter.makeUTCDate(
    year: 2025,
    month: 10,
    day: 22,
    hour: 14,
    minute: 30
)
```

### ViewModel Testing Example

```swift
class MomentListViewModelTests: XCTestCase {
    func testLoadMoments() async throws {
        // Given
        let mockResponses = [
            MomentMapper.mockNotionPage(title: "Moment 1"),
            MomentMapper.mockNotionPage(title: "Moment 2")
        ]

        // When
        let moments = MomentMapper.toDomain(mockResponses)

        // Then
        XCTAssertEqual(moments.count, 2)
        XCTAssertEqual(moments[0].title, "Moment 1")
    }
}
```

## 📋 Property Name Reference

### Moments Database (Momente)
- **Name**: title - Moment description
- **Typ**: select - Moment type
- **Zeitpunkt**: date - Timestamp (UTC)
- **Projekt**: relation - Project link
- **Lebensbereich**: relation - Life area link

### Projects Database (Projekte)
- **Projekt**: title - Project name
- **Status**: status - Filter "In Bearbeitung"

### Life Areas Database (Lebensbereiche)
- **Thema**: title - Life area name
- **Status**: status - Filter "Aktiv"

## 🎯 Common Pitfalls

### ❌ Wrong: Manual date conversion
```swift
let isoString = "2025-10-22T14:30:00Z"
let date = DateFormatter().date(from: isoString) // May fail!
```

### ✅ Right: Use DateConverter
```swift
let date = DateConverter.parseFromAPI("2025-10-22T14:30:00Z")
```

---

### ❌ Wrong: Hard-coded color mapping
```swift
let color: Color = type.color.rawValue == "blue" ? .blue : .gray
```

### ✅ Right: Use ColorMapper
```swift
let color = ColorMapper.colorForType(type)
```

---

### ❌ Wrong: Manual property building
```swift
let properties = [
    "Name": NotionProperty.title([...]) // Verbose and error-prone
]
```

### ✅ Right: Use mapper
```swift
let properties = MomentMapper.toNotionProperties(
    title: title,
    type: type,
    timestamp: timestamp
)
```

## 🔗 File Locations

```
Momentchen/
├── Domain/Entities/
│   ├── Moment.swift
│   ├── MomentType.swift
│   ├── Project.swift
│   ├── LifeArea.swift
│   └── NotionColor.swift
├── Data/
│   ├── Persistence/AppConfiguration.swift
│   ├── DTOs/
│   │   ├── NotionPageResponse.swift
│   │   ├── NotionDatabaseResponse.swift
│   │   └── NotionPropertyTypes.swift
│   └── Mappers/
│       ├── MomentMapper.swift
│       ├── ProjectMapper.swift
│       └── LifeAreaMapper.swift
└── Infrastructure/Utilities/
    ├── DateConverter.swift
    └── ColorMapper.swift
```

## 📚 See Also

- [Full Implementation Documentation](./CORE_MODELS_IMPLEMENTATION.md)
- [Architecture Documentation](./architecture.md)
- [Product Requirements](./prd.txt)
