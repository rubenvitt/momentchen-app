# Notion Setup für Momentchen

## Datenbank-Struktur

Die Momentchen Extension benötigt eine spezifische Datenbank-Struktur in Notion.

## 1. Hauptdatenbank: Momente

Deine Hauptdatenbank sollte folgende Properties haben:

| Property Name | Type | Beschreibung |
|---------------|------|--------------|
| **Name** | Title | Beschreibung des Moments (PFLICHT) |
| **Zeitpunkt** | Date | Wann das Moment passiert ist (PFLICHT) |
| **Typ** | Select | Art des Moments (learning, improvement, feeling, miss, etc.) (PFLICHT) |
| **Projekt** | Relation | Verknüpfung zur Projekte-Datenbank (OPTIONAL) |
| **Lebensbereich** | Relation | Verknüpfung zur Lebensbereiche-Datenbank (OPTIONAL) |
| **⭐ Tagesfavorit** | Checkbox | Tagesfavorit-Marker |
| **⭐ Wochenfavorit** | Checkbox | Wochenfavorit-Marker |
| **⭐ Monatsfavorit** | Checkbox | Monatsfavorit-Marker |
| **⭐ Jahresfavorit** | Checkbox | Jahresfavorit-Marker |
| **Moment meines Lebens** | Checkbox | Lebensmoment-Marker |
| **Relevantester Favorit** | Formula | Berechnet höchsten Favoriten-Status (OPTIONAL) |

## 2. Optional: Projekte-Datenbank

Wenn du Momente Projekten zuordnen möchtest:

1. **Neue Datenbank erstellen**:
   - Name: "Projekte" (oder ein anderer Name)
   - Füge ein Title-Property hinzu (z.B. "Name", "Projektname", "Title")

2. **Properties**:
   - Mindestens eine **Title-Property** (für den Namen des Projekts)
   - **Optional - Aktiv-Property** (für Filterung):
     - **"In Bearbeitung"** (Checkbox): Nur aktivierte (✓) Projekte werden angezeigt
     - **"Status"** (Select): Mit Option "Active" oder "Aktiv" - nur diese werden angezeigt
     - **"Status"** (Checkbox): Nur aktivierte (✓) Projekte werden angezeigt
     - Ohne diese Properties: Alle nicht-archivierten Projekte werden angezeigt
   - Optional: Beschreibung, Zeitraum, etc.

3. **In Momente-Datenbank verlinken**:
   - Füge eine **Relation-Property** namens "Projekt" hinzu
   - Verlinke sie mit der Projekte-Datenbank

4. **Beispiel-Einträge**:
   ```
   - Momentchen App
   - Website Relaunch
   - Lernen: Swift
   - Buch schreiben
   ```

## 3. Optional: Lebensbereiche-Datenbank

Wenn du Momente Lebensbereichen zuordnen möchtest:

1. **Neue Datenbank erstellen**:
   - Name: "Lebensbereiche" (oder ein anderer Name)
   - Füge ein Title-Property hinzu (z.B. "Name", "Bereich", "Title")

2. **Properties**:
   - Mindestens eine **Title-Property** (für den Namen des Lebensbereichs)
   - **Optional - Aktiv-Property** (für Filterung):
     - **"In Bearbeitung"** (Checkbox): Nur aktivierte (✓) Bereiche werden angezeigt
     - **"Status"** (Select): Mit Option "Active" oder "Aktiv" - nur diese werden angezeigt
     - **"Status"** (Checkbox): Nur aktivierte (✓) Bereiche werden angezeigt
     - Ohne diese Properties: Alle nicht-archivierten Bereiche werden angezeigt
   - Optional: Beschreibung, Farbe, Priorität, etc.

3. **In Momente-Datenbank verlinken**:
   - Füge eine **Relation-Property** namens "Lebensbereich" hinzu
   - Verlinke sie mit der Lebensbereiche-Datenbank

4. **Beispiel-Einträge**:
   ```
   - Karriere
   - Familie
   - Gesundheit
   - Persönliche Entwicklung
   - Hobbies
   ```

## 4. Integration einrichten

### 4.1 Notion Integration erstellen

1. Gehe zu https://www.notion.so/my-integrations
2. Klicke auf "+ New integration"
3. Gib einen Namen ein (z.B. "Momentchen Raycast")
4. Wähle den Workspace aus
5. **Wichtig**: Unter "Capabilities" stelle sicher, dass:
   - ✅ Read content
   - ✅ Update content
   - ✅ Insert content
   aktiviert sind
6. Kopiere den **Internal Integration Token**

### 4.2 Datenbanken mit Integration verbinden

**Für jede Datenbank** (Momente, Projekte, Lebensbereiche):

1. Öffne die Datenbank in Notion
2. Klicke oben rechts auf "..." (Drei Punkte)
3. Wähle "Add connections"
4. Wähle deine Integration aus
5. Bestätige mit "Confirm"

⚠️ **Wichtig**: Alle drei Datenbanken müssen mit der Integration verbunden sein!

## 5. Datenbank-IDs finden

Die Datenbank-ID findest du in der URL:

```
https://www.notion.so/[workspace]/[DATABASE_ID]?v=...
                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                                 Das ist die Database ID (32 Zeichen)
```

**Beispiel**:
```
https://www.notion.so/myworkspace/a418cfda28da4e9887f83df10a92d7f6?v=xyz
                                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                                  a418cfda28da4e9887f83df10a92d7f6
```

Nur die **Momente-Datenbank-ID** wird in der Raycast Extension konfiguriert. Die Projekte und Lebensbereiche werden automatisch über die Relations gefunden.

## Troubleshooting

### Projekte/Lebensbereiche werden nicht geladen

