# Notion API Service - Quick Reference

## Basic Setup

```swift
let apiService = NotionAPIService()
```

## 5 Core Operations

### 1. Validate Token
```swift
let user = try await apiService.validateToken(token: "secret_...")
```

### 2. Search Databases
```swift
let databases = try await apiService.searchDatabases(token: token)
```

### 3. Query Database
```swift
let pages = try await apiService.queryDatabase(
    token: token,
    databaseId: "db-id",
    filter: NotionFilter.todayMoments(),
    sorts: [.property("Zeitpunkt", direction: .descending)],
    pageSize: 100
)
```

### 4. Create Page
```swift
let properties = NotionProperties.momentProperties(
    description: "My moment",
    type: "Gedanke",
    timestamp: Date()
)

let page = try await apiService.createPage(
    token: token,
    databaseId: "db-id",
    properties: properties
)
```

### 5. Update Page
```swift
let updates = NotionProperties.momentUpdateProperties(
    description: "Updated text"
)

let page = try await apiService.updatePage(
    token: token,
    pageId: "page-id",
    properties: updates
)
```

## Common Filters

```swift
// Today's moments
NotionFilter.todayMoments()

// Active projects
NotionFilter.activeProjects()

// Active life areas
NotionFilter.activeLifeAreas()

// Date range
NotionFilter.momentsBetween(startDate, and: endDate)

// Compound (AND)
NotionFilter.and([
    .todayMoments(),
    .select("Typ", .equals("Gedanke"))
])

// Compound (OR)
NotionFilter.or([
    .todayMoments(),
    .date("Zeitpunkt", .equals("2025-10-21"))
])
```

## Common Sorts

```swift
// Property sort
NotionSort.property("Zeitpunkt", direction: .descending)

// Created time
NotionSort.createdTimeDescending

// Last edited time
NotionSort.lastEditedTimeDescending
```

## Property Extraction

```swift
let page: NotionPageResponse = ...

// Extract values
let title = page.extractTitle("Name")
let type = page.extractSelect("Typ")
let date = page.extractDate("Zeitpunkt")
let projectId = page.extractRelation("Projekt")
let isChecked = page.extractCheckbox("Done")
let count = page.extractNumber("Count")
```

## Error Handling

```swift
do {
    let pages = try await apiService.queryDatabase(...)
} catch let error as NotionAPIError {
    // User message (German)
    print(error.userMessage)

    // Technical details (for logs)
    print(error.technicalDetails)

    // Check if retryable
    if error.isRetryable {
        print("Retry after \(error.retryDelay)s")
    }
}
```

## Common Error Messages

| Error | German Message |
|-------|---------------|
| Invalid Token | "Ungültiger Notion Token" |
| Unauthorized | "Token ungültig oder abgelaufen" |
| Forbidden | "Keine Berechtigung für {resource}" |
| Not Found | "{resource} nicht gefunden" |
| Rate Limited | "Zu viele Anfragen. Bitte warte {n} Sekunden" |
| Server Error | "Notion Server-Fehler ({code})" |
| Network Error | "Netzwerkfehler" |

## Testing

```swift
// Mock service
let mockService = MockNotionAPIService()
mockService.queryDatabaseResult = .success([mockPage])

// Use in tests
let service = MyService(apiService: mockService)
let result = try await service.fetchData()
```

## Property Builders

```swift
NotionProperties.title("Text")
NotionProperties.richText("Text")
NotionProperties.select("Option")
NotionProperties.date(Date())
NotionProperties.date(isoString: "2025-10-22T12:00:00Z")
NotionProperties.dateRange(start: date1, end: date2)
NotionProperties.relation("page-id")
NotionProperties.relation(["id1", "id2"])
NotionProperties.checkbox(true)
NotionProperties.number(42.5)
NotionProperties.url("https://...")
NotionProperties.email("test@example.com")
NotionProperties.phoneNumber("+49...")
NotionProperties.multiSelect(["opt1", "opt2"])
NotionProperties.status("Active")
```

## Moment-Specific Helpers

```swift
// Create moment properties
let props = NotionProperties.momentProperties(
    description: "Text",
    type: "Gedanke",
    timestamp: Date(),
    projectId: "proj-id",    // optional
    lifeAreaId: "area-id"    // optional
)

// Update moment properties (only changed fields)
let updates = NotionProperties.momentUpdateProperties(
    description: "New text",
    type: nil,              // Don't update
    timestamp: Date()
)
```

## Performance Tips

1. **Use filters** to reduce result set size
2. **Limit page size** if you only need first N results
3. **Batch operations** when possible
4. **Cache database schemas** to avoid repeated fetches
5. **Let pagination happen** automatically (don't manually handle cursors)

## Best Practices

1. Always use the protocol for dependency injection:
   ```swift
   private let apiService: NotionAPIServiceProtocol
   ```

2. Handle errors with user-friendly messages:
   ```swift
   catch let error as NotionAPIError {
       showAlert(error.userMessage)
   }
   ```

3. Use helper methods:
   ```swift
   let filter = NotionFilter.todayMoments()  // ✅
   // Instead of manual filter construction ❌
   ```

4. Extract properties safely:
   ```swift
   guard let title = page.extractTitle("Name") else {
       return nil
   }
   ```

5. Test with mocks:
   ```swift
   let mockService = MockNotionAPIService()
   mockService.queryDatabaseResult = .success([...])
   ```

## Common Patterns

### Fetch Today's Moments
```swift
let filter = NotionFilter.todayMoments()
let sorts = [NotionSort.property("Zeitpunkt", direction: .descending)]
let pages = try await apiService.queryDatabase(
    token: token,
    databaseId: dbId,
    filter: filter,
    sorts: sorts,
    pageSize: 100
)
```

### Create a Moment
```swift
let properties = NotionProperties.momentProperties(
    description: description,
    type: type,
    timestamp: timestamp,
    projectId: projectId,
    lifeAreaId: lifeAreaId
)
let page = try await apiService.createPage(
    token: token,
    databaseId: dbId,
    properties: properties
)
```

### Update a Moment
```swift
let updates = NotionProperties.momentUpdateProperties(
    description: newDescription,
    timestamp: newTimestamp
)
let page = try await apiService.updatePage(
    token: token,
    pageId: pageId,
    properties: updates
)
```

### Get Select Options
```swift
let options = try await apiService.getSelectOptions(
    token: token,
    databaseId: dbId,
    propertyName: "Typ"
)
```

## URL Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/users/me` | Validate token |
| POST | `/search` | Search databases |
| POST | `/databases/{id}/query` | Query database |
| POST | `/pages` | Create page |
| PATCH | `/pages/{id}` | Update page |

## Headers

```
Authorization: Bearer {token}
Notion-Version: 2022-06-28
Content-Type: application/json
Accept: application/json
```

## Rate Limits

- **3 requests/second** (average)
- **429 errors** trigger automatic retry
- **Exponential backoff**: 0.5s → 1s → 2s → fail

## Thread Safety

- `NotionAPIService` is an `actor`
- All methods are thread-safe
- Safe to call from multiple tasks

```swift
Task { try await apiService.queryDatabase(...) }
Task { try await apiService.queryDatabase(...) }
// Both are safe to run concurrently
```

## Logging

```swift
import OSLog

let logger = Logger(subsystem: "com.momentchen.app", category: "NotionAPI")

// Automatic logging includes:
// - Request/response details
// - Error details
// - Retry attempts
// - Pagination progress
```

View logs in Console.app or filter by "NotionAPI" category.

---

For complete documentation, see [README.md](README.md)
