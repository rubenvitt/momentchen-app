# Swift Architektur-Dokument: Momentchen

**Version:** 1.0
**Datum:** 22. Oktober 2025
**Plattformen:** iOS 17.0+, macOS 14.0+
**Sprache:** Swift 5.9+, SwiftUI, SwiftData

---

## 1. Architektur-Übersicht

```
┌─────────────────────────────────────────────────────────────┐
│                     SwiftUI Views                           │
│  (ContentView, SetupFlow, MomentForm, Settings)             │
└───────────────────────┬─────────────────────────────────────┘
                        │ @StateObject / @Environment
┌───────────────────────▼─────────────────────────────────────┐
│                   ViewModels (@Observable)                  │
│  (SetupViewModel, MomentListViewModel, MomentFormViewModel) │
└───────────────────────┬─────────────────────────────────────┘
                        │ async/await
┌───────────────────────▼─────────────────────────────────────┐
│                   Domain Services                           │
│  (MomentService, ProjectService, LifeAreaService)           │
└───────────────┬───────────────────┬─────────────────────────┘
                │                   │
       ┌────────▼────────┐  ┌──────▼──────────┐
       │ NotionAPIService│  │ ConfigService   │
       │  (URLSession)   │  │  (SwiftData)    │
       └─────────────────┘  └─────────────────┘
                │                   │
       ┌────────▼────────┐  ┌──────▼──────────┐
       │  Notion REST API│  │ SwiftData Store │
       │  (Cloud)        │  │  (Local)        │
       └─────────────────┘  └─────────────────┘
```

**Architektur-Prinzipien:**
- **Single Source of Truth**: Notion als primäre Datenquelle (keine lokale Moment-Persistenz)
- **Separation of Concerns**: Strikte Layer-Trennung (UI → ViewModel → Service → API)
- **Async/Await First**: Keine Completion Handlers, pure async/await
- **Protocol-Oriented**: Alle Services hinter Protocols für Testability
- **SwiftData für Config**: Nur für App-Konfiguration, nicht für Business-Daten

---

## 2. Layer-Design

### 2.1 Presentation Layer (SwiftUI)

**Verantwortlichkeiten:**
- UI-Darstellung und User-Interaktion
- Navigation und State-Management
- Theme-Anwendung

**Komponenten:**
```swift
// Screens
ContentView.swift              // Haupt-Navigation (TabView)
SetupFlowView.swift           // Token + DB-Auswahl
MomentListView.swift          // Heute-Ansicht
MomentFormView.swift          // Erfassen/Bearbeiten
SettingsView.swift            // Einstellungen

// Reusable Components
MomentRow.swift               // Listen-Eintrag
DatabasePicker.swift          // DB-Dropdown
ThemeToggle.swift             // Theme-Segmented-Control
LoadingOverlay.swift          // Full-Screen Loader
ErrorBanner.swift             // Auto-dismissing Error
```

### 2.2 Domain Layer (ViewModels + Services)

**Verantwortlichkeiten:**
- Business Logic und State-Management
- Orchestrierung von Service-Calls
- Fehlerbehandlung und User-Feedback

**ViewModels:**
```swift
@Observable
class SetupViewModel {
    var notionToken: String = ""
    var availableDatabases: [NotionDatabase] = []
    var selectedMomentsDB: NotionDatabase?
    var selectedProjectsDB: NotionDatabase?
    var selectedLifeAreasDB: NotionDatabase?
    var isLoading: Bool = false
    var errorMessage: String?

    func validateToken() async
    func loadDatabases() async
    func saveConfiguration() async throws
}

@Observable
class MomentListViewModel {
    var moments: [Moment] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var lastRefreshDate: Date?

    func loadTodaysMoments() async
    func refreshMoments() async
    func deleteMoment(_ moment: Moment) async
    func startAutoRefresh() // 15s Timer
}

@Observable
class MomentFormViewModel {
    var description: String = ""
    var selectedType: MomentType?
    var timestamp: Date = Date()
    var selectedProject: Project?
    var selectedLifeArea: LifeArea?
    var availableTypes: [MomentType] = []
    var availableProjects: [Project] = []
    var availableLifeAreas: [LifeArea] = []
    var isEditing: Bool = false

    func loadAvailableOptions() async
    func saveMoment() async throws
    func updateMoment(id: String) async throws
}
```

**Services:**
```swift
// Domain Services orchestrieren API + Config
protocol MomentServiceProtocol {
    func fetchTodaysMoments() async throws -> [Moment]
    func createMoment(properties: MomentProperties) async throws -> Moment
    func updateMoment(id: String, properties: MomentProperties) async throws
}

protocol ProjectServiceProtocol {
    func fetchActiveProjects() async throws -> [Project]
}

protocol LifeAreaServiceProtocol {
    func fetchActiveLifeAreas() async throws -> [LifeArea]
}
```

