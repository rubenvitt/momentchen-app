# Momentchen

**Ein minimalistisches Moment-Journaling für iOS und macOS mit Notion-Integration**

Momentchen hilft dir, besondere Augenblicke deines Lebens festzuhalten und später wiederzuentdecken. Die App verbindet sich nahtlos mit Notion als Backend und nutzt Apple Intelligence für intelligente Kategorisierungsvorschläge.

---

## Features

### Momente erfassen
- **Schnelle Erfassung** — Halte Gedanken, Erlebnisse und Aktivitäten mit wenigen Taps fest
- **Intelligente Kategorisierung** — KI-gestützte Vorschläge für Typ und Kategorie (Apple Intelligence)
- **Projekte & Lebensbereiche** — Ordne Momente thematisch zu
- **Keyboard Shortcuts** — Effizientes Arbeiten mit `⌘N`, `Space`, `⌘↩`

### Rückblick
- **Zeitbasierte Reviews** — Täglich, wöchentlich, monatlich, jährlich, Lebenszeit
- **Favoriten markieren** — Die besten Momente jeder Periode hervorheben
- **Flexible Navigation** — Durch vergangene Zeiträume blättern

### Plattform
- **Multi-Platform** — Native Apps für iPhone, iPad und Mac
- **Notion-First** — Alle Daten leben in deinen Notion-Datenbanken
- **Offline-Ready** — Lokales Caching für schnelle Ladezeiten
- **Datenschutz** — KI-Inference komplett on-device

---

## Screenshots

| Moment erfassen | Rückblick | Einstellungen |
|:---------------:|:---------:|:-------------:|
| *Coming soon*   | *Coming soon* | *Coming soon* |

---

## Systemanforderungen

| Plattform | Mindestversion |
|-----------|----------------|
| iOS       | 17.0+          |
| iPadOS    | 17.0+          |
| macOS     | 14.0+          |
| Xcode     | 15.0+          |
| Swift     | 5.9+           |

**Für KI-Features:** iOS 18.0+ mit aktivierter Apple Intelligence

---

## Installation

### Voraussetzungen

1. **Notion Account** mit einer Integration
2. **Drei Notion-Datenbanken:**
   - Moments-Datenbank
   - Projects-Datenbank
   - Life Areas-Datenbank

### Notion Setup

