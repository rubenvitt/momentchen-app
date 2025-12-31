# KI-gestützte Typ-Erkennung für Momentchen

## Übersicht

Die App kann jetzt automatisch den passenden Moment-Typ (Gedanke, Erlebnis, Aktivität, etc.) basierend auf der Beschreibung vorschlagen. Diese Funktion nutzt Google Gemini AI.

## Schnellstart

⚠️ **WICHTIG**: Das Google Generative AI Swift Package muss erst in Xcode hinzugefügt werden!

👉 **[Folge dieser Anleitung zum Hinzufügen des Packages](XCODE_PACKAGE_SETUP.md)**

Nach dem Package-Setup, fahre mit den unteren Schritten fort.

## Setup-Anleitung

### 1. Google Generative AI SDK hinzufügen

✅ Das SDK wurde bereits als optionale Dependency konfiguriert.
📖 Siehe: **[XCODE_PACKAGE_SETUP.md](XCODE_PACKAGE_SETUP.md)** für detaillierte Installationsanweisungen.

Kurzversion:

1. Öffne das Projekt in Xcode: `open Momentchen/Momentchen.xcodeproj`
2. Wähle im Project Navigator das Projekt "Momentchen" aus
3. Wähle das Target "Momentchen" aus
4. Gehe zum Tab "Package Dependencies"
5. Klicke auf das "+" Symbol unten links
6. Füge folgende URL hinzu: `https://github.com/google/generative-ai-swift`
7. Wähle "Up to Next Major Version" mit Minimum "0.5.0"
8. Klicke auf "Add Package"

### 2. Google AI API Key erstellen

1. Besuche [Google AI Studio](https://aistudio.google.com/apikey)
2. Melde dich mit deinem Google-Konto an
3. Klicke auf "Create API Key"
4. Kopiere den generierten API Key

### 3. API Key in der App konfigurieren

1. Öffne die Momentchen App
2. Gehe zu Einstellungen (⚙️)
3. Scrolle zur Sektion "KI-Features"
4. Klicke auf "Hinzufügen"
5. Füge deinen API Key ein
6. Klicke auf "Speichern"

## Verwendung

Sobald der API Key konfiguriert ist:

1. Erstelle einen neuen Moment
2. Gib eine Beschreibung ein (z.B. "Spaziergang im Park")
3. Nach ca. 0.8 Sekunden schlägt die KI automatisch einen passenden Typ vor
4. Der vorgeschlagene Typ wird mit einem ✨ "KI-Vorschlag" Label markiert
5. Du kannst den Vorschlag akzeptieren oder manuell einen anderen Typ wählen

## Technische Details

### Architektur

- **GeminiService**: Service-Layer für die Kommunikation mit Google AI
  - Pfad: `Momentchen/Infrastructure/Services/GeminiService.swift`
  - Nutzt das Gemini 2.0 Flash Modell
  - Konfiguriert mit niedriger Temperature (0.3) für konsistente Ergebnisse

- **MomentFormViewModel**: Integration der KI-Inferenz
  - Automatisches Debouncing (0.8s) um API-Aufrufe zu minimieren
  - Nur Inferenz wenn kein Typ ausgewählt ist
  - Optionales Feature - funktioniert auch ohne API Key

- **MomentFormView**: UI-Feedback
  - ProgressView während der Inferenz
  - "KI-Vorschlag" Label für vorgeschlagene Typen
  - Manuelle Auswahl überschreibt KI-Vorschlag

### Datenmodell-Änderungen

**AppConfiguration.swift**:
```swift
var googleAiApiKey: String?  // Neu hinzugefügt
```

### Sicherheit

- API Key wird in SwiftData gespeichert (lokale Datenbank)
- Für Produktions-Apps wird empfohlen, den Key im Keychain zu speichern
- API Key wird nie in Logs ausgegeben

## Kosten

Google AI Studio bietet:
- **Kostenlos**: 15 Anfragen pro Minute, 1500 Anfragen pro Tag
- Für typische Nutzung der App sollte das kostenlose Kontingent ausreichen
- Bei höherem Bedarf: [Pricing Details](https://ai.google.dev/pricing)

## Fehlerbehebung

### "Keine Typ-Vorschläge"
- Prüfe, ob der API Key korrekt eingegeben wurde
- Prüfe deine Internetverbindung
- Prüfe das Google AI Studio Dashboard auf API-Limits

### "Compilation Error: Cannot find 'GoogleGenerativeAI'"
- Stelle sicher, dass das Swift Package korrekt hinzugefügt wurde
- Rebuild das Projekt (⌘ + Shift + K, dann ⌘ + B)

### API Key wurde versehentlich committed
- Entferne den Key aus der Datenbank (Settings → KI-Features → Entfernen)
- Der Key wird nur lokal gespeichert, nicht im Git Repository

## Deaktivierung

Um die KI-Features zu deaktivieren:
1. Gehe zu Einstellungen
2. Sektion "KI-Features"
3. Klicke auf "API Key entfernen"

Die App funktioniert weiterhin normal, Typ-Vorschläge werden dann nicht mehr gemacht.