### 2.3 Data Layer (API + Repositories)

**Verantwortlichkeiten:**
- Notion API-Kommunikation
- Request/Response-Mapping
- Pagination-Handling
- Retry-Logik

**API Service:**
```swift
protocol NotionAPIServiceProtocol {
    func validateToken() async throws -> NotionUser
    func searchDatabases(filter: SearchFilter?) async throws -> [NotionDatabase]
    func queryDatabase(id: String, filter: DatabaseFilter?, sorts: [Sort]?) async throws -> [NotionPage]
    func createPage(databaseId: String, properties: [String: NotionProperty]) async throws -> NotionPage
    func updatePage(id: String, properties: [String: NotionProperty]) async throws -> NotionPage
}

class NotionAPIService: NotionAPIServiceProtocol {
    private let baseURL = URL(string: "https://api.notion.com/v1")!
    private let notionVersion = "2022-06-28"
    private var token: String

    init(token: String) {
        self.token = token
    }

    // Generische Request-Methode mit Error-Handling
    private func performRequest<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        // URLSession-Implementation
    }
}
```

### 2.4 Infrastructure Layer (Config + Utilities)

**Verantwortlichkeiten:**
- SwiftData-Persistenz für Konfiguration
- Keychain-Management für Token
- Datum/Zeit-Konvertierung
- Theme-Verwaltung

**Komponenten:**
```swift
// Configuration Service
protocol ConfigurationServiceProtocol {
    func loadConfiguration() async throws -> AppConfiguration?
    func saveConfiguration(_ config: AppConfiguration) async throws
    func deleteConfiguration() async throws
}

// Date Service (UTC ↔ Local)
protocol DateServiceProtocol {
    func toUTC(from localDate: Date) -> Date
    func toLocal(from utcDate: Date) -> Date
    func formatForAPI(_ date: Date) -> String // ISO8601
    func parseFromAPI(_ string: String) -> Date?
}

// Theme Manager
class ThemeManager: ObservableObject {
    @Published var currentTheme: ThemePreference = .system

    func applyTheme(_ theme: ThemePreference)
    func loadSavedTheme()
}
```

---

## 3. MVVM Pattern

### 3.1 Protocol-Definition

```swift
// Base ViewModel Protocol
protocol ViewModelProtocol: ObservableObject {
    associatedtype State
    var state: State { get set }
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
}

// Error-Handling Extension
extension ViewModelProtocol {
    func handleError(_ error: Error) {
        if let apiError = error as? NotionAPIError {
            errorMessage = apiError.userMessage
        } else {
            errorMessage = "Ein unerwarteter Fehler ist aufgetreten"
        }
        isLoading = false
    }
}
```

### 3.2 Beispiel: MomentListViewModel

```swift
@Observable
class MomentListViewModel {
    // MARK: - Dependencies
    private let momentService: MomentServiceProtocol
    private let dateService: DateServiceProtocol
    private var refreshTimer: Timer?

    // MARK: - State
    var moments: [Moment] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var lastRefreshDate: Date?

    // MARK: - Initialization
    init(
        momentService: MomentServiceProtocol,
        dateService: DateServiceProtocol
    ) {
        self.momentService = momentService
        self.dateService = dateService
    }

    // MARK: - Public Methods
    @MainActor
    func loadTodaysMoments() async {
        isLoading = true
        errorMessage = nil

        do {
            moments = try await momentService.fetchTodaysMoments()
            lastRefreshDate = Date()
            isLoading = false
        } catch {
            handleError(error)
        }
    }

    @MainActor
    func refreshMoments() async {
        // Refresh ohne Loading-Indikator (für Auto-Refresh)
        do {
            let freshMoments = try await momentService.fetchTodaysMoments()
            moments = freshMoments
            lastRefreshDate = Date()
        } catch {
            // Silent failure bei Auto-Refresh
            print("Auto-refresh failed: \(error)")
        }
    }

    func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshMoments()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    @MainActor
    func deleteMoment(_ moment: Moment) async {
        // Optimistic Update
        moments.removeAll { $0.id == moment.id }

        do {
            try await momentService.deleteMoment(id: moment.id)
        } catch {
            // Rollback bei Fehler
            await loadTodaysMoments()
            handleError(error)
        }
    }

    // MARK: - Private Methods
    private func handleError(_ error: Error) {
        if let apiError = error as? NotionAPIError {
            errorMessage = apiError.userMessage
        } else {
            errorMessage = "Fehler beim Laden der Momente"
        }
        isLoading = false
    }

    deinit {
        stopAutoRefresh()
    }
}

// MARK: - View Integration
struct MomentListView: View {
    @State private var viewModel: MomentListViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.moments) { moment in
                    MomentRow(moment: moment)
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteMoment(moment)
                                }
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                }
            }
            .refreshable {
                await viewModel.loadTodaysMoments()
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
            .task {
                await viewModel.loadTodaysMoments()
                viewModel.startAutoRefresh()
            }
        }
    }
}
```

