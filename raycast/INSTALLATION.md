# Momentchen Extension Installation

## Voraussetzungen

1. **Raycast installiert** (https://raycast.com)
2. **Node.js** installiert (Version 16 oder höher)
3. Die Extension heruntergeladen/geklont

## Installation Schritt-für-Schritt

### Schritt 1: Dependencies installieren

Öffne ein Terminal und navigiere zum Extension-Ordner:

```bash
cd /Users/rubeen/dev/personal/momentchen-app/raycast
npm install
```

Dies installiert alle benötigten Pakete (~1-2 Minuten).

### Schritt 2: Extension in Raycast laden

Es gibt zwei Methoden:

#### Methode A: Development Mode (Empfohlen für Entwicklung)

1. **Terminal öffnen** im `raycast/` Ordner
2. **Development Mode starten**:
   ```bash
   npm run dev
   ```
3. **Raycast öffnet sich automatisch** und zeigt eine Benachrichtigung
4. Die Extension ist jetzt verfügbar!

**Vorteile**:
- Änderungen werden automatisch geladen
- Gut zum Testen
- Einfaches Debugging

**Nachteile**:
- Terminal muss offen bleiben
- `npm run dev` muss laufen

#### Methode B: Import in Raycast (Für produktive Nutzung)

1. **Build erstellen**:
   ```bash
   npm run build
   ```

2. **Raycast öffnen** (Cmd+Space oder dein Hotkey)

3. **Extensions öffnen**:
   - Suche nach "Import Extension"
   - Oder: Raycast → Preferences → Extensions → "+" (unten links) → "Import Extension"

4. **Extension-Ordner auswählen**:
   - Navigiere zu `/Users/rubeen/dev/personal/momentchen-app/raycast`
   - Wähle den `raycast` Ordner aus
   - Klicke "Import"

5. **Fertig!** Die Extension ist jetzt dauerhaft installiert

**Vorteile**:
- Läuft permanent
- Kein Terminal nötig
- Schnellerer Start

**Nachteile**:
- Bei Änderungen muss neu gebaut und reimportiert werden

## Schritt 3: Extension konfigurieren

Beim ersten Start wirst du nach zwei Dingen gefragt:

### 1. Notion Integration Token

1. Gehe zu https://www.notion.so/my-integrations
2. Klicke "+ New integration"
3. Name: "Momentchen Raycast"
4. Wähle deinen Workspace
5. **Kopiere den Token** (beginnt mit `secret_...`)
6. Füge ihn in Raycast ein

### 2. Moments Database ID

1. Öffne deine Momente-Datenbank in Notion
2. Kopiere die ID aus der URL:
   ```
   https://www.notion.so/workspace/[DATABASE_ID]?v=...
                                   ^^^^^^^^^^^^^^^^
   ```
3. Füge die ID in Raycast ein

### 3. Datenbank mit Integration verbinden

**Wichtig!** Du musst noch deine Datenbanken mit der Integration verbinden:

1. **Momente-Datenbank** öffnen in Notion
2. Oben rechts: "..." → "Add connections"
3. Deine Integration auswählen
4. Bestätigen

Wiederhole das für:
- **Projekte-Datenbank** (falls vorhanden)
- **Lebensbereiche-Datenbank** (falls vorhanden)

## Schritt 4: Testen

1. **Raycast öffnen** (Cmd+Space)
2. Suche nach **"Create Moment"**
3. Fülle das Formular aus
4. Erstelle einen Test-Moment
5. Suche nach **"Search Moments"**
6. Dein Moment sollte erscheinen! ✅

## Troubleshooting

### "Extension not found" Fehler

**Problem**: Raycast findet die Extension nicht

**Lösung**:
1. Stelle sicher, dass `npm install` erfolgreich war
2. Überprüfe, dass `package.json` im Ordner existiert
3. Bei Methode A: Stelle sicher, dass `npm run dev` läuft
4. Bei Methode B: Stelle sicher, dass `npm run build` erfolgreich war

### "Dependencies not found" Fehler

**Problem**: Module fehlen

**Lösung**:
```bash
cd raycast
rm -rf node_modules
npm install
```

### Icon fehlt

**Problem**: Extension zeigt kein Icon

**Lösung**:
- Du brauchst ein `icon.png` (512x512) im `raycast/` Ordner
- Siehe `ICON_INSTRUCTIONS.md` für Details
- Die Extension funktioniert auch ohne Icon (zeigt nur Platzhalter)

### "Notion API Error: Unauthorized"

**Problem**: Token ist falsch oder ungültig

**Lösung**:
1. Gehe zu Raycast → Preferences → Extensions → Momentchen
2. Überprüfe den Token
3. Erstelle ggf. einen neuen Token in Notion
4. Stelle sicher, dass die Datenbanken mit der Integration verbunden sind

### Projekte/Lebensbereiche werden nicht geladen

**Problem**: Dropdown bleibt leer

**Lösung**:
1. Stelle sicher, dass die Relations in der Momente-Datenbank korrekt sind
2. Verbinde die Projekte/Lebensbereiche-Datenbanken mit der Integration
3. Setze "In Bearbeitung" Checkbox für aktive Projekte
4. Warte 1 Minute (Cache) und lade neu

## Development Workflow

### Während der Entwicklung

1. **Änderungen machen** an den Dateien in `src/`
2. **Automatisches Reload**:
   - Im Development Mode (`npm run dev`) werden Änderungen automatisch geladen
   - Raycast zeigt eine Benachrichtigung

### Build für Produktion

```bash
# Build erstellen
npm run build

# Linting
npm run lint

# Linting mit Auto-Fix
npm run fix-lint
```

### Extension aktualisieren

Nach Änderungen:

**Development Mode**:
- Änderungen werden automatisch geladen
- Ggf. Raycast neu öffnen (Cmd+R in Raycast)

**Importierte Extension**:
```bash
npm run build
```
Dann in Raycast: Extensions → Momentchen → "Reload Extension"

## Deinstallation

### Development Mode beenden

```bash
# Im Terminal: Strg+C
# Oder Terminal schließen
```

### Extension entfernen

1. Raycast öffnen
2. Preferences → Extensions
3. Momentchen finden
4. Rechtsklick → "Uninstall Extension"
5. Bestätigen

## Nächste Schritte

Nach erfolgreicher Installation:

1. **Teste die Extension** mit ein paar Momenten
2. **Passe Moment-Typen an** in `src/commands/create-moment.tsx`
3. **Füge Keyboard Shortcuts hinzu** in Raycast Preferences
4. **Setze Projekte/Lebensbereiche auf** in Notion
5. **Nutze die Extension täglich!** 🎉

## Support

Bei Problemen:
1. Überprüfe die Raycast Logs: Preferences → Advanced → "Open Extension Logs"
2. Schaue in die anderen Docs: `README.md`, `QUICKSTART.md`, `NOTION_SETUP.md`
3. Überprüfe die Terminal-Ausgabe (bei `npm run dev`)

## Tipps

- **Keyboard Shortcuts**: Erstelle globale Shortcuts für schnellen Zugriff
  - Raycast Preferences → Extensions → Momentchen → Commands → Shortcut setzen
  - Beispiel: Cmd+Shift+M für "Create Moment"

- **Favoriten**: Pinne häufig genutzte Commands an Raycast Root
  - In Raycast: Command suchen → Cmd+Shift+P

- **Alias**: Erstelle kurze Aliase
  - In Raycast: Command suchen → Cmd+Shift+A
  - Beispiel: "cm" für "Create Moment"