1. Erstelle eine [Notion Integration](https://www.notion.so/my-integrations)
2. Kopiere den **Internal Integration Token**
3. Teile deine Datenbanken mit der Integration (Share → Invite)
4. Notiere die Datenbank-IDs aus den URLs

### App bauen

```bash
# Repository klonen
git clone https://github.com/yourusername/momentchen-app.git
cd momentchen-app

# In Xcode öffnen
open Momentchen/Momentchen.xcodeproj

# Oder via Command Line bauen
xcodebuild -project Momentchen/Momentchen.xcodeproj \
           -scheme Momentchen \
           -sdk iphoneos \
           build
```

### Erstkonfiguration

Beim ersten Start führt dich die App durch das Setup:

1. **Notion Token** eingeben
2. **Datenbanken auswählen** — Die App findet automatisch passende Datenbanken
3. **Fertig** — Beginne Momente zu erfassen

---

## Datenbank-Schema

### Moments-Datenbank

| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `Moment` | Title | Beschreibung des Moments |
| `Type` | Select | Gedanke, Erlebnis, Aktivität, etc. |
| `Timestamp` | Date | Zeitpunkt des Moments |
| `Project` | Relation | Verknüpfung zu Projects |
| `Life Area` | Relation | Verknüpfung zu Life Areas |
| `Daily Favorite` | Checkbox | Tagesfavorit |
| `Weekly Favorite` | Checkbox | Wochenfavorit |
| `Monthly Favorite` | Checkbox | Monatsfavorit |
| `Yearly Favorite` | Checkbox | Jahresfavorit |
| `Lifetime` | Checkbox | Lebensmoment |

### Projects-Datenbank

| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `Name` | Title | Projektname |
| `Status` | Select | Active, Completed, etc. |
| `Color` | Select | Notion-Farbe |

### Life Areas-Datenbank

| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `Name` | Title | Name des Lebensbereichs |
| `Color` | Select | Notion-Farbe |

---

## Architektur

Momentchen folgt **Clean Architecture** mit strikter Schichtentrennung:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │    Views    │  │ ViewModels  │  │     Components      │  │
│  │  (SwiftUI)  │  │(@Observable)│  │  (Reusable UI)      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    Domain Layer                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Entities   │  │    Enums    │  │      Protocols      │  │
│  │  (Structs)  │  │  (Types)    │  │    (Interfaces)     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │    DTOs     │  │   Mappers   │  │    Repositories     │  │
│  │   (JSON)    │  │ (DTO↔Domain)│  │   (Data Access)     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              NotionAPIService (Actor)                   ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                  Infrastructure Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Services   │  │  Utilities  │  │     SwiftData       │  │
│  │ (AI, Push)  │  │(Date, Color)│  │  (Local Config)     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Projektstruktur

```
Momentchen/
├── Domain/
│   ├── Entities/          # Moment, MomentType, Project, LifeArea
│   └── Models/            # ReviewSettings
├── Data/
│   ├── Network/           # NotionAPIService, RequestBuilder
│   ├── DTOs/              # NotionPageResponse, PropertyTypes
│   ├── Repositories/      # MomentType-, Project-, LifeAreaRepository
│   └── Mappers/           # Domain ↔ DTO Konvertierung
├── Infrastructure/
│   ├── Services/          # LocalAIService, NotificationManager
│   ├── AppIntents/        # Siri & Shortcuts Integration
│   └── Utilities/         # DateConverter, ColorMapper, HapticManager
└── Presentation/
    ├── ViewModels/        # MomentForm-, MomentList-, ReviewModeViewModel
    └── Views/
        ├── Components/    # CategoryPicker, FlowLayout, ParticleEffect
        └── *.swift        # Main Views
```

---

## Technologie-Stack

| Technologie | Verwendung |
|-------------|------------|
| **SwiftUI** | Deklarative UI |
| **SwiftData** | Lokale Konfiguration & Caching |
| **Notion API** | Remote-Datenspeicher |
| **FoundationModels** | On-Device KI (iOS 18+) |
| **AppIntents** | Siri & Shortcuts |
| **OSLog** | Strukturiertes Logging |

**Keine externen Abhängigkeiten** — Nur Apple-Frameworks

---

## Keyboard Shortcuts

| Shortcut | Aktion |
|----------|--------|
| `⌘ 1` | Momente-Tab |
| `⌘ 2` | Reviews-Tab |
| `⌘ N` | Neuer Moment |
| `Space` | Neuer Moment (Schnellzugriff) |
| `⌘ R` | Aktualisieren |
| `⌘ ,` | Einstellungen |
| `⌘ ↩` | Moment speichern |
| `Esc` | Abbrechen |
| `← / →` | Vorheriger/Nächster Zeitraum |

---

## Entwicklung

### Tests ausführen

```bash
# Unit Tests
xcodebuild test \
    -project Momentchen/Momentchen.xcodeproj \
    -scheme Momentchen \
    -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Projekt-Konventionen

- **Concurrency:** Alle Typen sind `Sendable`
- **API Service:** Actor-basiert für Thread-Sicherheit
- **ViewModels:** `@Observable` statt `@StateObject`
- **Fehlerbehandlung:** Lokalisierte Fehlermeldungen (Deutsch)
- **Caching:** 24h TTL für Katalogdaten

### Beitragen

1. Fork erstellen
2. Feature Branch (`git checkout -b feature/amazing-feature`)
3. Änderungen committen (`git commit -m 'Add amazing feature'`)
4. Branch pushen (`git push origin feature/amazing-feature`)
5. Pull Request öffnen

---

## Roadmap

- [ ] Widget-Support für iOS & macOS
- [ ] Watch-App für schnelle Erfassung
- [ ] iCloud Sync für Konfiguration
- [ ] Export-Funktion (JSON, CSV)
- [ ] Erweiterte Statistiken
- [ ] Notion-Template für einfaches Setup

---

## Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert — siehe [LICENSE](LICENSE) für Details.

---

## Danksagung

- Inspiriert von der Notion-Community
- Gebaut mit SwiftUI und viel ☕

---

<p align="center">
  <sub>Mit Liebe in Deutschland entwickelt</sub>
</p>