---

## 4. SwiftData Models

### 4.1 AppConfiguration Model

```swift
import SwiftData
import Foundation

@Model
final class AppConfiguration {
    // MARK: - Properties
    @Attribute(.unique) var id: UUID
    var notionToken: String // Wird via Keychain verschlüsselt
    var momentsDatabaseId: String
    var projectsDatabaseId: String
    var lifeAreasDatabaseId: String
    var themePreference: String // ThemePreference.rawValue
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        notionToken: String,
        momentsDatabaseId: String,
        projectsDatabaseId: String,
        lifeAreasDatabaseId: String,
        themePreference: ThemePreference = .system,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.notionToken = notionToken
        self.momentsDatabaseId = momentsDatabaseId
        self.projectsDatabaseId = projectsDatabaseId
        self.lifeAreasDatabaseId = lifeAreasDatabaseId
        self.themePreference = themePreference.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties
    var theme: ThemePreference {
        get { ThemePreference(rawValue: themePreference) ?? .system }
        set { themePreference = newValue.rawValue }
    }
}

// MARK: - Supporting Types
enum ThemePreference: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// MARK: - SwiftData Container Setup
extension AppConfiguration {
    static var modelContainer: ModelContainer = {
        let schema = Schema([AppConfiguration.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}

// MARK: - App Integration
@main
struct MomentchenApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(AppConfiguration.modelContainer)
    }
}
```

### 4.2 Configuration Service Implementation

```swift
import SwiftData

class ConfigurationService: ConfigurationServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadConfiguration() async throws -> AppConfiguration? {
        let descriptor = FetchDescriptor<AppConfiguration>()
        let configs = try modelContext.fetch(descriptor)
        return configs.first
    }

    func saveConfiguration(_ config: AppConfiguration) async throws {
        config.updatedAt = Date()
        modelContext.insert(config)
        try modelContext.save()
    }

    func deleteConfiguration() async throws {
        let descriptor = FetchDescriptor<AppConfiguration>()
        let configs = try modelContext.fetch(descriptor)

        for config in configs {
            modelContext.delete(config)
        }

        try modelContext.save()
    }
}
```

---

## 5. Notion API Service

### 5.1 Protocol Definition

```swift
import Foundation

protocol NotionAPIServiceProtocol {
    func validateToken() async throws -> NotionUser
    func searchDatabases(filter: SearchFilter?) async throws -> [NotionDatabase]
    func queryDatabase(
        id: String,
        filter: DatabaseFilter?,
        sorts: [Sort]?,
        pageSize: Int
    ) async throws -> [NotionPage]
    func createPage(
        databaseId: String,
        properties: [String: NotionProperty]
    ) async throws -> NotionPage
    func updatePage(
        id: String,
        properties: [String: NotionProperty]
    ) async throws -> NotionPage
}

// MARK: - Supporting Types
struct SearchFilter: Codable {
    let property: String
    let value: String
}

struct DatabaseFilter: Codable {
    let property: String
    let date: DateFilter?

    struct DateFilter: Codable {
        let equals: String? // ISO8601 Date
    }
}

struct Sort: Codable {
    let property: String
    let direction: SortDirection

    enum SortDirection: String, Codable {
        case ascending
        case descending
    }
}
```

### 5.2 Implementation (Key Methods)

