# Caching in Momentchen Extension

## Übersicht

Die Momentchen Raycast Extension nutzt intelligentes Caching, um die Performance zu optimieren und Offline-Zugriff zu ermöglichen.

## Wie funktioniert das Caching?

### Automatisches Caching

- **Speicherdauer**: 5 Minuten (konfigurierbar in `src/utils/cache.ts`)
- **Hintergrund-Aktualisierung**: Daten werden automatisch aktualisiert, wenn:
  - Die Extension geöffnet wird
  - Das Raycast-Fenster den Fokus erhält
  - Der Nutzer manuell aktualisiert (Cmd+R)

### Cache-Strategie

Die Extension verwendet `useCachedPromise` von `@raycast/utils`:

```typescript
useCachedPromise(
  async () => {
    // Fetch data from Notion API
    return moments;
  },
  [],
  {
    keepPreviousData: true, // Zeige alte Daten während des Ladens
    execute: true,           // Führe automatisch aus
  }
);
```

### Vorteile

1. **Schnelle Ladezeiten**: Gecachte Daten werden sofort angezeigt
2. **Offline-Zugriff**: Zugriff auf letzte gecachte Daten ohne Internet
3. **Smooth UX**: Keine Ladebildschirme beim Aktualisieren
4. **Reduzierte API-Calls**: Weniger Belastung der Notion API

## Cache-Verwaltung

### Keyboard Shortcuts

- `Cmd+R` - Manuell von Notion aktualisieren
- `Cmd+Shift+C` - Cache Management öffnen

### Cache Management View

Im Cache Management kannst du:
- Letzte Synchronisationszeit sehen
- Anzahl gecachter Momente einsehen
- Cache komplett löschen
- Cache-Konfiguration überprüfen

### Programmgesteuerte Cache-Kontrolle

```typescript
import {
  getCached,
  setCache,
  clearCache,
  clearAllCache,
  invalidateMomentsCache,
  optimisticallyAddMoment,
  optimisticallyUpdateMoment,
  optimisticallyRemoveMoment
} from "../utils/cache";

// Daten aus dem Cache lesen
const moments = getCached<Moment[]>(CACHE_KEYS.MOMENTS);

// Daten in den Cache schreiben
setCache(CACHE_KEYS.MOMENTS, moments);

// Spezifischen Cache löschen
clearCache(CACHE_KEYS.MOMENTS);

// Alle Caches löschen
clearAllCache();

// Cache nach Create/Update/Delete invalidieren
invalidateMomentsCache();

// Optimistische Updates (erscheint sofort in UI)
optimisticallyAddMoment(newMoment);
optimisticallyUpdateMoment(updatedMoment);
optimisticallyRemoveMoment(momentId);
```

## Cache-Struktur

### Cache Keys

```typescript
export const CACHE_KEYS = {
  MOMENTS: "moments-list",
  MOMENT_TYPES: "moment-types",
  LAST_SYNC: "last-sync-timestamp",
} as const;
```

### Cache Duration

```typescript
export const CACHE_DURATION = {
  MOMENTS: 5 * 60 * 1000,      // 5 Minuten
  MOMENT_TYPES: 60 * 60 * 1000, // 1 Stunde
} as const;
```

## Cache-Invalidation bei Mutations

Die Extension invalidiert automatisch den Cache nach Änderungen:

### Beim Erstellen eines Moments

```typescript
// In create-moment.tsx
await client.createPage({ properties });

// Cache invalidieren, damit der neue Moment in Search erscheint
invalidateMomentsCache();

// Zurück zur Hauptansicht
await popToRoot();
```

**Flow:**
1. User erstellt neuen Moment
2. API-Call zu Notion
3. Cache wird invalidiert
4. Beim nächsten Öffnen von Search lädt `useCachedPromise` automatisch neu
5. Der neue Moment erscheint sofort

### Beim Bearbeiten/Löschen (Future)

```typescript
// Nach Update
await client.updatePage(pageId, properties);
invalidateMomentsCache();

// Nach Delete
await client.archivePage(pageId);
optimisticallyRemoveMoment(pageId); // Sofortiges Feedback
```

### Optimistische Updates

Für noch bessere UX kannst du optimistische Updates nutzen:

```typescript
// Moment erscheint sofort, auch wenn API langsam ist
optimisticallyAddMoment(newMoment);

try {
  await client.createPage({ properties });
} catch (error) {
  // Bei Fehler: Cache neu laden
  invalidateMomentsCache();
}
```

**Vorteile:**
- Sofortiges visuelles Feedback
- Keine Wartezeit auf API
- Automatisches Rollback bei Fehler

**Nachteile:**
- Komplexere Fehlerbehandlung
- Temporäre IDs erforderlich

## Anpassung

### Cache-Dauer ändern

In `src/utils/cache.ts`:

```typescript
export const CACHE_DURATION = {
  MOMENTS: 10 * 60 * 1000, // 10 Minuten statt 5
  MOMENT_TYPES: 60 * 60 * 1000,
} as const;
```

### Caching deaktivieren

Falls du das Caching komplett deaktivieren möchtest, ersetze `useCachedPromise` durch `usePromise` in `search-moments.tsx`:

```typescript
// Statt useCachedPromise:
import { usePromise } from "@raycast/utils";

const { data, isLoading, revalidate } = usePromise(
  async () => {
    // ... fetch logic
  },
  []
);
```

## Best Practices

1. **Nicht zu lange cachen**: 5 Minuten ist ein guter Kompromiss zwischen Performance und Aktualität
2. **Background-Refresh nutzen**: Lasse die automatische Aktualisierung aktiviert
3. **Cache bei Fehlern löschen**: Bei anhaltenden Fehlern kann ein Cache-Clear helfen
4. **Offline-First denken**: Nutze `keepPreviousData: true` für bessere UX

## Debugging

### Cache-Inhalte prüfen

```typescript
import { getCached, CACHE_KEYS } from "../utils/cache";

// In der Browser-Console:
const moments = getCached(CACHE_KEYS.MOMENTS);
console.log("Cached moments:", moments);
```

### Last Sync Time

```typescript
import { getLastSyncTime, formatLastSync } from "../utils/cache";

console.log("Last sync:", formatLastSync());
console.log("Last sync date:", getLastSyncTime());
```

## Troubleshooting

### Problem: Daten werden nicht aktualisiert

**Lösung**:
1. Manuell mit `Cmd+R` aktualisieren
2. Cache Management öffnen und Cache löschen
3. Extension neu starten

### Problem: Offline-Daten nicht verfügbar

**Lösung**:
- Stelle sicher, dass die Daten mindestens einmal online geladen wurden
- Überprüfe, ob der Cache nicht manuell gelöscht wurde

### Problem: Langsame Performance

**Lösung**:
- Cache-Dauer verlängern (siehe Anpassung oben)
- Überprüfe die Anzahl gecachter Momente im Cache Management
