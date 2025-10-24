/**
 * Notion API types
 * Subset of Notion API response types needed for Momentchen
 */

export interface NotionUser {
  id: string;
  name?: string;
  avatar_url?: string;
  type: string;
  person?: {
    email?: string;
  };
  bot?: Record<string, unknown>;
}

export interface NotionDatabase {
  object: "database";
  id: string;
  created_time: string;
  last_edited_time: string;
  title: NotionRichText[];
  properties?: Record<string, NotionPropertySchema>;
  parent: {
    type: string;
    page_id?: string;
    workspace?: boolean;
  };
}

export interface NotionPage {
  object: "page";
  id: string;
  created_time: string;
  last_edited_time: string;
  properties: Record<string, NotionProperty>;
  url: string;
  parent: {
    type: string;
    database_id?: string;
  };
}

export interface NotionRichText {
  type: "text";
  text: {
    content: string;
    link?: { url: string } | null;
  };
  annotations?: {
    bold: boolean;
    italic: boolean;
    strikethrough: boolean;
    underline: boolean;
    code: boolean;
    color: string;
  };
  plain_text: string;
  href?: string | null;
}

// Property types for reading
export type NotionProperty =
  | { id: string; type: "title"; title: NotionRichText[] }
  | { id: string; type: "rich_text"; rich_text: NotionRichText[] }
  | { id: string; type: "select"; select: { id: string; name: string; color: string } | null }
  | { id: string; type: "date"; date: { start: string; end?: string | null; time_zone?: string | null } | null }
  | { id: string; type: "checkbox"; checkbox: boolean }
  | { id: string; type: "relation"; relation: { id: string }[]; has_more?: boolean }
  | { id: string; type: "formula"; formula: { type: string; string?: string; number?: number; boolean?: boolean } };

// Property schema types (from database schema)
export type NotionPropertySchema =
  | { id: string; name: string; type: "title"; title: Record<string, unknown> }
  | { id: string; name: string; type: "rich_text"; rich_text: Record<string, unknown> }
  | {
      id: string;
      name: string;
      type: "select";
      select: { options: Array<{ id: string; name: string; color: string }> };
    }
  | { id: string; name: string; type: "date"; date: Record<string, unknown> }
  | { id: string; name: string; type: "checkbox"; checkbox: Record<string, unknown> }
  | { id: string; name: string; type: "relation"; relation: { database_id: string } }
  | { id: string; name: string; type: "formula"; formula: { expression: string } };

// Property input types for creating/updating
export interface NotionPropertyInput {
  title?: NotionRichText[];
  rich_text?: NotionRichText[];
  select?: { name: string } | null;
  date?: { start: string; end?: string | null; time_zone?: string | null } | null;
  checkbox?: boolean;
  relation?: Array<{ id: string }>;
}

// API request/response types
export interface NotionQueryDatabaseRequest {
  filter?: NotionFilter;
  sorts?: NotionSort[];
  start_cursor?: string;
  page_size?: number;
}

export interface NotionQueryDatabaseResponse {
  object: "list";
  results: NotionPage[];
  next_cursor: string | null;
  has_more: boolean;
}

export interface NotionSearchResponse {
  object: "list";
  results: NotionDatabase[];
  next_cursor: string | null;
  has_more: boolean;
}

export interface NotionCreatePageRequest {
  parent: { database_id: string };
  properties: Record<string, NotionPropertyInput>;
}

export interface NotionUpdatePageRequest {
  properties: Record<string, NotionPropertyInput>;
}

// Filter types
export type NotionFilter =
  | {
      property: string;
      title?: { contains: string };
      rich_text?: { contains: string };
      select?: { equals: string };
      date?: { on_or_after: string } | { on_or_before: string };
      checkbox?: { equals: boolean };
    }
  | { and: NotionFilter[] }
  | { or: NotionFilter[] };

// Sort types
export interface NotionSort {
  property?: string;
  timestamp?: "created_time" | "last_edited_time";
  direction: "ascending" | "descending";
}

export interface NotionAPIError {
  object: "error";
  status: number;
  code: string;
  message: string;
}
