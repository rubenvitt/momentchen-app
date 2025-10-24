# Momentchen Raycast Extension - Quickstart

## Schritt 1: Dependencies installieren

```bash
cd raycast
npm install
```

## Schritt 2: Icon erstellen (vorübergehend)

Du benötigst ein `icon.png` (512x512 Pixel) im `raycast/` Verzeichnis.

**Schnelle Lösung für Testing:**
1. Gehe zu https://www.flaticon.com/ oder https://icon.kitchen/
2. Suche nach "star" oder "moment" oder "clock"
3. Lade ein 512x512 PNG herunter
4. Benenne es um in `icon.png` und platziere es in `raycast/`

Siehe `ICON_INSTRUCTIONS.md` für mehr Details.

## Schritt 3: Notion Integration einrichten

### 3.1 Notion Integration erstellen

1. Gehe zu https://www.notion.so/my-integrations
2. Klicke auf "+ New integration"
3. Gib einen Namen ein (z.B. "Momentchen Raycast")
4. Wähle den Workspace aus
5. Kopiere den **Internal Integration Token** (beginnt mit `secret_...`)

### 3.2 Datenbank verbinden

1. Öffne deine Momentchen-Datenbank in Notion
2. Klicke oben rechts auf "..." → "Add connections"
3. Wähle deine neue Integration aus

### 3.3 Datenbank-ID finden

Die Datenbank-ID findest du in der URL deiner Datenbank:
```
https://www.notion.so/[workspace]/[DATABASE_ID]?v=...
```

Beispiel:
```
https://www.notion.so/myworkspace/a418cfda28da4e9887f83df10a92d7f6?v=...
                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                                 Das ist die Database ID
```

## Schritt 4: Extension in Raycast testen

```bash
npm run dev
```

Dies öffnet die Raycast-Entwicklungsumgebung. Du wirst aufgefordert:
1. **Notion Integration Token** einzugeben (aus Schritt 3.1)
2. **Moments Database ID** einzugeben (aus Schritt 3.3)

## Schritt 5: Commands nutzen

Nach der Konfiguration kannst du in Raycast:

1. **"Create Moment"** suchen - um ein neues Moment anzulegen
   - Beschreibung eingeben
   - Typ auswählen (learning, improvement, feeling, etc.)
   - Optional: Projekt oder Lebensbereich zuweisen
   - Favoriten werden später während Reviews gesetzt
2. **"Search Moments"** suchen - um deine Momente zu durchsuchen
   - Filter nach Typ und Favoriten
   - Siehe Projekt/Lebensbereich Icons (📁/🌱)
   - Cmd+R zum Aktualisieren

## Troubleshooting

### Fehler: "Notion API Error: Unauthorized"
- Stelle sicher, dass der Integration Token korrekt ist
- Überprüfe, dass die Integration mit der Datenbank verbunden ist

### Fehler: "Database not found"
- Überprüfe die Database ID
- Stelle sicher, dass die Integration Zugriff auf die Datenbank hat

### Extension erscheint nicht in Raycast
- Stelle sicher, dass `npm run dev` läuft
- Öffne Raycast neu (Cmd+R)
- Überprüfe, dass alle Dependencies installiert sind

### Problem: Projekte/Lebensbereiche zeigen nur "Untitled"
- **Lösung**: Die Extension cached die Daten. So behebst du das:
  1. Öffne "Create Moment" in Raycast
  2. Warte, bis das Form geladen ist
  3. Schließe und öffne das Form erneut
  4. Die Namen sollten jetzt korrekt angezeigt werden
- **Alternative**: Raycast komplett neu starten (Cmd+Q, dann neu öffnen)

## Nächste Schritte

1. **Testen**: Erstelle ein paar Test-Momente
2. **Anpassen**: Passe die Moment-Typen in `create-moment.tsx` an deine Bedürfnisse an
3. **Veröffentlichen**: Wenn alles funktioniert, kannst du mit `npm run build` und `npm run publish` die Extension veröffentlichen

## Tipps

- **Keyboard Shortcuts**: Füge in Raycast Preferences eigene Shortcuts für die Commands hinzu
  - `Cmd+R` - Daten von Notion aktualisieren
  - `Cmd+Shift+C` - Cache Management öffnen
- **Filter**: In Search Moments kannst du nach Typ und Favoriten filtern
- **Integration**: Die Extension nutzt dieselbe Notion-Datenbank wie die iOS App
- **Caching**: Die Extension cached Momente für 5 Minuten - siehe `CACHING.md` für Details
- **Offline-Modus**: Gecachte Momente sind auch ohne Internet verfügbar

## Support

Bei Fragen oder Problemen:
1. Überprüfe die Raycast Logs (Raycast → Preferences → Advanced → Open Extension Logs)
2. Stelle sicher, dass die Notion-Datenbank die korrekten Properties hat (siehe README.md)
3. Überprüfe die Notion API-Dokumentation: https://developers.notion.com/