```swift
class NotionAPIService: NotionAPIServiceProtocol {
    // MARK: - Properties
    private let baseURL = URL(string: "https://api.notion.com/v1")!
    private let notionVersion = "2022-06-28"
    private var token: String
    private let session: URLSession

    // MARK: - Initialization
    init(token: String, session: URLSession = .shared) {
        self.token = token
        self.session = session
    }

    // MARK: - Public Methods
    func validateToken() async throws -> NotionUser {
        return try await performRequest(
            endpoint: "/users/me",
            method: "GET"
        )
    }

    func searchDatabases(filter: SearchFilter? = nil) async throws -> [NotionDatabase] {
        let body = SearchRequest(
            filter: ["property": "object", "value": "database"],
            pageSize: 100
        )

        let response: SearchResponse<NotionDatabase> = try await performRequest(
            endpoint: "/search",
            method: "POST",
            body: body
        )

        return response.results
    }

    func queryDatabase(
        id: String,
        filter: DatabaseFilter? = nil,
        sorts: [Sort]? = nil,
        pageSize: Int = 100
    ) async throws -> [NotionPage] {
        let body = QueryRequest(
            filter: filter,
            sorts: sorts,
            pageSize: pageSize
        )

        let response: QueryResponse = try await performRequest(
            endpoint: "/databases/\(id)/query",
            method: "POST",
            body: body
        )

        // Handle Pagination
        var allPages = response.results
        if response.hasMore, let cursor = response.nextCursor {
            let nextPages = try await queryDatabaseWithCursor(
                id: id,
                cursor: cursor,
                filter: filter,
                sorts: sorts
            )
            allPages.append(contentsOf: nextPages)
        }

        return allPages
    }

    func createPage(
        databaseId: String,
        properties: [String: NotionProperty]
    ) async throws -> NotionPage {
        let body = CreatePageRequest(
            parent: ["database_id": databaseId],
            properties: properties
        )

        return try await performRequest(
            endpoint: "/pages",
            method: "POST",
            body: body
        )
    }

    func updatePage(
        id: String,
        properties: [String: NotionProperty]
    ) async throws -> NotionPage {
        let body = UpdatePageRequest(properties: properties)

        return try await performRequest(
            endpoint: "/pages/\(id)",
            method: "PATCH",
            body: body
        )
    }

    // MARK: - Private Methods
    private func performRequest<T: Decodable>(
        endpoint: String,
        method: String,
        body: Encodable? = nil,
        retryCount: Int = 0
    ) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(notionVersion, forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NotionAPIError.networkError(NSError(domain: "Invalid response", code: -1))
            }

            // Error Handling
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 429 && retryCount < 3 {
                    // Rate Limiting: Exponential Backoff
                    let delay = UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000)
                    try await Task.sleep(nanoseconds: delay)
                    return try await performRequest(
                        endpoint: endpoint,
                        method: method,
                        body: body,
                        retryCount: retryCount + 1
                    )
                }
                throw NotionAPIError.serverError(httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)

        } catch let error as NotionAPIError {
            throw error
        } catch {
            throw NotionAPIError.networkError(error)
        }
    }

    private func queryDatabaseWithCursor(
        id: String,
        cursor: String,
        filter: DatabaseFilter?,
        sorts: [Sort]?
    ) async throws -> [NotionPage] {
        let body = QueryRequest(
            filter: filter,
            sorts: sorts,
            pageSize: 100,
            startCursor: cursor
        )

        let response: QueryResponse = try await performRequest(
            endpoint: "/databases/\(id)/query",
            method: "POST",
            body: body
        )

        var pages = response.results
        if response.hasMore, let nextCursor = response.nextCursor {
            let nextPages = try await queryDatabaseWithCursor(
                id: id,
                cursor: nextCursor,
                filter: filter,
                sorts: sorts
            )
            pages.append(contentsOf: nextPages)
        }

        return pages
    }
}
```

---

## 6. Error Handling

### 6.1 Error Enum Hierarchy

```swift
// MARK: - Base API Error
enum NotionAPIError: Error, LocalizedError {
    case invalidToken
    case unauthorized
    case forbidden(String)
    case notFound(String)
    case rateLimited
    case badRequest(String)
    case serverError(Int)
    case networkError(Error)
    case decodingError(Error)
    case validationError(String)

    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "Ungültiger Notion Token"
        case .unauthorized:
            return "Token ungültig, bitte neu einloggen"
        case .forbidden(let resource):
            return "Keine Berechtigung für \(resource)"
        case .notFound(let resource):
            return "\(resource) nicht gefunden"
        case .rateLimited:
            return "Zu viele Anfragen, bitte warten"
        case .badRequest(let message):
            return "Ungültige Anfrage: \(message)"
        case .serverError(let code):
            return "Notion Server-Fehler (\(code)), bitte später versuchen"
        case .networkError(let error):
            return "Netzwerkfehler: \(error.localizedDescription)"
        case .decodingError:
            return "Fehler beim Verarbeiten der Antwort"
        case .validationError(let message):
            return message
        }
    }

    var userMessage: String {
        errorDescription ?? "Ein Fehler ist aufgetreten"
    }
}

// MARK: - Configuration Errors
enum ConfigurationError: Error, LocalizedError {
    case notFound
    case saveFailed(Error)
    case deleteFailed(Error)
    case invalidConfiguration(String)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Keine Konfiguration gefunden"
        case .saveFailed(let error):
            return "Speichern fehlgeschlagen: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Löschen fehlgeschlagen: \(error.localizedDescription)"
        case .invalidConfiguration(let message):
            return "Ungültige Konfiguration: \(message)"
        }
    }
}

// MARK: - Domain Errors
enum MomentError: Error, LocalizedError {
    case creationFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case invalidProperties(String)
    case missingRequiredField(String)

    var errorDescription: String? {
        switch self {
        case .creationFailed:
            return "Moment konnte nicht erstellt werden"
        case .updateFailed:
            return "Moment konnte nicht aktualisiert werden"
        case .deleteFailed:
            return "Moment konnte nicht gelöscht werden"
        case .invalidProperties(let message):
            return "Ungültige Eigenschaften: \(message)"
        case .missingRequiredField(let field):
            return "Pflichtfeld fehlt: \(field)"
        }
    }
}
```

---

## 7. Data Flow

### 7.1 Setup Flow (Token-Validierung)

