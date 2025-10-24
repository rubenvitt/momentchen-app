/**
 * Utilities for mapping between Notion API responses and domain models
 */

import { NotionPage, NotionRichText, NotionPropertyInput } from "../types/notion";
import { Moment, MomentType, MomentCategory, NotionColor } from "../types/moment";

/**
 * Extract text from Notion rich text array
 */
export function extractText(richText: NotionRichText[]): string {
  return richText.map((rt) => rt.plain_text).join("");
}

/**
 * Create Notion rich text from string
 */
export function createRichText(text: string): NotionRichText[] {
  return [
    {
      type: "text",
      text: { content: text, link: null },
      plain_text: text,
      href: null,
    },
  ];
}

/**
 * Map Notion page to Moment domain model
 */
export function notionPageToMoment(page: NotionPage): Moment {
  const props = page.properties;

  // Extract title
  const titleProp = props["Name"];
  const title = titleProp?.type === "title" ? extractText(titleProp.title) : "Untitled";

  // Extract type
  const typeProp = props["Typ"];
  const momentType: MomentType =
    typeProp?.type === "select" && typeProp.select
      ? {
          name: typeProp.select.name,
          color: typeProp.select.color as NotionColor,
        }
      : { name: "unknown", color: NotionColor.Gray };

  // Extract timestamp
  const dateProp = props["Zeitpunkt"];
  const timestamp =
    dateProp?.type === "date" && dateProp.date ? new Date(dateProp.date.start) : new Date(page.created_time);

  // Extract favorites
  const getDailyFav = props["⭐ Tagesfavorit"];
  const isDailyFavorite = getDailyFav?.type === "checkbox" ? getDailyFav.checkbox : false;

  const getWeeklyFav = props["⭐ Wochenfavorit"];
  const isWeeklyFavorite = getWeeklyFav?.type === "checkbox" ? getWeeklyFav.checkbox : false;

  const getMonthlyFav = props["⭐ Monatsfavorit"];
  const isMonthlyFavorite = getMonthlyFav?.type === "checkbox" ? getMonthlyFav.checkbox : false;

  const getYearlyFav = props["⭐ Jahresfavorit"];
  const isYearlyFavorite = getYearlyFav?.type === "checkbox" ? getYearlyFav.checkbox : false;

  const getLifetimeMoment = props["Moment meines Lebens"];
  const isLifetimeMoment = getLifetimeMoment?.type === "checkbox" ? getLifetimeMoment.checkbox : false;

  // Extract highest review level (formula)
  const reviewLevelProp = props["Relevantester Favorit"];
  const highestReviewLevel =
    reviewLevelProp?.type === "formula" && reviewLevelProp.formula.type === "string"
      ? reviewLevelProp.formula.string || ""
      : "";

  // Extract category (from relations)
  const projectRelation = props["Projekt"];
  const lifeAreaRelation = props["Lebensbereich"];

  let category: MomentCategory = { type: "none" };

  if (projectRelation?.type === "relation" && projectRelation.relation.length > 0) {
    category = {
      type: "project",
      id: projectRelation.relation[0].id,
      name: "Projekt", // Name will be loaded separately if needed
    };
  } else if (lifeAreaRelation?.type === "relation" && lifeAreaRelation.relation.length > 0) {
    category = {
      type: "lifeArea",
      id: lifeAreaRelation.relation[0].id,
      name: "Lebensbereich",
    };
  }

  return {
    id: page.id,
    title,
    type: momentType,
    timestamp,
    category,
    isDailyFavorite,
    isWeeklyFavorite,
    isMonthlyFavorite,
    isYearlyFavorite,
    isLifetimeMoment,
    highestReviewLevel,
  };
}

/**
 * Convert Moment data to Notion properties for creation
 */
export function momentToNotionProperties(data: {
  title: string;
  type: string;
  timestamp: Date;
}): Record<string, NotionPropertyInput> {
  return {
    Name: {
      title: createRichText(data.title),
    },
    Typ: {
      select: { name: data.type },
    },
    Zeitpunkt: {
      date: {
        start: data.timestamp.toISOString(),
        end: null,
        time_zone: null,
      },
    },
    // Favoriten werden nicht beim Erstellen gesetzt, sondern während Reviews
    "⭐ Tagesfavorit": {
      checkbox: false,
    },
    "⭐ Wochenfavorit": {
      checkbox: false,
    },
    "⭐ Monatsfavorit": {
      checkbox: false,
    },
    "⭐ Jahresfavorit": {
      checkbox: false,
    },
    "Moment meines Lebens": {
      checkbox: false,
    },
  };
}
