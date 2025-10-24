/**
 * Cache Management View
 * Allows users to inspect and manage cache
 */

import { Action, ActionPanel, List, showToast, Toast, Icon, Color } from "@raycast/api";
import { useState, useEffect } from "react";
import { getLastSyncTime, clearAllCache, formatLastSync, CACHE_KEYS, getCached } from "../utils/cache";
import { Moment } from "../types/moment";

export default function CacheManagement({ onCacheCleared }: { onCacheCleared?: () => void }) {
  const [lastSync, setLastSync] = useState<string>("");
  const [cachedMomentsCount, setCachedMomentsCount] = useState<number>(0);

  useEffect(() => {
    loadCacheInfo();
  }, []);

  function loadCacheInfo() {
    setLastSync(formatLastSync());

    const cached = getCached<Moment[]>(CACHE_KEYS.MOMENTS);
    setCachedMomentsCount(cached?.length || 0);
  }

  async function handleClearCache() {
    try {
      clearAllCache();

      await showToast({
        style: Toast.Style.Success,
        title: "Cache gelöscht",
        message: "Alle gespeicherten Daten wurden entfernt",
      });

      loadCacheInfo();

      if (onCacheCleared) {
        onCacheCleared();
      }
    } catch (error) {
      await showToast({
        style: Toast.Style.Failure,
        title: "Fehler",
        message: error instanceof Error ? error.message : "Konnte Cache nicht löschen",
      });
    }
  }

  return (
    <List navigationTitle="Cache Verwaltung">
      <List.Item
        title="Letzte Synchronisation"
        subtitle={lastSync}
        icon={Icon.Clock}
        accessories={[
          {
            icon: Icon.CircleProgress,
            tooltip: `Zuletzt aktualisiert: ${lastSync}`,
          },
        ]}
      />

      <List.Item
        title="Gespeicherte Momente"
        subtitle={`${cachedMomentsCount} Momente im Cache`}
        icon={Icon.Document}
        accessories={[
          {
            tag: {
              value: `${cachedMomentsCount}`,
              color: cachedMomentsCount > 0 ? Color.Green : Color.SecondaryText,
            },
          },
        ]}
      />

      <List.Item
        title="Cache löschen"
        subtitle="Alle gespeicherten Daten entfernen"
        icon={{ source: Icon.Trash, tintColor: Color.Red }}
        actions={
          <ActionPanel>
            <Action
              title="Cache Löschen"
              icon={Icon.Trash}
              style={Action.Style.Destructive}
              onAction={handleClearCache}
            />
          </ActionPanel>
        }
      />

      <List.Section title="Cache Informationen">
        <List.Item
          title="Automatische Aktualisierung"
          subtitle="Cache wird automatisch im Hintergrund aktualisiert"
          icon={Icon.CheckCircle}
          accessories={[{ tag: { value: "Aktiv", color: Color.Green } }]}
        />

        <List.Item
          title="Cache Dauer"
          subtitle="Daten werden 5 Minuten gecacht"
          icon={Icon.Clock}
        />

        <List.Item
          title="Hintergrund-Sync"
          subtitle="Aktualisiert sich automatisch beim Öffnen"
          icon={Icon.ArrowClockwise}
        />
      </List.Section>
    </List>
  );
}