**Ablauf:**
1. User gibt Token in `SetupFlowView` ein
2. `SetupViewModel.validateToken()` ruft `NotionAPIService.validateToken()` auf
3. API-Call zu `/v1/users/me`
4. Bei Erfolg (200): Token + User-Info in `AppConfiguration` speichern via `ConfigurationService`
5. Bei Fehler (401): `NotionAPIError.unauthorized` werfen, UI zeigt Error-Banner
6. Navigation zu Datenbank-Auswahl

**Code-Flow:**
```
SetupFlowView
  └─> SetupViewModel.validateToken()
       └─> NotionAPIService.validateToken()
            └─> URLSession.data(for: request)
                 ├─> Success: NotionUser
                 │    └─> ConfigurationService.saveConfiguration()
                 │         └─> SwiftData ModelContext.save()
                 │              └─> Navigation → DatabaseSelectionView
                 └─> Error: 401
                      └─> throw NotionAPIError.unauthorized
                           └─> SetupViewModel.handleError()
                                └─> errorMessage = "Token ungültig"
```

### 7.2 Create Moment Flow

**Ablauf:**
1. User füllt `MomentFormView` aus (Beschreibung, Typ, Zeit, Kategorien)
2. `MomentFormViewModel.saveMoment()` validiert Input
3. Zeitstempel wird von Lokalzeit zu UTC konvertiert (`DateService`)
4. `MomentService.createMoment()` mappt Domain-Model zu Notion-Properties
5. `NotionAPIService.createPage()` sendet POST zu `/v1/pages`
6. Bei Erfolg: Toast-Nachricht + Navigation zurück zu Liste
7. Bei Fehler: Alert mit spezifischer Fehlermeldung

**Code-Flow:**
```
MomentFormView [User Input]
  └─> MomentFormViewModel.saveMoment()
       ├─> Validation (Beschreibung nicht leer, Typ ausgewählt)
       └─> DateService.toUTC(timestamp)
            └─> MomentService.createMoment(properties)
                 ├─> Map Domain Properties → Notion Properties
                 └─> NotionAPIService.createPage(databaseId, properties)
                      └─> URLSession POST /v1/pages
                           ├─> Success: NotionPage
                           │    └─> Map to Domain Moment
                           │         └─> MomentFormViewModel.showSuccessToast()
                           │              └─> Navigation → MomentListView
                           └─> Error: 400/401/500
                                └─> throw NotionAPIError
                                     └─> MomentFormViewModel.handleError()
                                          └─> errorMessage + Alert
```

### 7.3 Fetch Today's Moments Flow

**Ablauf:**
1. `MomentListView` wird geladen, triggert `MomentListViewModel.loadTodaysMoments()`
2. Aktuelles Datum wird zu UTC-Datum konvertiert
3. `MomentService.fetchTodaysMoments()` erstellt Filter für "Zeitpunkt = heute"
4. `NotionAPIService.queryDatabase()` mit Filter + Sort (neueste zuerst)
5. Pagination-Handling falls `has_more = true`
6. Response-Pages werden zu Domain-`Moment`-Objekten gemappt
7. UTC-Zeitstempel werden zu Lokalzeit konvertiert für UI-Anzeige
8. Liste wird aktualisiert, Auto-Refresh-Timer startet (15s)

**Code-Flow:**
```
MomentListView.task { loadTodaysMoments() }
  └─> MomentListViewModel.loadTodaysMoments()
       └─> DateService.toUTC(Date()) → "2025-10-22"
            └─> MomentService.fetchTodaysMoments()
                 ├─> Create DatabaseFilter(property: "Zeitpunkt", date.equals: "2025-10-22")
                 └─> NotionAPIService.queryDatabase(id, filter, sorts)
                      └─> URLSession POST /v1/databases/{id}/query
                           ├─> Response: QueryResponse (results + has_more + next_cursor)
                           ├─> Pagination Loop while has_more == true
                           └─> Map [NotionPage] → [Moment]
                                ├─> Parse Properties (title, select, date, relations)
                                ├─> DateService.toLocal(utcTimestamp)
                                └─> MomentListViewModel.moments = mappedMoments
                                     └─> SwiftUI re-renders List
                                          └─> Start Timer(15s) → refreshMoments()
```

---

## 8. Project Structure

