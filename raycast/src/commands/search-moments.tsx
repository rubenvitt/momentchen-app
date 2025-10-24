/**
 * Search Moments Command
 * Browse and filter moments from your Notion database
 */

import { Action, ActionPanel, List, showToast, Toast, Icon, Color } from "@raycast/api";
import { useState } from "react";
import { useCachedPromise } from "@raycast/utils";
import NotionAPIClient from "../api/notion";
import { Moment } from "../types/moment";
import { notionPageToMoment } from "../utils/notion-mapper";
import { formatDisplayDate } from "../utils/date-formatter";
import { notionColorToRaycast, getMomentTypeEmoji, getReviewLevelEmoji } from "../utils/color-mapper";
import { formatLastSync, setLastSyncTime } from "../utils/cache";
import CacheManagement from "./cache-management";

export default function SearchMoments() {
  const [filterType, setFilterType] = useState<string>("all");
  const [filterFavorite, setFilterFavorite] = useState<string>("all");

  // Use cached promise for automatic caching and revalidation
  const { data: moments = [], isLoading, revalidate } = useCachedPromise(
    async () => {
      const client = new NotionAPIClient();

      // Query database with sorting by timestamp
      const pages = await client.queryDatabase({
        sorts: [{ property: "Zeitpunkt", direction: "descending" }],
      });

      // Map Notion pages to Moment domain models
      const mappedMoments = pages.map(notionPageToMoment);

      // Update last sync time
      setLastSyncTime();

      return mappedMoments;
    },
    [],
    {
      // Keep previous data while revalidating
      keepPreviousData: true,
      // Revalidate in background when window regains focus
      execute: true,
      // Show toast on error
      onError: (error) => {
        showToast({
          style: Toast.Style.Failure,
          title: "Fehler beim Laden",
          message: error instanceof Error ? error.message : "Unbekannter Fehler",
        });
      },
    }
  );

  function filterMoments(moments: Moment[]): Moment[] {
    let filtered = moments;

    // Filter by type
    if (filterType !== "all") {
      filtered = filtered.filter((m) => m.type.name === filterType);
    }

    // Filter by favorite
    switch (filterFavorite) {
      case "daily":
        filtered = filtered.filter((m) => m.isDailyFavorite);
        break;
      case "weekly":
        filtered = filtered.filter((m) => m.isWeeklyFavorite);
        break;
      case "monthly":
        filtered = filtered.filter((m) => m.isMonthlyFavorite);
        break;
      case "yearly":
        filtered = filtered.filter((m) => m.isYearlyFavorite);
        break;
      case "lifetime":
        filtered = filtered.filter((m) => m.isLifetimeMoment);
        break;
    }

    return filtered;
  }

  const filteredMoments = filterMoments(moments);

  const lastSync = formatLastSync();

  return (
    <List
      isLoading={isLoading}
      searchBarPlaceholder="Suche nach Momenten..."
      navigationTitle={`Momente (${filteredMoments.length})`}
      searchBarAccessory={
        <>
          <List.Dropdown
            tooltip="Filter nach Typ"
            value={filterType}
            onChange={setFilterType}
            storeValue
          >
            <List.Dropdown.Item title="Alle Typen" value="all" />
            <List.Dropdown.Item title="Learning 📚" value="learning" />
            <List.Dropdown.Item title="Improvement 📈" value="improvement" />
            <List.Dropdown.Item title="Feeling ❤️" value="feeling" />
            <List.Dropdown.Item title="Miss 😔" value="miss" />
            <List.Dropdown.Item title="Gedanke 💭" value="Gedanke" />
            <List.Dropdown.Item title="Erlebnis ✨" value="Erlebnis" />
            <List.Dropdown.Item title="Aktivität 🏃" value="Aktivität" />
            <List.Dropdown.Item title="Idee 💡" value="Idee" />
          </List.Dropdown>
          <List.Dropdown
            tooltip="Filter nach Favoriten"
            value={filterFavorite}
            onChange={setFilterFavorite}
            storeValue
          >
            <List.Dropdown.Item title="Alle Momente" value="all" />
            <List.Dropdown.Item title="⭐ Tagesfavoriten" value="daily" />
            <List.Dropdown.Item title="⭐ Wochenfavoriten" value="weekly" />
            <List.Dropdown.Item title="⭐ Monatsfavoriten" value="monthly" />
            <List.Dropdown.Item title="⭐ Jahresfavoriten" value="yearly" />
            <List.Dropdown.Item title="🌟 Lebensmomente" value="lifetime" />
          </List.Dropdown>
        </>
      }
    >
      {filteredMoments.map((moment) => (
        <List.Item
          key={moment.id}
          title={moment.title}
          subtitle={formatDisplayDate(moment.timestamp)}
          icon={{
            value: getMomentTypeEmoji(moment.type.name),
            tooltip: moment.type.name,
          }}
          accessories={[
            ...(moment.category && moment.category.type !== "none"
              ? [
                  {
                    icon: moment.category.type === "project" ? "📁" : "🌱",
                    tooltip: moment.category.type === "project" ? "Projekt" : "Lebensbereich",
                  },
                ]
              : []),
            ...(moment.highestReviewLevel
              ? [
                  {
                    icon: getReviewLevelEmoji(moment.highestReviewLevel),
                    tooltip: `Review Level: ${moment.highestReviewLevel}`,
                  },
                ]
              : []),
            {
              tag: {
                value: moment.type.name,
                color: notionColorToRaycast(moment.type.color),
              },
            },
          ]}
          actions={
            <ActionPanel>
              <Action.Push title="Details Anzeigen" target={<MomentDetail moment={moment} />} />
              <Action.OpenInBrowser
                title="In Notion Öffnen"
                url={`https://www.notion.so/${moment.id.replace(/-/g, "")}`}
              />
              <ActionPanel.Section title="Daten">
                <Action
                  title="Neu Laden"
                  onAction={revalidate}
                  icon={Icon.ArrowClockwise}
                  shortcut={{ modifiers: ["cmd"], key: "r" }}
                />
                <Action.Push
                  title="Cache Verwalten"
                  target={<CacheManagement onCacheCleared={revalidate} />}
                  icon={Icon.HardDrive}
                  shortcut={{ modifiers: ["cmd", "shift"], key: "c" }}
                />
                <Action.CopyToClipboard
                  title="Moment-ID Kopieren"
                  content={moment.id}
                  shortcut={{ modifiers: ["cmd"], key: "." }}
                />
              </ActionPanel.Section>
            </ActionPanel>
          }
        />
      ))}

      {!isLoading && filteredMoments.length === 0 && moments.length === 0 && (
        <List.EmptyView
          title="Keine Momente vorhanden"
          description="Erstelle dein erstes Moment mit 'Create Moment'"
          icon={Icon.Stars}
          actions={
            <ActionPanel>
              <Action
                title="Neu Laden"
                onAction={revalidate}
                icon={Icon.ArrowClockwise}
                shortcut={{ modifiers: ["cmd"], key: "r" }}
              />
            </ActionPanel>
          }
        />
      )}

      {!isLoading && filteredMoments.length === 0 && moments.length > 0 && (
        <List.EmptyView
          title="Keine Momente gefunden"
          description={`Keine Momente mit den aktuellen Filtern. ${moments.length} Momente insgesamt.`}
          icon={Icon.MagnifyingGlass}
        />
      )}
    </List>
  );
}

