/**
 * Color mapping utilities
 * Maps Notion colors to Raycast icon colors
 */

import { Color } from "@raycast/api";
import { NotionColor } from "../types/moment";

/**
 * Map Notion color to Raycast Color
 */
export function notionColorToRaycast(notionColor: NotionColor): Color {
  switch (notionColor) {
    case NotionColor.Gray:
      return Color.SecondaryText;
    case NotionColor.Brown:
      return Color.Orange;
    case NotionColor.Orange:
      return Color.Orange;
    case NotionColor.Yellow:
      return Color.Yellow;
    case NotionColor.Green:
      return Color.Green;
    case NotionColor.Blue:
      return Color.Blue;
    case NotionColor.Purple:
      return Color.Purple;
    case NotionColor.Pink:
      return Color.Magenta;
    case NotionColor.Red:
      return Color.Red;
    case NotionColor.Default:
    default:
      return Color.PrimaryText;
  }
}

/**
 * Get emoji for moment type
 */
export function getMomentTypeEmoji(typeName: string): string {
  const normalizedName = typeName.toLowerCase();

  const emojiMap: Record<string, string> = {
    gedanke: "💭",
    thought: "💭",
    erlebnis: "✨",
    experience: "✨",
    aktivität: "🏃",
    activity: "🏃",
    idee: "💡",
    idea: "💡",
    emotion: "❤️",
    feeling: "❤️",
    lernen: "📚",
    learning: "📚",
    improvement: "📈",
    miss: "😔",
  };

  return emojiMap[normalizedName] || "📝";
}

/**
 * Get review level emoji
 */
export function getReviewLevelEmoji(reviewLevel: string): string {
  const levelMap: Record<string, string> = {
    "01-leben": "🌟", // Lifetime
    "02-jahr": "⭐", // Year
    "03-monat": "🌙", // Month
    "04-woche": "✨", // Week
    "05-tag": "💫", // Day
  };

  return levelMap[reviewLevel] || "";
}