```
Momentchen/
├── Momentchen/
│   ├── MomentchenApp.swift                 # App Entry Point + SwiftData Setup
│   │
│   ├── Presentation/
│   │   ├── Views/
│   │   │   ├── ContentView.swift           # Haupt-Navigation (TabView)
│   │   │   ├── Setup/
│   │   │   │   ├── SetupFlowView.swift     # Setup-Navigation
│   │   │   │   ├── TokenInputView.swift    # Token-Eingabe
│   │   │   │   ├── DatabaseSelectionView.swift
│   │   │   │   └── SetupSuccessView.swift
│   │   │   ├── Moments/
│   │   │   │   ├── MomentListView.swift    # Heute-Ansicht
│   │   │   │   ├── MomentFormView.swift    # Erfassen/Bearbeiten
│   │   │   │   └── MomentDetailView.swift  # View-Mode
│   │   │   └── Settings/
│   │   │       └── SettingsView.swift
│   │   │
│   │   ├── Components/
│   │   │   ├── MomentRow.swift
│   │   │   ├── DatabasePicker.swift
│   │   │   ├── ThemeToggle.swift
│   │   │   ├── LoadingOverlay.swift
│   │   │   └── ErrorBanner.swift
│   │   │
│   │   └── ViewModels/
│   │       ├── SetupViewModel.swift
│   │       ├── MomentListViewModel.swift
│   │       ├── MomentFormViewModel.swift
│   │       └── SettingsViewModel.swift
│   │
│   ├── Domain/
│   │   ├── Models/
│   │   │   ├── Moment.swift
│   │   │   ├── MomentType.swift
│   │   │   ├── Project.swift
│   │   │   └── LifeArea.swift
│   │   │
│   │   └── Services/
│   │       ├── MomentService.swift
│   │       ├── ProjectService.swift
│   │       └── LifeAreaService.swift
│   │
│   ├── Data/
│   │   ├── API/
│   │   │   ├── NotionAPIService.swift
│   │   │   ├── Models/
│   │   │   │   ├── NotionPage.swift
│   │   │   │   ├── NotionDatabase.swift
│   │   │   │   ├── NotionUser.swift
│   │   │   │   ├── NotionProperty.swift
│   │   │   │   └── Requests/
│   │   │   │       ├── SearchRequest.swift
│   │   │   │       ├── QueryRequest.swift
│   │   │   │       ├── CreatePageRequest.swift
│   │   │   │       └── UpdatePageRequest.swift
│   │   │   └── Responses/
│   │   │       ├── SearchResponse.swift
│   │   │       └── QueryResponse.swift
│   │   │
│   │   └── Persistence/
│   │       ├── AppConfiguration.swift      # SwiftData Model
│   │       └── ConfigurationService.swift
│   │
│   ├── Infrastructure/
│   │   ├── DateService.swift               # UTC ↔ Local
│   │   ├── ThemeManager.swift              # Theme-Verwaltung
│   │   ├── KeychainManager.swift           # Token-Verschlüsselung
│   │   └── Errors/
│   │       ├── NotionAPIError.swift
│   │       ├── ConfigurationError.swift
│   │       └── MomentError.swift
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   ├── Localizable.strings             # V1: nur Deutsch
│   │   └── Info.plist
│   │
│   └── Extensions/
│       ├── Date+Extensions.swift
│       ├── Color+Extensions.swift
│       └── View+Extensions.swift
│
├── MomentchenTests/
│   ├── Domain/
│   │   └── MomentServiceTests.swift
│   ├── Data/
│   │   └── NotionAPIServiceTests.swift
│   ├── Infrastructure/
│   │   └── DateServiceTests.swift
│   └── Mocks/
│       ├── MockNotionAPIService.swift
│       └── MockConfigurationService.swift
│
├── MomentchenUITests/
│   ├── SetupFlowTests.swift
│   ├── MomentCreationTests.swift
│   └── MomentListTests.swift
│
└── Momentchen.xcodeproj
```

---

## 9. Architecture Decision Records (ADRs)

### ADR-001: SwiftData vs CoreData für lokale Persistenz

**Status:** Accepted
**Kontext:** App benötigt lokale Speicherung der Notion-Konfiguration (Token, Database IDs, Theme)

**Entscheidung:** SwiftData verwenden

**Begründung:**
- **Modern**: Native Swift-API ohne Objective-C-Baggage
- **Type-Safe**: `@Model` Macro eliminiert boilerplate NSManagedObject-Code
- **Simple**: Kein `.xcdatamodeld` erforderlich, Migrations automatisch
- **Scope-Limited**: Nur für Konfiguration, nicht für komplexe Relationen

**Alternativen erwogen:**
- CoreData: Überdimensioniert für einfaches Config-Schema
- UserDefaults: Keine Verschlüsselung, nicht typsicher
- Property List: Keine Verschlüsselung, manuelle Serialisierung

**Konsequenzen:**
- ✅ Weniger Code, schnellere Entwicklung
- ✅ Bessere Testability durch Protocol-Abstraction
- ❌ iOS 17.0+ / macOS 14.0+ Mindestanforderung

---

### ADR-002: MVVM ohne Combine/Publisher

**Status:** Accepted
**Kontext:** SwiftUI erfordert State-Management-Pattern für komplexe Business Logic

**Entscheidung:** MVVM mit `@Observable` Macro (Swift 5.9+), ohne Combine