**Problem**: Die Dropdowns bleiben leer oder zeigen nur "Keine Projekte verfügbar"

**Lösungen**:
1. ✅ Stelle sicher, dass die Projekte/Lebensbereiche-Datenbanken mit der Integration verbunden sind
2. ✅ Überprüfe, dass die Relation-Properties in der Momente-Datenbank korrekt eingerichtet sind
3. ✅ Die Datenbanken sollten mindestens einen Eintrag haben
4. ✅ Jede Datenbank muss eine Title-Property haben (der Name ist egal)

### "Untitled" statt echten Namen

**Problem**: Alle Einträge heißen "Untitled"

**Ursache**: Die Title-Property ist leer oder nicht richtig gesetzt

**Lösung**:
1. Öffne die Projekte/Lebensbereiche-Datenbank in Notion
2. Stelle sicher, dass jeder Eintrag einen Namen in der Title-Property hat
3. Warte 1-2 Minuten (Cache-Zeit)
4. Öffne die Raycast Extension erneut

### Keine Relations verfügbar

**Problem**: Die Relation-Dropdown zeigt keine Optionen

**Lösung**:
1. Überprüfe in Notion:
   - Momente-Datenbank → "Projekt" Property → "Edit property"
   - Ist die Relation zur richtigen Datenbank verlinkt?
2. In der verlinkten Datenbank:
   - Sind Einträge vorhanden?
   - Haben alle Einträge einen Titel?
3. Integration-Zugriff:
   - Gehe zur Projekte-Datenbank
   - "..." → "Connections" → Ist deine Integration verbunden?

## Filterung von Projekten und Lebensbereichen

Die Extension zeigt automatisch nur **aktive** Projekte und Lebensbereiche an:

### Archivierte Einträge

- **Archivierte Pages werden automatisch ausgeblendet**
- In Notion: Rechtsklick auf Page → "Delete" → "Archive"
- Diese erscheinen nicht mehr in der Raycast Extension

### Status-basierte Filterung

Die Extension unterstützt mehrere Property-Namen für die Filterung:

#### Variante 1: "In Bearbeitung" (Checkbox) ⭐ Empfohlen
```
☑ Checked = In Bearbeitung ✅ (wird angezeigt)
☐ Unchecked = Nicht aktiv ❌ (wird ausgeblendet)
```
**Priorität**: Diese Property wird zuerst geprüft!

#### Variante 2: "Status" (Select)
```
Optionen:
- Active ✅ (wird angezeigt)
- Aktiv ✅ (wird angezeigt)
- Inactive ❌ (wird ausgeblendet)
- Completed ❌ (wird ausgeblendet)
- On Hold ❌ (wird ausgeblendet)
- Kein Wert ❌ (wird ausgeblendet)
```

#### Variante 3: "Status" (Checkbox)
```
☑ Checked = Aktiv ✅ (wird angezeigt)
☐ Unchecked = Inaktiv ❌ (wird ausgeblendet)
```

### Ohne Filter-Property

Wenn **keine** der oben genannten Properties existiert:
- Alle nicht-archivierten Einträge werden angezeigt
- Einfachste Variante für schnellen Start

### Empfohlene Setup-Varianten

**Minimal** (für Anfang):
- Nur Title-Property
- Filterung nur über Notion-Archivierung
- Einfachstes Setup

**Empfohlen** (mit "In Bearbeitung"): ⭐
- Title-Property
- "In Bearbeitung" (Checkbox)
- Einfaches Aktivieren/Deaktivieren von Projekten
- Intuitive deutsche Benennung

**Erweitert** (mit Status-Select):
- Title-Property
- "Status" (Select) mit "Active" Option
- Mehrere Status-Werte (Active, Completed, On Hold, etc.)
- Detaillierte Projekt-Phasen

**International** (mit Status-Checkbox):
- Title-Property
- "Status" (Checkbox)
- Einfaches An/Aus-Schalten
- Englische Benennung

## Best Practices

### Typ-Property einrichten

Empfohlene Select-Options für die "Typ"-Property:

```
- learning (Blau) 📚
- improvement (Gelb) 📈
- feeling (Lila) ❤️
- miss (Rot) 😔
- Gedanke (Blau) 💭
- Erlebnis (Grün) ✨
- Aktivität (Orange) 🏃
- Idee (Gelb) 💡
```

### Formula für "Relevantester Favorit"

Optional: Automatische Berechnung des höchsten Favoriten-Status

```
if(prop("Moment meines Lebens"), "01-leben",
  if(prop("⭐ Jahresfavorit"), "02-jahr",
    if(prop("⭐ Monatsfavorit"), "03-monat",
      if(prop("⭐ Wochenfavorit"), "04-woche",
        if(prop("⭐ Tagesfavorit"), "05-tag", "")))))
```

Diese Formula wird automatisch von der Extension erkannt und angezeigt.

## Beispiel-Setup

Minimale Konfiguration für schnellen Start:

1. **Eine Datenbank**: "Momente"
   - Name (Title)
   - Zeitpunkt (Date)
   - Typ (Select mit 3-4 Optionen)
   - Favoriten-Checkboxen

2. **Start ohne Relations**: Du kannst später Projekte/Lebensbereiche hinzufügen

3. **Integration**: Erstellen und mit der Momente-Datenbank verbinden

4. **Raycast**: Token und Database-ID eingeben

Fertig! 🎉

## Support

Wenn du Probleme hast:
1. Überprüfe die Raycast Extension Logs (Preferences → Advanced → Extension Logs)
2. Teste die Integration direkt in Notion (funktioniert die Relation manuell?)
3. Überprüfe, dass alle erforderlichen Properties existieren
