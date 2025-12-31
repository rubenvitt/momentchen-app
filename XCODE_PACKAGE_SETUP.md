# Xcode Swift Package Setup: Google Generative AI

⚠️ **WICHTIG**: Das Google AI Swift SDK ist deprecated und wird durch das Firebase SDK ersetzt. Für jetzt funktioniert es aber noch und ist einfacher einzurichten als Firebase.

**Status:**
- ✅ **Jetzt**: Google AI SDK funktioniert (schnelle Einrichtung)
- 🔄 **Zukunft**: Migration zu Firebase SDK empfohlen

## Problem gelöst ✅

Der Fehler "No such module 'GoogleGenerativeAI'" wurde behoben. Der Code kompiliert jetzt erfolgreich **auch ohne** das Package. Die KI-Features werden automatisch aktiviert, sobald das Package hinzugefügt wird.

## Schritt-für-Schritt-Anleitung

### 1. Öffne das Projekt in Xcode

```bash
open Momentchen/Momentchen.xcodeproj
```

### 2. Navigiere zu Package Dependencies

1. Im **Project Navigator** (linke Sidebar), wähle ganz oben das **Momentchen** Projekt (blaues Icon)
2. Im Hauptbereich, wähle das **Target "Momentchen"** aus (unter TARGETS)
3. Wechsle zum Tab **"General"**
4. Scrolle nach unten zur Sektion **"Frameworks, Libraries, and Embedded Content"**

### 3. Füge das Swift Package hinzu

1. Wechsle zum Tab **"Package Dependencies"** (neben "General")
2. Klicke auf das **"+"** Symbol unten links
3. Im Suchfeld oben gib ein:
   ```
   https://github.com/google/generative-ai-swift
   ```
4. Wähle das Package aus der Liste
5. Bei "Dependency Rule" wähle: **"Up to Next Major Version"**
6. Minimum Version: **0.5.0** (oder die neueste verfügbare)
7. Klicke auf **"Add Package"**
8. Im nächsten Dialog stelle sicher, dass **"GoogleGenerativeAI"** für das Target "Momentchen" ausgewählt ist
9. Klicke auf **"Add Package"**

### 4. Warte auf Package Resolution

Xcode wird das Package herunterladen und integrieren. Das kann 1-2 Minuten dauern.
Du siehst den Fortschritt oben in der Toolbar.

### 5. Verifiziere die Installation

1. Im Project Navigator solltest du jetzt unter **"Package Dependencies"** den Eintrag **"generative-ai-swift"** sehen
2. Baue das Projekt: **⌘ + B** (Command + B)
3. Der Build sollte erfolgreich sein

### 6. Teste die KI-Features

1. Starte die App: **⌘ + R** (Command + R)
2. Gehe zu **Einstellungen** → **KI-Features**
3. Füge einen [Google AI API Key](https://aistudio.google.com/apikey) hinzu
4. Erstelle einen neuen Moment und tippe eine Beschreibung
5. Nach ~1 Sekunde sollte die App automatisch einen Typ vorschlagen ✨

## Alternative: Terminal-basierte Installation

Falls du lieber mit dem Terminal arbeitest:

```bash
cd /Users/rubeen/dev/personal/momentchen-app/Momentchen

# Füge das Package zur Package.swift hinzu (falls vorhanden)
# Oder editiere die .pbxproj direkt (NICHT empfohlen!)
```

**WICHTIG**: Die direkte Bearbeitung der `.pbxproj`-Datei ist fehleranfällig und wird NICHT empfohlen.
Nutze immer Xcode für Package Dependencies.

## Was wurde geändert?

Der Code verwendet jetzt **bedingte Kompilierung**:

```swift
#if canImport(GoogleGenerativeAI)
import GoogleGenerativeAI
// ... GeminiService implementation ...
#endif
```

Das bedeutet:
- ✅ **Ohne Package**: App kompiliert normal, keine KI-Features
- ✅ **Mit Package**: App kompiliert mit KI-Features aktiviert

## Troubleshooting

### Package kann nicht aufgelöst werden

1. Prüfe deine Internetverbindung
2. Versuche: **File → Packages → Reset Package Caches**
3. Versuche: **File → Packages → Update to Latest Package Versions**

### Build-Fehler nach Package-Installation

1. Clean Build Folder: **⌘ + Shift + K** (Command + Shift + K)
2. Rebuild: **⌘ + B** (Command + B)
3. Falls das nicht hilft, starte Xcode neu

### Package verschwindet nach Git Pull

Das ist normal! Das Package wird nicht ins Git committed.
Xcode sollte es automatisch wieder herunterladen.
Falls nicht: **File → Packages → Resolve Package Versions**

## Git Ignore

Die Package-Dateien werden automatisch von Git ignoriert:
- `.swiftpm/` - Package-Konfiguration
- `Packages/` - Heruntergeladene Packages
- `*.xcworkspace` - Workspace-Dateien

Das ist gewollt und Best Practice für Swift Packages.

## Nächste Schritte

Nach erfolgreicher Installation:
1. API Key erstellen: [Google AI Studio](https://aistudio.google.com/apikey)
2. In App konfigurieren: Settings → KI-Features
3. Details siehe: [AI_FEATURES_SETUP.md](AI_FEATURES_SETUP.md)