**Begründung:**
- **Simplicity**: `@Observable` reduziert Boilerplate vs. `@Published`
- **Performance**: Keine Combine-Subscriptions, direktes SwiftUI-Observation
- **Async-First**: async/await ist cleaner als Publisher-Chaining für API-Calls
- **Testability**: ViewModels sind POSOs (Plain Old Swift Objects) ohne Framework-Dependencies

**Alternativen erwogen:**
- MV (View-only): Zu viel Business Logic in Views
- VIPER: Überdimensioniert für App-Scope
- Redux/TCA: Steile Lernkurve, Overkill für einfache CRUD-App

**Konsequenzen:**
- ✅ Klare Separation of Concerns
- ✅ Einfaches Unit-Testing via Dependency Injection
- ✅ Keine Combine-Debugging-Komplexität
- ❌ Swift 5.9+ / Xcode 15+ erforderlich

---

### ADR-003: URLSession vs Notion SDK

**Status:** Accepted
**Kontext:** Kommunikation mit Notion REST API v1

**Entscheidung:** Native URLSession mit async/await, kein offizielles SDK

**Begründung:**
- **Control**: Volle Kontrolle über Error-Handling und Retry-Logik
- **Lightweight**: Kein zusätzlicher Dependency, geringere App-Größe
- **Async-First**: URLSession async/await ist native Swift-Idiom
- **Flexibility**: Custom Pagination, Caching, Request-Modifikation
- **No SDK**: Notion bietet kein offizielles Swift-SDK (nur JS/Python)

**Alternativen erwogen:**
- Third-Party SDKs (z.B. SwiftNotion): Nicht offiziell supportet, veraltet
- Alamofire: Überdimensioniert, URLSession async/await ist ausreichend

**Konsequenzen:**
- ✅ Zero Dependencies außer Foundation
- ✅ Optimierte Performance durch custom Pagination
- ❌ Manuelles Mapping von Notion API-Responses
- ❌ Breaking API Changes erfordern manuelles Update

---

## 10. Testing Strategy

### 10.1 Unit Tests

**Was testen:**

**Services (Mocking erforderlich):**
```swift
// MomentServiceTests.swift
class MomentServiceTests: XCTestCase {
    var sut: MomentService!
    var mockAPIService: MockNotionAPIService!
    var mockConfigService: MockConfigurationService!

    func test_fetchTodaysMoments_validResponse_returnsMoments() async throws {
        // Given
        mockAPIService.queryDatabaseResult = .success(mockNotionPages)

        // When
        let moments = try await sut.fetchTodaysMoments()

        // Then
        XCTAssertEqual(moments.count, 3)
        XCTAssertEqual(moments.first?.description, "Test Moment")
    }

    func test_createMoment_apiError_throwsError() async {
        // Given
        mockAPIService.createPageResult = .failure(.serverError(500))

        // When/Then
        await XCTAssertThrowsError(
            try await sut.createMoment(properties: mockProperties)
        )
    }
}
```

**DateService (keine Mocks):**
```swift
// DateServiceTests.swift
func test_toUTC_convertsCorrectly() {
    // Given
    let localDate = Date(timeIntervalSince1970: 1698057600) // 23.10.2023 14:00 CEST

    // When
    let utcDate = sut.toUTC(from: localDate)

    // Then
    let formatter = ISO8601DateFormatter()
    XCTAssertEqual(formatter.string(from: utcDate), "2023-10-23T12:00:00Z")
}
```

**ViewModels (Mocking Services):**
```swift
// MomentListViewModelTests.swift
func test_loadTodaysMoments_success_updatesState() async {
    // Given
    mockMomentService.fetchTodaysMomentsResult = .success(mockMoments)

    // When
    await viewModel.loadTodaysMoments()

    // Then
    XCTAssertEqual(viewModel.moments.count, 3)
    XCTAssertFalse(viewModel.isLoading)
    XCTAssertNil(viewModel.errorMessage)
}
```

**Was mocken:**
- `NotionAPIService` → `MockNotionAPIService` (alle async throws Methods)
- `ConfigurationService` → `MockConfigurationService` (SwiftData CRUD)
- `URLSession` → `MockURLSession` (für NotionAPIService-Tests)

**Was NICHT mocken:**
- `DateService` (reine Funktionen, keine Side-Effects)
- Domain Models (Plain Structs/Enums)
- SwiftUI Views (UI-Tests)

### 10.2 Integration Tests

**Was testen:**

**Setup-Flow End-to-End:**
```swift
func test_setupFlow_validToken_savesConfiguration() async throws {
    // Given: Real ConfigurationService mit in-memory ModelContext
    let configService = ConfigurationService(modelContext: inMemoryContext)
    let apiService = NotionAPIService(token: validTestToken)
    let viewModel = SetupViewModel(apiService: apiService, configService: configService)

    // When
    await viewModel.validateToken()
    await viewModel.loadDatabases()
    viewModel.selectDatabases(moments: db1, projects: db2, lifeAreas: db3)
    try await viewModel.saveConfiguration()

    // Then
    let savedConfig = try await configService.loadConfiguration()
    XCTAssertNotNil(savedConfig)
    XCTAssertEqual(savedConfig?.momentsDatabaseId, db1.id)
}
```

