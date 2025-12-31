# Debugging: Warum funktioniert die KI-Typ-Erkennung nicht?

## Schnell-Checkliste ✅

Die KI-Typ-Erkennung funktioniert nur wenn **ALLE** diese Bedingungen erfüllt sind:

1. ✅ **Google Generative AI Package installiert** (in Xcode)
2. ✅ **Google AI API Key konfiguriert** (in App → Einstellungen)
3. ✅ **Kein Typ bereits ausgewählt** (die KI schlägt nur vor, wenn leer)
4. ✅ **Titel ist nicht leer** (mindestens 1 Zeichen)
5. ✅ **Moment-Typen geladen** (aus Notion)

## Schritt-für-Schritt Debugging

### Schritt 1: Package installiert?

**Prüfen:**
```bash
cd /Users/rubeen/dev/personal/momentchen-app/Momentchen
open Momentchen.xcodeproj
```

In Xcode:
- Project Navigator → Projekt "Momentchen" → Target "Momentchen"
- Tab **"Package Dependencies"**
- Solltest du sehen: **"generative-ai-swift"**

**Nicht da?** → [Package Installation](XCODE_PACKAGE_SETUP.md)

### Schritt 2: API Key konfiguriert?

**Prüfen:**
1. Starte die App in Xcode (⌘ + R)
2. Öffne **Einstellungen** (⚙️ Icon)
3. Scrolle zu **"KI-Features"**
4. Status sollte sein: ✅ **"Konfiguriert"**

**Nicht konfiguriert?**
1. Erstelle API Key: https://aistudio.google.com/apikey
2. In App: Einstellungen → KI-Features → "Hinzufügen"
3. API Key einfügen und "Speichern"

### Schritt 3: Console Logs checken

Die App gibt jetzt detaillierte Logs aus!

**Console öffnen in Xcode:**
1. App im Simulator/Gerät starten (⌘ + R)
2. Unten rechts: **"Show/Hide Debug Area"** (⌘ + Shift + Y)
3. Im Debug-Bereich solltest du die Console sehen

**Neuen Moment erstellen:**
1. In der App: **"+" Button** drücken
2. Anfangen zu tippen: z.B. "Spaziergang im Park"
3. **Warte 1.2 Sekunden** nach dem letzten Buchstaben
4. Beobachte die Console!

### Schritt 4: Console Logs interpretieren

**Erwartete Logs bei ERFOLGREICHER Inferenz:**
```
🔍 AI Inference Check:
  - Has Gemini Service: true
  - Selected Type: none
  - Title: "Spaziergang im Park"
  - Available Types: 6
  ✅ Starting inference task...
  🤖 Calling Gemini API...
  ✨ AI suggested: Aktivität
```

**Mögliche Probleme:**

#### Problem 1: "Has Gemini Service: false"
```
🔍 AI Inference Check:
  - Has Gemini Service: false   ← Problem!
```
**Lösung:**
- Package nicht installiert → [Schritt 1](#schritt-1-package-installiert)
- API Key fehlt → [Schritt 2](#schritt-2-api-key-konfiguriert)

#### Problem 2: "Selected Type: Gedanke"
```
🔍 AI Inference Check:
  - Selected Type: Gedanke   ← Problem!
  ❌ Preconditions not met
```
**Lösung:**
Die KI schlägt nur vor, wenn **KEIN** Typ ausgewählt ist.
- Lösche den ausgewählten Typ bevor du tippst
- Oder: Lösche das Titel-Feld und tippe neu

#### Problem 3: "Available Types: 0"
```
🔍 AI Inference Check:
  - Available Types: 0   ← Problem!
```
**Lösung:**
Die Notion-Typen wurden nicht geladen.
- Prüfe deine Notion-Verbindung
- Prüfe deine Internetverbindung
- Starte die App neu

#### Problem 4: "Inference cancelled (user still typing)"
```
  ⏭️ Inference cancelled (user still typing)
```
**Das ist NORMAL!**
Die App wartet 1.2 Sekunden nach dem letzten Buchstaben.
Wenn du weiter tippst, wird die alte Anfrage abgebrochen.
→ **Einfach aufhören zu tippen und 1.2 Sekunden warten!**

#### Problem 5: API Fehler
```
  ❌ AI inference failed: <Fehlermeldung>
```
**Mögliche Ursachen:**
- **Ungültiger API Key:** Prüfe den Key in den Einstellungen
- **API Limit erreicht:** Free Tier hat 15 Anfragen/Minute
- **Keine Internetverbindung:** Prüfe WiFi/Mobile Data
- **Gemini API down:** Prüfe https://status.cloud.google.com/

### Schritt 5: UI Feedback beobachten

Während die KI läuft, solltest du sehen:

1. **Während der Inferenz:**
   ```
   Typ  [⚙️ ProgressView]
   ```

2. **Nach der Inferenz:**
   ```
   Typ  [✨ KI-Vorschlag]
   [Aktivität] ← Vorgeschlagener Typ ist ausgewählt
   ```

**Siehst du das ProgressView?**
- ✅ Ja → KI läuft, warte auf Ergebnis
- ❌ Nein → KI wurde nicht getriggert, siehe Console Logs

## Häufige Fehler

### "Ich sehe keine Logs!"

**Xcode Console Filter:**
1. Unten in der Console ist ein Suchfeld
2. Stelle sicher, dass es **LEER** ist
3. Rechts davon: Filter-Buttons - alle sollten aktiviert sein

### "Es passiert nichts wenn ich tippe"

**Checkliste:**
1. Hast du **mindestens 1.2 Sekunden** gewartet?
2. Ist ein Typ **bereits ausgewählt**? (dann macht die KI nichts)
3. Siehst du Logs in der Console? (wenn nein → Package fehlt)

### "Die KI schlägt immer den falschen Typ vor"

Das ist möglich! Die KI ist nicht perfekt.
**Wichtig:** Du kannst den Vorschlag einfach überschreiben durch:
- Klick auf einen anderen Typ
- Das ✨ "KI-Vorschlag" Label verschwindet dann

### "Nach dem Überschreiben macht die KI nochmal einen Vorschlag"

**Das ist ein Bug!** Die KI sollte nicht nochmal vorschlagen, wenn du manuell ausgewählt hast.

Workaround:
- Wähle zuerst den Typ
- Dann tippe den Titel

## Logs für Support

Falls du immer noch Probleme hast, sammle diese Infos:

1. **Xcode Console Output** (komplette Logs kopieren)
2. **App Version:** Einstellungen → Über → Version
3. **Package installiert?** Ja/Nein
4. **API Key gesetzt?** Ja/Nein
5. **Test-Beschreibung:** Was hast du getippt?
6. **Was erwartet:** Welcher Typ sollte vorgeschlagen werden?
7. **Was passiert:** Was siehst du stattdessen?

## Quick Fix: Neu starten

Manchmal hilft ein kompletter Neustart:

```bash
# 1. Xcode beenden
# 2. Simulator beenden
# 3. Terminal:
cd /Users/rubeen/dev/personal/momentchen-app/Momentchen
rm -rf ~/Library/Developer/Xcode/DerivedData/Momentchen-*

# 4. Xcode neu öffnen
open Momentchen.xcodeproj

# 5. Clean Build: ⌘ + Shift + K
# 6. Build: ⌘ + B
# 7. Run: ⌘ + R
```

## Noch Fragen?

Die Logs sollten dir zeigen, was das Problem ist!
Wenn nicht, teile die Console-Ausgabe für weitere Hilfe.
