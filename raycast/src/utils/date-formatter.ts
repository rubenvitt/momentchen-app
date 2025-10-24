/**
 * Date formatting utilities
 */

/**
 * Format date for display in the UI
 */
export function formatDisplayDate(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

  if (diffDays === 0) {
    return `Heute, ${formatTime(date)}`;
  } else if (diffDays === 1) {
    return `Gestern, ${formatTime(date)}`;
  } else if (diffDays < 7) {
    return `${formatWeekday(date)}, ${formatTime(date)}`;
  } else {
    return formatFullDate(date);
  }
}

/**
 * Format time as HH:MM
 */
export function formatTime(date: Date): string {
  return date.toLocaleTimeString("de-DE", {
    hour: "2-digit",
    minute: "2-digit",
  });
}

/**
 * Format weekday name
 */
export function formatWeekday(date: Date): string {
  return date.toLocaleDateString("de-DE", {
    weekday: "long",
  });
}

/**
 * Format full date as "DD.MM.YYYY HH:MM"
 */
export function formatFullDate(date: Date): string {
  return date.toLocaleString("de-DE", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

/**
 * Format date for API (ISO 8601)
 */
export function formatISODate(date: Date): string {
  return date.toISOString();
}

/**
 * Parse ISO date string to Date
 */
export function parseISODate(isoString: string): Date {
  return new Date(isoString);
}