**API-Call mit realem Notion-Endpoint (Optional, requires Test-Token):**
```swift
func test_notionAPIService_validateToken_realAPI() async throws {
    // Requires: NOTION_TEST_TOKEN in Environment
    let token = ProcessInfo.processInfo.environment["NOTION_TEST_TOKEN"]!
    let service = NotionAPIService(token: token)

    let user = try await service.validateToken()

    XCTAssertFalse(user.id.isEmpty)
    XCTAssertEqual(user.object, "user")
}
```

### 10.3 UI Tests

**Was testen:**

**Kritische User Journeys:**
```swift
// SetupFlowUITests.swift
func test_setupFlow_validToken_navigatesToDatabaseSelection() {
    let app = XCUIApplication()
    app.launch()

    // Enter Token
    let tokenField = app.secureTextFields["TokenInputField"]
    tokenField.tap()
    tokenField.typeText("valid_test_token_here")

    // Tap Validate
    app.buttons["Validieren"].tap()

    // Assert Navigation
    XCTAssertTrue(app.navigationBars["Wähle deine Datenbanken"].waitForExistence(timeout: 5))
}

// MomentCreationUITests.swift
func test_createMoment_fillForm_savesSuccessfully() {
    let app = XCUIApplication()
    app.launch()

    // Tap + Button
    app.buttons["NewMomentButton"].tap()

    // Fill Form
    app.textViews["BeschreibungField"].tap()
    app.textViews["BeschreibungField"].typeText("UI Test Moment")
    app.buttons["TypGedanke"].tap()

    // Save
    app.buttons["Speichern"].tap()

    // Assert Toast
    XCTAssertTrue(app.staticTexts["Moment gespeichert"].waitForExistence(timeout: 3))
}
```

**Snapshot Tests (Optional mit swift-snapshot-testing):**
```swift
func test_momentRow_lightMode_snapshot() {
    let moment = Moment.mock()
    let view = MomentRow(moment: moment)
        .environment(\.colorScheme, .light)

    assertSnapshot(matching: view, as: .image)
}
```

---

## Anhang: Code-Beispiele

### A1: Notion Property Mapping

```swift
// Domain → Notion Properties
extension MomentProperties {
    func toNotionProperties() -> [String: NotionProperty] {
        var properties: [String: NotionProperty] = [:]

        // Title (required)
        properties["Name"] = .title([
            NotionRichText(text: NotionRichText.Text(content: description))
        ])

        // Select (type)
        if let type = type {
            properties["Typ"] = .select(NotionSelectOption(name: type.rawValue))
        }

        // Date (timestamp)
        let formatter = ISO8601DateFormatter()
        properties["Zeitpunkt"] = .date(NotionDate(start: formatter.string(from: timestamp)))

        // Relations (optional)
        if let projectId = projectId {
            properties["Projekt"] = .relation([NotionRelation(id: projectId)])
        }

        if let lifeAreaId = lifeAreaId {
            properties["Lebensbereich"] = .relation([NotionRelation(id: lifeAreaId)])
        }

        return properties
    }
}

// Notion Response → Domain Model
extension NotionPage {
    func toMoment() throws -> Moment {
        guard let titleProperty = properties["Name"],
              case .title(let richTexts) = titleProperty,
              let firstText = richTexts.first?.text.content else {
            throw MomentError.missingRequiredField("Name")
        }

        guard let typeProperty = properties["Typ"],
              case .select(let selectOption) = typeProperty else {
            throw MomentError.missingRequiredField("Typ")
        }

        guard let dateProperty = properties["Zeitpunkt"],
              case .date(let notionDate) = dateProperty,
              let timestamp = ISO8601DateFormatter().date(from: notionDate.start) else {
            throw MomentError.missingRequiredField("Zeitpunkt")
        }

        // Optional Relations
        var project: Project?
        if let projectProperty = properties["Projekt"],
           case .relation(let relations) = projectProperty,
           let firstRelation = relations.first {
            project = Project(id: firstRelation.id, name: "") // Name via separate fetch
        }

        var lifeArea: LifeArea?
        if let lifeAreaProperty = properties["Lebensbereich"],
           case .relation(let relations) = lifeAreaProperty,
           let firstRelation = relations.first {
            lifeArea = LifeArea(id: firstRelation.id, name: "")
        }

        return Moment(
            id: id,
            description: firstText,
            type: MomentType(rawValue: selectOption.name) ?? .gedanke,
            timestamp: timestamp,
            project: project,
            lifeArea: lifeArea
        )
    }
}
```

---

**Ende des Architektur-Dokuments**