/**
 * Detail view for a single moment
 */
function MomentDetail({ moment }: { moment: Moment }) {
  return (
    <List>
      <List.Item
        title="Beschreibung"
        subtitle={moment.title}
        icon={Icon.Text}
      />
      <List.Item
        title="Typ"
        subtitle={moment.type.name}
        icon={getMomentTypeEmoji(moment.type.name)}
        accessories={[
          {
            tag: {
              value: moment.type.name,
              color: notionColorToRaycast(moment.type.color),
            },
          },
        ]}
      />
      <List.Item
        title="Zeitpunkt"
        subtitle={formatDisplayDate(moment.timestamp)}
        icon={Icon.Calendar}
      />

      {moment.category && moment.category.type !== "none" && (
        <List.Item
          title={moment.category.type === "project" ? "Projekt" : "Lebensbereich"}
          icon={moment.category.type === "project" ? "📁" : "🌱"}
          accessories={[
            {
              tag: {
                value: moment.category.name,
                color: Color.SecondaryText,
              },
            },
          ]}
        />
      )}

      {moment.highestReviewLevel && (
        <List.Item
          title="Höchstes Review Level"
          subtitle={moment.highestReviewLevel}
          icon={getReviewLevelEmoji(moment.highestReviewLevel)}
        />
      )}

      {moment.isDailyFavorite && (
        <List.Item
          title="⭐ Tagesfavorit"
          icon={{ source: Icon.Star, tintColor: Color.Yellow }}
        />
      )}
      {moment.isWeeklyFavorite && (
        <List.Item
          title="⭐ Wochenfavorit"
          icon={{ source: Icon.Star, tintColor: Color.Yellow }}
        />
      )}
      {moment.isMonthlyFavorite && (
        <List.Item
          title="⭐ Monatsfavorit"
          icon={{ source: Icon.Star, tintColor: Color.Yellow }}
        />
      )}
      {moment.isYearlyFavorite && (
        <List.Item
          title="⭐ Jahresfavorit"
          icon={{ source: Icon.Star, tintColor: Color.Yellow }}
        />
      )}
      {moment.isLifetimeMoment && (
        <List.Item
          title="🌟 Moment meines Lebens"
          icon={{ source: Icon.Star, tintColor: Color.Orange }}
        />
      )}
    </List>
  );
}
