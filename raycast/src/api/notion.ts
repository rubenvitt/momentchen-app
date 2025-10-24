/**
 * Notion API Client for Momentchen
 * Handles all HTTP communication with Notion API v1
 */

import { getPreferenceValues } from "@raycast/api";
import {
  NotionDatabase,
  NotionPage,
  NotionQueryDatabaseRequest,
  NotionQueryDatabaseResponse,
  NotionCreatePageRequest,
  NotionUpdatePageRequest,
  NotionSearchResponse,
  NotionUser,
  NotionAPIError,
} from "../types/notion";

interface Preferences {
  notionToken: string;
  databaseId: string;
}

const NOTION_VERSION = "2022-06-28";
const BASE_URL = "https://api.notion.com/v1";

class NotionAPIClient {
  private token: string;
  private databaseId: string;

  constructor() {
    const preferences = getPreferenceValues<Preferences>();
    this.token = preferences.notionToken;
    this.databaseId = preferences.databaseId;
  }

  private async makeRequest<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const url = `${BASE_URL}${endpoint}`;

    const headers: Record<string, string> = {
      Authorization: `Bearer ${this.token}`,
      "Notion-Version": NOTION_VERSION,
      "Content-Type": "application/json",
      ...((options.headers as Record<string, string>) || {}),
    };

    const response = await fetch(url, {
      ...options,
      headers,
    });

    if (!response.ok) {
      const error: NotionAPIError = await response.json();
      throw new Error(`Notion API Error: ${error.message} (${error.code})`);
    }

    return response.json();
  }

  /**
   * Validate the Notion token
   */
  async validateToken(): Promise<NotionUser> {
    return this.makeRequest<NotionUser>("/users/me");
  }

  /**
   * Search for databases
   */
  async searchDatabases(): Promise<NotionDatabase[]> {
    const response = await this.makeRequest<NotionSearchResponse>("/search", {
      method: "POST",
      body: JSON.stringify({
        filter: { property: "object", value: "database" },
        page_size: 100,
      }),
    });

    return response.results;
  }

  /**
   * Query the moments database
   */
  async queryDatabase(request: NotionQueryDatabaseRequest = {}): Promise<NotionPage[]> {
    const response = await this.makeRequest<NotionQueryDatabaseResponse>(
      `/databases/${this.databaseId}/query`,
      {
        method: "POST",
        body: JSON.stringify({
          page_size: 100,
          ...request,
        }),
      }
    );

    // Handle pagination if needed
    let results = response.results;
    let nextCursor = response.next_cursor;

    while (nextCursor) {
      const nextResponse = await this.makeRequest<NotionQueryDatabaseResponse>(
        `/databases/${this.databaseId}/query`,
        {
          method: "POST",
          body: JSON.stringify({
            page_size: 100,
            start_cursor: nextCursor,
            ...request,
          }),
        }
      );

      results = [...results, ...nextResponse.results];
      nextCursor = nextResponse.next_cursor;
    }

    return results;
  }

  /**
   * Create a new page in the database
   */
  async createPage(request: Omit<NotionCreatePageRequest, "parent">): Promise<NotionPage> {
    return this.makeRequest<NotionPage>("/pages", {
      method: "POST",
      body: JSON.stringify({
        parent: { database_id: this.databaseId },
        ...request,
      }),
    });
  }

  /**
   * Update an existing page
   */
  async updatePage(pageId: string, request: NotionUpdatePageRequest): Promise<NotionPage> {
    return this.makeRequest<NotionPage>(`/pages/${pageId}`, {
      method: "PATCH",
      body: JSON.stringify(request),
    });
  }

  /**
   * Archive a page (soft delete)
   */
  async archivePage(pageId: string): Promise<NotionPage> {
    return this.makeRequest<NotionPage>(`/pages/${pageId}`, {
      method: "PATCH",
      body: JSON.stringify({ archived: true }),
    });
  }

  /**
   * Get the database schema
   */
  async getDatabase(): Promise<NotionDatabase> {
    return this.makeRequest<NotionDatabase>(`/databases/${this.databaseId}`);
  }

  /**
   * Get pages from a specific database (for relations like projects/life areas)
   * Only returns non-archived pages
   */
  async getPagesFromDatabase(databaseId: string): Promise<NotionPage[]> {
    const response = await this.makeRequest<NotionQueryDatabaseResponse>(
      `/databases/${databaseId}/query`,
      {
        method: "POST",
        body: JSON.stringify({
          page_size: 100,
          // No filter here - we filter by archived status after receiving
        }),
      }
    );

    // Filter out archived pages (Notion's system property)
    return response.results.filter((page) => !page.archived);
  }

  /**
   * Get relation options (projects or life areas)
   */
  async getRelationOptions(propertyName: string): Promise<Array<{ id: string; title: string }>> {
    // First get the database schema to find the relation database ID
    const database = await this.getDatabase();
    const property = database.properties?.[propertyName];

    if (!property || property.type !== "relation") {
      return [];
    }

    const relationDatabaseId = property.relation.database_id;
    const pages = await this.getPagesFromDatabase(relationDatabaseId);

    // Filter out pages with inactive status
    // Check for "In Bearbeitung" (checkbox) or "Status" (select) property
    const filteredPages = pages.filter((page) => {
      const inBearbeitungProp = page.properties["In Bearbeitung"];
      const statusProp = page.properties["Status"];

      // If "In Bearbeitung" checkbox exists, use it for filtering
      if (inBearbeitungProp && inBearbeitungProp.type === "checkbox") {
        // Only include if checkbox is checked
        return inBearbeitungProp.checkbox === true;
      }

      // If "Status" property exists, use it for filtering
      if (statusProp) {
        // If Status is a select
        if (statusProp.type === "select") {
          // If no value is selected, exclude the page
          if (!statusProp.select) return false;

          // Only include if status is "Active" or "Aktiv"
          const statusName = statusProp.select.name.toLowerCase();
          return statusName === "active" || statusName === "aktiv";
        }

        // If Status is a checkbox, only include if checked
        if (statusProp.type === "checkbox") {
          return statusProp.checkbox === true;
        }
      }

      // If neither property exists, include all non-archived pages
      return true;
    });

    // Extract titles from filtered pages
    const options = filteredPages.map((page) => {
      let title = "Untitled";

      // Find the title property (every Notion database has exactly one title property)
      // We need to iterate through all properties to find the one with type "title"
      const properties = page.properties;

      for (const [propName, propValue] of Object.entries(properties)) {
        if (propValue.type === "title" && propValue.title) {
          const extractedTitle = propValue.title.map((t) => t.plain_text).join("").trim();
          if (extractedTitle) {
            title = extractedTitle;
            break;
          }
        }
      }

      return {
        id: page.id,
        title,
      };
    });

    // Sort alphabetically by title
    return options.sort((a, b) => a.title.localeCompare(b.title, "de"));
  }
}

export default NotionAPIClient;
