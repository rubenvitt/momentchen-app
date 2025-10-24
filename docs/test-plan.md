# Test Plan: Momentchen Swift

**Version:** 1.0
**Date:** October 22, 2025
**Test Architect:** TEA Agent
**Platform:** iOS 17.0+, macOS 14.0+

---

## Table of Contents

1. [Test Scope](#test-scope)
2. [Test Strategy](#test-strategy)
3. [Functional Test Cases](#functional-test-cases)
4. [API Integration Tests](#api-integration-tests)
5. [UI Test Scenarios](#ui-test-scenarios)
6. [Data Mapping Tests](#data-mapping-tests)
7. [Error Handling Tests](#error-handling-tests)
8. [Performance Tests](#performance-tests)
9. [Test Environment Setup](#test-environment-setup)
10. [Risk Assessment](#risk-assessment)

---

## Test Scope

### In Scope
- All 7 User Stories from PRD (US-1 through US-7)
- 5 Notion API endpoints (users.me, search, query, create, update)
- DTO → Domain → UI data mapping
- Error handling paths (401, 404, 429, network errors)
- UTC ↔ Local timezone conversion
- SwiftData configuration persistence
- German UI language compliance
- Auto-refresh mechanism (15-second interval)
- Theme management (Light/Dark/System)

### Out of Scope (V1)
- Offline mode functionality
- Push notifications
- Export functionality (PDF/CSV)
- Analytics and statistics
- Multi-language support (only German for V1)
- Page deletion (Notion API limitation)
- macOS-specific UI optimizations

---

## Test Strategy

### Test Pyramid

```
       ┌─────────────────┐
       │   UI Tests      │  10% - Critical user flows
       │   (XCTest)      │
       ├─────────────────┤
       │ Integration     │  30% - API ↔ Service ↔ ViewModel
       │   Tests         │
       ├─────────────────┤
       │   Unit Tests    │  60% - Services, Mappers, Utilities
       └─────────────────┘
```

### Test Priorities

| Priority | Description | Coverage |
|----------|-------------|----------|
| **P0 - Critical** | Setup flow, moment creation, API integration | Must pass for release |
| **P1 - High** | Editing, filtering, auto-refresh, error handling | Should pass for release |
| **P2 - Medium** | Theme switching, validation, edge cases | Nice to have |
| **P3 - Low** | Performance benchmarks, accessibility | Future improvements |

### Test Execution Strategy

1. **Unit Tests** - Run on every commit (CI/CD)
2. **Integration Tests** - Run daily with real Notion test workspace
3. **UI Tests** - Run before major releases
4. **Performance Tests** - Run weekly on physical devices

---

## Functional Test Cases

### US-1: Notion Token Authentication

#### TC-US1-001: Valid Token Validation
- **Priority:** P0 - Critical
- **Preconditions:**
  - App installed
  - Valid Notion integration token available
- **Steps:**
  1. Launch app (first time)
  2. Enter valid Notion token in SecureField
  3. Tap "Validieren" button
- **Expected Result:**
  - Loading indicator appears
  - API calls `POST /v1/users/me`
  - Success: Token marked valid, navigation to database selection
  - Token saved to SwiftData
- **Status:** ⏳ Pending
- **Validation:** Check `SetupViewModel.isTokenValid == true` and SwiftData contains token

---

#### TC-US1-002: Invalid Token Error Handling
- **Priority:** P0 - Critical
- **Preconditions:** App in setup flow
- **Steps:**
  1. Enter invalid/expired token
  2. Tap "Validieren"
- **Expected Result:**
  - API returns 401 Unauthorized
  - Error alert shows: "Token ungültig oder abgelaufen. Bitte melde dich neu an."
  - User remains on token input screen
  - Token not saved
- **Status:** ⏳ Pending
- **Validation:** `errorMessage` contains correct German text

---

#### TC-US1-003: Empty Token Validation
- **Priority:** P1 - High
- **Preconditions:** Setup screen displayed
- **Steps:**
  1. Leave token field empty
  2. Attempt to tap "Validieren"
- **Expected Result:**
  - Button disabled (gray, non-interactive)
  - No API call made
- **Status:** ⏳ Pending

---

#### TC-US1-004: Token Copy-Paste Support
- **Priority:** P2 - Medium
- **Preconditions:** Token in clipboard
- **Steps:**
  1. Long-press or right-click token field
  2. Select "Paste"
- **Expected Result:**
  - Token pasted successfully
  - SecureField masks the token
- **Status:** ⏳ Pending

---

### US-2: Database Selection

#### TC-US2-001: Load Available Databases
- **Priority:** P0 - Critical
- **Preconditions:**
  - Token validated
  - Database selection screen shown
- **Steps:**
  1. Observe database loading
- **Expected Result:**
  - API calls `POST /v1/search` with filter `{"property": "object", "value": "database"}`
  - All accessible databases loaded
  - Databases sorted alphabetically
  - Three pickers shown: Momente, Projekte, Lebensbereiche
- **Status:** ⏳ Pending
- **Validation:** Check `availableDatabases` array populated and sorted

---

#### TC-US2-002: Select All Three Databases
- **Priority:** P0 - Critical
- **Preconditions:** Databases loaded
- **Steps:**
  1. Select database from "Momente Datenbank" picker
  2. Select database from "Projekte Datenbank" picker
  3. Select database from "Lebensbereiche Datenbank" picker
  4. Tap "Speichern"
- **Expected Result:**
  - "Speichern" button enabled after all 3 selections
  - Configuration saved to SwiftData
  - Success alert shown: "Setup abgeschlossen!"
  - Auto-navigation to main view after 2 seconds
- **Status:** ⏳ Pending
- **Validation:** SwiftData contains all 3 database IDs

---

#### TC-US2-003: Incomplete Database Selection
- **Priority:** P1 - High
- **Preconditions:** Database selection screen
- **Steps:**
  1. Select only 1 or 2 databases
  2. Observe "Speichern" button
- **Expected Result:**
  - Button remains disabled (gray)
  - No save operation possible
- **Status:** ⏳ Pending

---

#### TC-US2-004: Database Search Error Handling
- **Priority:** P1 - High
- **Preconditions:** Token valid but network unstable
- **Steps:**
  1. Navigate to database selection
  2. Simulate network error
- **Expected Result:**
  - Error message displayed
  - Retry mechanism attempts up to 3 times
  - User can manually retry
- **Status:** ⏳ Pending

---

### US-3: Create New Moment

#### TC-US3-001: Create Moment with All Fields
- **Priority:** P0 - Critical
- **Preconditions:**
  - Setup complete
  - Main view displayed
- **Steps:**
  1. Tap "+" button
  2. Enter description: "Spaziergang im Park"
  3. Select type: "Aktivität"
  4. Keep timestamp as current time
  5. Select project: "Sport & Gesundheit"
  6. Select life area: "Körper & Gesundheit"
  7. Tap "Speichern"
- **Expected Result:**
  - API calls `POST /v1/pages` with correct properties
  - Timestamp converted to UTC in API call
  - Success: Sheet dismisses
  - Toast/Alert: "Moment gespeichert"
  - New moment appears in list
- **Status:** ⏳ Pending
- **Validation:** Check API request body matches expected NotionProperty structure

---

#### TC-US3-002: Create Moment with Minimum Fields
- **Priority:** P0 - Critical
- **Preconditions:** Moment form open
- **Steps:**
  1. Enter description: "Test"
  2. Select type: "Gedanke"
  3. Leave project/life area empty
  4. Tap "Speichern"
- **Expected Result:**
  - Save succeeds
  - Optional relations not included in API call
  - Moment created successfully
- **Status:** ⏳ Pending

---

#### TC-US3-003: Validation - Empty Description
- **Priority:** P1 - High
- **Preconditions:** Form open
- **Steps:**
  1. Leave description empty
  2. Select type
  3. Tap "Speichern"
- **Expected Result:**
  - Error alert: "Bitte gib eine Beschreibung ein"
  - Form not submitted
  - User remains on form
- **Status:** ⏳ Pending

---

#### TC-US3-004: Validation - No Type Selected
- **Priority:** P1 - High
- **Preconditions:** Form open
- **Steps:**
  1. Enter description
  2. Do not select type
  3. Tap "Speichern"
- **Expected Result:**
  - Error alert: "Bitte wähle einen Typ aus"
  - No API call made
- **Status:** ⏳ Pending

---

#### TC-US3-005: Timestamp Picker Default Value
- **Priority:** P2 - Medium
- **Preconditions:** Form open
- **Steps:**
  1. Observe timestamp field
- **Expected Result:**
  - Default value is current local time
  - Picker displays local timezone
  - "Jetzt" button sets to current time
- **Status:** ⏳ Pending

---

#### TC-US3-006: Cancel Without Changes
- **Priority:** P2 - Medium
- **Preconditions:** Form open, no input entered
- **Steps:**
  1. Tap "Abbrechen"
- **Expected Result:**
  - Sheet dismisses immediately
  - No confirmation dialog
- **Status:** ⏳ Pending

---

#### TC-US3-007: Cancel With Unsaved Changes
- **Priority:** P2 - Medium
- **Preconditions:** Form with partial input
- **Steps:**
  1. Enter description
  2. Tap "Abbrechen"
- **Expected Result:**
  - ⚠️ **GAP:** PRD AC3.11 requires confirmation dialog
  - **Current Implementation:** No dirty-state detection implemented
  - **Recommendation:** Add `@State var hasChanges` and show confirmation alert
- **Status:** ⚠️ Missing Feature

---

### US-4: Display Today's Moments

#### TC-US4-001: Load Today's Moments
- **Priority:** P0 - Critical
- **Preconditions:**
  - Setup complete
  - Test moments created for today
- **Steps:**
  1. Launch app
  2. Navigate to moment list
- **Expected Result:**
  - Loading indicator appears
  - API calls `POST /v1/databases/{id}/query` with:
    - Filter: `{"property": "Zeitpunkt", "date": {"equals": "2025-10-22"}}`
    - Sort: `[{"property": "Zeitpunkt", "direction": "descending"}]`
  - Moments displayed in reverse chronological order
  - Timestamps shown in local timezone
- **Status:** ⏳ Pending
- **Validation:** UTC date filter matches today in UTC, display shows local time

---

#### TC-US4-002: Moment Row Display Format
- **Priority:** P1 - High
- **Preconditions:** Moments loaded
- **Steps:**
  1. Observe moment list entries
- **Expected Result:**
  - Each row shows:
    - Description (max 2 lines, truncated with "...")
    - Type badge with color (from Notion select option)
    - Timestamp (HH:mm format in local time)
    - Project icon/badge (if present)
    - Life area icon/badge (if present)
- **Status:** ⏳ Pending

---

#### TC-US4-003: Auto-Refresh Every 15 Seconds
- **Priority:** P1 - High
- **Preconditions:** List displayed
- **Steps:**
  1. Display moment list
  2. Create new moment in Notion web interface
  3. Wait 15 seconds
- **Expected Result:**
  - Timer fires every 15 seconds
  - API query executed silently (no loading indicator)
  - New moment appears after next refresh
  - No UI disruption during refresh
- **Status:** ⏳ Pending
- **Validation:** Check `MomentListViewModel.refreshTimer` active

---

#### TC-US4-004: Pull-to-Refresh
- **Priority:** P1 - High
- **Preconditions:** List displayed
- **Steps:**
  1. Swipe down from top of list
- **Expected Result:**
  - Refresh spinner appears
  - API query executed
  - List updated with latest data
  - Spinner dismisses
- **Status:** ⏳ Pending

---

#### TC-US4-005: Empty State - No Moments Today
- **Priority:** P2 - Medium
- **Preconditions:** No moments created for today
- **Steps:**
  1. View list
- **Expected Result:**
  - Empty state view shown
  - Message: "Noch keine Momente heute" (or similar)
  - CTA button: "Moment erfassen" → Opens form
- **Status:** ⏳ Pending

---

#### TC-US4-006: Network Error During Load
- **Priority:** P1 - High
- **Preconditions:** Network disabled
- **Steps:**
  1. Launch app
  2. Attempt to load moments
- **Expected Result:**
  - Error banner shown at top
  - Message: "Netzwerkfehler. Bitte überprüfe deine Internetverbindung."
  - Previously cached data remains visible (if any)
  - User can retry via pull-to-refresh
- **Status:** ⏳ Pending

---

### US-5: Edit Moment

#### TC-US5-001: Open Moment in View Mode
- **Priority:** P1 - High
- **Preconditions:** Moments displayed
- **Steps:**
  1. Tap on a moment row
- **Expected Result:**
  - ⚠️ **GAP:** PRD AC5.1 requires detail view in view mode
  - **Current Implementation:** No detail view exists, tapping likely opens edit form directly
  - **Recommendation:** Add `MomentDetailView` with view mode + edit icon
- **Status:** ⚠️ Missing Feature

---

#### TC-US5-002: Edit Existing Moment
- **Priority:** P1 - High
- **Preconditions:** Moment detail/edit view open
- **Steps:**
  1. Modify description
  2. Change type
  3. Update timestamp
  4. Tap "Speichern"
- **Expected Result:**
  - API calls `PATCH /v1/pages/{page-id}` with updated properties
  - Only changed properties sent (not full object)
  - Success feedback shown
  - Navigation back to list
  - Updated moment visible
- **Status:** ⏳ Pending

---

#### TC-US5-003: Cancel Edit with Changes
- **Priority:** P2 - Medium
- **Preconditions:** Edit form with modifications
- **Steps:**
  1. Make changes
  2. Tap "Abbrechen"
- **Expected Result:**
  - ⚠️ **GAP:** PRD AC5.7 requires dirty-state confirmation
  - **Current Implementation:** No confirmation dialog implemented
- **Status:** ⚠️ Missing Feature

---

### US-6: Theme Management

#### TC-US6-001: Switch Theme to Dark Mode
- **Priority:** P2 - Medium
- **Preconditions:** Settings screen open
- **Steps:**
  1. Navigate to Settings
  2. Select "Dark" from theme segmented control
- **Expected Result:**
  - UI immediately switches to dark theme
  - Smooth animation (no flashing)
  - Preference saved to UserDefaults
- **Status:** ⏳ Pending

---

#### TC-US6-002: Theme Persistence Across Launches
- **Priority:** P2 - Medium
- **Preconditions:** Theme set to Dark
- **Steps:**
  1. Close app
  2. Relaunch app
- **Expected Result:**
  - Dark theme applied on launch
  - No flash of light theme
- **Status:** ⏳ Pending

---

#### TC-US6-003: System Theme Follow
- **Priority:** P2 - Medium
- **Preconditions:** Theme set to "System"
- **Steps:**
  1. Change iOS/macOS system theme
- **Expected Result:**
  - App theme updates automatically
  - Matches system preference
- **Status:** ⏳ Pending

---

### US-7: Setup Reset

#### TC-US7-001: Reset Setup Flow
- **Priority:** P2 - Medium
- **Preconditions:** App configured
- **Steps:**
  1. Navigate to Settings
  2. Tap "Setup zurücksetzen"
  3. Confirm in dialog
- **Expected Result:**
  - Confirmation dialog: "Warnung vor Datenverlust"
  - After confirmation:
    - Token deleted from SwiftData
    - Database IDs deleted
    - App navigates to setup screen
    - No moment data deleted (only config)
- **Status:** ⏳ Pending

---

## API Integration Tests

### API-001: Validate Token Endpoint
- **Endpoint:** `POST /v1/users/me`
- **Test:** Valid token returns user object
- **Validation:**
  - Response status: 200
  - Body contains: `{"object": "user", "id": "...", "name": "..."}`
  - Type is "person" or "bot"

---

### API-002: Search Databases
- **Endpoint:** `POST /v1/search`
- **Request Body:**
```json
{
  "filter": {"property": "object", "value": "database"},
  "page_size": 100
}
```
- **Test:** Returns all accessible databases
- **Validation:**
  - Response: `{"results": [...], "has_more": bool, "next_cursor": string?}`
  - Each result is NotionDatabaseResponse
  - Pagination handled if `has_more: true`

---

### API-003: Query Database with Date Filter
- **Endpoint:** `POST /v1/databases/{id}/query`
- **Request Body:**
```json
{
  "filter": {
    "property": "Zeitpunkt",
    "date": {"equals": "2025-10-22"}
  },
  "sorts": [{"property": "Zeitpunkt", "direction": "descending"}],
  "page_size": 100
}
```
- **Test:** Returns moments for specific UTC date
- **Validation:**
  - Only moments with matching date returned
  - Sorted by timestamp descending
  - Pagination handled

---

### API-004: Create Page
- **Endpoint:** `POST /v1/pages`
- **Request Body:**
```json
{
  "parent": {"database_id": "..."},
  "properties": {
    "Name": {"title": [{"text": {"content": "Test Moment"}}]},
    "Typ": {"select": {"name": "Gedanke"}},
    "Zeitpunkt": {"date": {"start": "2025-10-22T14:30:00Z"}},
    "Projekt": {"relation": [{"id": "project-id"}]},
    "Lebensbereich": {"relation": [{"id": "life-area-id"}]}
  }
}
```
- **Test:** Creates new moment page
- **Validation:**
  - Response status: 200
  - Returns created NotionPageResponse with page ID
  - Properties match request

---

### API-005: Update Page
- **Endpoint:** `PATCH /v1/pages/{page-id}`
- **Request Body:**
```json
{
  "properties": {
    "Name": {"title": [{"text": {"content": "Updated Title"}}]}
  }
}
```
- **Test:** Updates existing page properties
- **Validation:**
  - Response status: 200
  - Only specified properties updated
  - Other properties unchanged

---

### API-006: Rate Limiting Handling
- **Scenario:** Exceed 3 requests/second
- **Test:** Trigger 429 response
- **Validation:**
  - Error caught as `.rateLimited`
  - Retry-After header read
  - Exponential backoff applied (1s, 2s, 4s)
  - Max 3 retries before failing

---

### API-007: Pagination Support
- **Scenario:** Database with >100 entries
- **Test:** Recursive pagination
- **Validation:**
  - Initial request: `page_size: 100`
  - If `has_more: true`, follow `next_cursor`
  - All pages aggregated into single result array

---

## Data Mapping Tests

### MAP-001: NotionPageResponse → Moment
- **Input:** NotionPageResponse with all properties
- **Test:** `MomentMapper.toDomain(_:)`
- **Validation:**
  - Title extracted from `properties["Name"].title[0].plainText`
  - Type mapped from `properties["Typ"].select.name`
  - Color mapped from `properties["Typ"].select.color`
  - Timestamp parsed from ISO8601 string
  - Optional relations extracted correctly

---

### MAP-002: Missing Required Property Error
- **Input:** NotionPageResponse without "Name"
- **Test:** Mapper throws error
- **Expected:** `MappingError.missingRequiredProperty("Name")`

---

### MAP-003: Invalid Date Format Error
- **Input:** "Zeitpunkt" with invalid date string
- **Test:** Mapper handles gracefully
- **Expected:** Error or nil moment

---

### MAP-004: Moment → NotionProperty
- **Input:** Moment domain object
- **Test:** `MomentMapper.toNotionProperties(...)`
- **Validation:**
  - Title converted to RichText array
  - Type converted to SelectOption
  - Timestamp formatted as ISO8601 UTC
  - Relations converted to ID arrays

---

### MAP-005: Project Mapper
- **Input:** NotionPageResponse with project data
- **Test:** `ProjectMapper.toDomain(_:)`
- **Validation:**
  - Title from "Projekt" property
  - Status from "Status" property
  - Correct Project domain object created

---

### MAP-006: LifeArea Mapper
- **Input:** NotionPageResponse with life area data
- **Test:** `LifeAreaMapper.toDomain(_:)`
- **Validation:**
  - Title from "Thema" property
  - Status from "Status" property
  - Correct LifeArea domain object created

---

## Error Handling Tests

### ERR-001: 401 Unauthorized
- **Scenario:** Invalid/expired token
- **Test:** API returns 401
- **Expected Behavior:**
  - Error: `.unauthorized`
  - User message: "Token ungültig oder abgelaufen. Bitte melde dich neu an."
  - ⚠️ **GAP:** PRD REQ-ERR-001 requires redirect to setup flow
  - **Current:** Error shown in alert, but no automatic redirect
  - **Recommendation:** Add global error handler to detect 401 and trigger setup reset

---

### ERR-002: 403 Forbidden
- **Scenario:** Token lacks database permissions
- **Test:** API returns 403
- **Expected:**
  - Error: `.forbidden(resource: "Datenbank")`
  - User message: "Keine Berechtigung für diese Datenbank"

---

### ERR-003: 404 Not Found
- **Scenario:** Database deleted after setup
- **Test:** Query non-existent database
- **Expected:**
  - Error: `.notFound(resource: "Datenbank")`
  - User message: "Datenbank nicht gefunden"

---

### ERR-004: 429 Rate Limit
- **Scenario:** Too many requests
- **Test:** Trigger rate limit
- **Expected:**
  - Error: `.rateLimited(retryAfter: TimeInterval)`
  - User message: "Zu viele Anfragen. Bitte warte X Sekunden."
  - Automatic retry with exponential backoff (max 3 attempts)

---

### ERR-005: 500 Server Error
- **Scenario:** Notion server error
- **Test:** Mock 500 response
- **Expected:**
  - Error: `.serverError(statusCode: 500, message: ...)`
  - User message: "Notion Server-Fehler (500). Bitte versuche es später erneut."
  - Retry mechanism (max 3 attempts)

---

### ERR-006: Network Error (No Internet)
- **Scenario:** Device offline
- **Test:** Airplane mode enabled
- **Expected:**
  - Error: `.networkError(underlying: ...)`
  - User message: "Netzwerkfehler. Bitte überprüfe deine Internetverbindung."
  - Retry button available

---

### ERR-007: Decoding Error
- **Scenario:** Notion API schema change
- **Test:** Invalid JSON response
- **Expected:**
  - Error: `.decodingError(underlying: ..., data: Data)`
  - User message: "Fehler beim Verarbeiten der Antwort von Notion."
  - Technical details logged to OSLog

---

## Performance Tests

### PERF-001: Today's View Load Time
- **Target:** <2 seconds for 50 moments
- **Test:**
  1. Create 50 test moments for today
  2. Measure time from view appear to list populated
- **Validation:**
  - Average load time <2s
  - 95th percentile <3s
- **Status:** ⏳ Pending

---

### PERF-002: Moment Creation Feedback
- **Target:** <1 second user feedback
- **Test:**
  1. Fill form
  2. Tap "Speichern"
  3. Measure time to feedback (toast/alert)
- **Validation:**
  - Optimistic UI update <100ms
  - API response <1s
- **Status:** ⏳ Pending

---

### PERF-003: Auto-Refresh CPU Usage
- **Target:** <5% CPU during idle
- **Test:**
  1. Display list
  2. Monitor CPU for 60 seconds
  3. Check auto-refresh impact
- **Validation:**
  - Background refresh <5% CPU spike
  - No memory leaks
- **Status:** ⏳ Pending

---

### PERF-004: App Launch Time
- **Target:** <3 seconds to main view (after setup)
- **Test:**
  1. Cold launch app
  2. Measure time to moment list visible
- **Validation:**
  - Configuration load <500ms
  - SwiftData read <200ms
  - UI render <2s
- **Status:** ⏳ Pending

---

## Test Environment Setup

### Required Configuration

1. **Notion Test Workspace**
   - Create test integration token
   - Set up 3 test databases:
     - **Momente DB** with properties:
       - Name (title)
       - Typ (select) with options: Gedanke, Erlebnis, Aktivität, Idee, Emotion, Lernen
       - Zeitpunkt (date)
       - Projekt (relation)
       - Lebensbereich (relation)
     - **Projekte DB** with properties:
       - Projekt (title)
       - Status (status) with option: "In Bearbeitung"
     - **Lebensbereiche DB** with properties:
       - Thema (title)
       - Status (status) with option: "Aktiv"

2. **Test Data**
   - 10 moments for today (various types)
   - 5 moments for yesterday (to test filtering)
   - 3 active projects
   - 4 active life areas

3. **Xcode Configuration**
   - Set `NOTION_TEST_TOKEN` environment variable
   - Configure in-memory SwiftData for unit tests
   - Mock URLSession for isolated tests

### Test Devices

- **iOS Simulator:** iPhone 15 (iOS 17.0)
- **Physical Device:** iPhone 14 Pro (for performance tests)
- **macOS:** macOS 14.0+ (conditional UI tests)

---

## Risk Assessment

### High Risk Areas

1. **UTC ↔ Local Timezone Conversion** ⚠️
   - **Risk:** Date boundary bugs (moments appearing on wrong day)
   - **Mitigation:** Comprehensive DateConverter unit tests with edge cases (DST transitions)
   - **Test Coverage:** 95% required

2. **Pagination Handling** ⚠️
   - **Risk:** Infinite loops or incomplete data with large databases
   - **Mitigation:** Integration tests with 200+ entry databases
   - **Test Coverage:** Recursive cursor following tested

3. **Error Handling Completeness** ⚠️
   - **Risk:** Unhandled error states crash app
   - **Mitigation:** All API calls wrapped in do-catch, comprehensive NotionAPIError enum
   - **Test Coverage:** Every error path tested

4. **SwiftData Migration** ⚠️
   - **Risk:** Configuration loss on schema changes
   - **Mitigation:** Schema versioning (currently v1, no migration needed)
   - **Test Coverage:** Upgrade/downgrade tests for future versions

### Critical Gaps Identified

| Gap ID | Description | Priority | Recommendation |
|--------|-------------|----------|----------------|
| **GAP-001** | No dirty-state confirmation on form cancel | P2 | Add `hasChanges` tracking + confirmation alert |
| **GAP-002** | No detail view in view mode (AC5.1) | P1 | Create `MomentDetailView` with view/edit separation |
| **GAP-003** | No automatic 401 redirect to setup (REQ-ERR-001) | P1 | Implement global error observer in `MomentchenApp` |
| **GAP-004** | Delete moment not supported (API limitation) | P3 | Document limitation, hide swipe-delete action |
| **GAP-005** | No test coverage exists yet | P0 | Implement test suite with 80% coverage target |

---

## Test Execution Checklist

### Pre-Release Validation

- [ ] All P0 tests passing (100%)
- [ ] All P1 tests passing (>95%)
- [ ] All 7 User Stories covered
- [ ] All 5 API endpoints functional
- [ ] Error handling verified for all paths
- [ ] Performance targets met (2s load, 1s create)
- [ ] German UI language verified
- [ ] Theme switching smooth
- [ ] Auto-refresh working
- [ ] Timezone conversion correct

### Sign-Off

- [ ] Test Architect approval
- [ ] Product Manager sign-off
- [ ] Developer confirmation of bug fixes
- [ ] Ready for beta testing

---

**Document Version:** 1.0
**Last Updated:** October 22, 2025
**Next Review:** Before V1 release
