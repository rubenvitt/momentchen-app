/**
 * Domain types for Momentchen
 * Based on the Swift domain models
 */

export interface Moment {
  id: string;
  title: string;
  type: MomentType;
  timestamp: Date;
  category?: MomentCategory;
  isDailyFavorite: boolean;
  isWeeklyFavorite: boolean;
  isMonthlyFavorite: boolean;
  isYearlyFavorite: boolean;
  isLifetimeMoment: boolean;
  highestReviewLevel: string;
}

export interface MomentType {
  name: string;
  color: NotionColor;
}

export type MomentCategory =
  | { type: "none" }
  | { type: "project"; id: string; name: string }
  | { type: "lifeArea"; id: string; name: string };

export enum NotionColor {
  Default = "default",
  Gray = "gray",
  Brown = "brown",
  Orange = "orange",
  Yellow = "yellow",
  Green = "green",
  Blue = "blue",
  Purple = "purple",
  Pink = "pink",
  Red = "red",
}

// Common moment types
export const MomentTypes = {
  GEDANKE: { name: "Gedanke", color: NotionColor.Blue },
  ERLEBNIS: { name: "Erlebnis", color: NotionColor.Green },
  AKTIVITÄT: { name: "Aktivität", color: NotionColor.Orange },
  IDEE: { name: "Idee", color: NotionColor.Yellow },
  EMOTION: { name: "Emotion", color: NotionColor.Pink },
  LERNEN: { name: "Lernen", color: NotionColor.Purple },
  LEARNING: { name: "learning", color: NotionColor.Blue },
  IMPROVEMENT: { name: "improvement", color: NotionColor.Yellow },
  FEELING: { name: "feeling", color: NotionColor.Purple },
  MISS: { name: "miss", color: NotionColor.Red },
};
