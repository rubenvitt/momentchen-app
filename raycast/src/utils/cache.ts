/**
 * Cache utilities for Momentchen
 * Provides manual cache control and configuration
 */

import { Cache } from "@raycast/api";

const cache = new Cache();

// Cache keys
export const CACHE_KEYS = {
  MOMENTS: "moments-list",
  MOMENT_TYPES: "moment-types",
  LAST_SYNC: "last-sync-timestamp",
} as const;

// Cache duration in milliseconds
export const CACHE_DURATION = {
  MOMENTS: 5 * 60 * 1000, // 5 minutes
  MOMENT_TYPES: 60 * 60 * 1000, // 1 hour
} as const;

/**
 * Get cached data
 */
export function getCached<T>(key: string): T | null {
  try {
    const cached = cache.get(key);
    if (!cached) return null;

    const data = JSON.parse(cached);
    return data as T;
  } catch {
    return null;
  }
}

/**
 * Set cache data
 */
export function setCache<T>(key: string, data: T): void {
  try {
    cache.set(key, JSON.stringify(data));
  } catch (error) {
    console.error("Failed to set cache:", error);
  }
}

/**
 * Clear specific cache key
 */
export function clearCache(key: string): void {
  cache.remove(key);
}

/**
 * Clear all cache
 */
export function clearAllCache(): void {
  Object.values(CACHE_KEYS).forEach((key) => cache.remove(key));
}

/**
 * Get last sync timestamp
 */
export function getLastSyncTime(): Date | null {
  const timestamp = getCached<number>(CACHE_KEYS.LAST_SYNC);
  return timestamp ? new Date(timestamp) : null;
}

/**
 * Set last sync timestamp
 */
export function setLastSyncTime(): void {
  setCache(CACHE_KEYS.LAST_SYNC, Date.now());
}

/**
 * Check if cache is stale
 */
export function isCacheStale(duration: number = CACHE_DURATION.MOMENTS): boolean {
  const lastSync = getLastSyncTime();
  if (!lastSync) return true;

  const now = Date.now();
  const timeSinceSync = now - lastSync.getTime();

  return timeSinceSync > duration;
}

/**
 * Format last sync time for display
 */
export function formatLastSync(): string {
  const lastSync = getLastSyncTime();
  if (!lastSync) return "Nie";

  const now = new Date();
  const diffMs = now.getTime() - lastSync.getTime();
  const diffMinutes = Math.floor(diffMs / (1000 * 60));

  if (diffMinutes < 1) return "Gerade eben";
  if (diffMinutes === 1) return "Vor 1 Minute";
  if (diffMinutes < 60) return `Vor ${diffMinutes} Minuten`;

  const diffHours = Math.floor(diffMinutes / 60);
  if (diffHours === 1) return "Vor 1 Stunde";
  if (diffHours < 24) return `Vor ${diffHours} Stunden`;

  const diffDays = Math.floor(diffHours / 24);
  if (diffDays === 1) return "Vor 1 Tag";
  return `Vor ${diffDays} Tagen`;
}

/**
 * Invalidate the moments cache
 * Call this after creating, updating, or deleting a moment
 */
export function invalidateMomentsCache(): void {
  clearCache(CACHE_KEYS.MOMENTS);
  clearCache(CACHE_KEYS.LAST_SYNC);
}

/**
 * Optimistically add a new moment to the cache
 * Useful for showing new moments immediately without waiting for API
 */
export function optimisticallyAddMoment<T>(newMoment: T): void {
  try {
    const cached = getCached<T[]>(CACHE_KEYS.MOMENTS) || [];
    const updated = [newMoment, ...cached]; // Add to beginning
    setCache(CACHE_KEYS.MOMENTS, updated);
  } catch (error) {
    console.error("Failed to optimistically add moment:", error);
    // Fallback: just invalidate cache
    invalidateMomentsCache();
  }
}

/**
 * Optimistically update a moment in the cache
 */
export function optimisticallyUpdateMoment<T extends { id: string }>(updatedMoment: T): void {
  try {
    const cached = getCached<T[]>(CACHE_KEYS.MOMENTS) || [];
    const updated = cached.map((m) => (m.id === updatedMoment.id ? updatedMoment : m));
    setCache(CACHE_KEYS.MOMENTS, updated);
  } catch (error) {
    console.error("Failed to optimistically update moment:", error);
    invalidateMomentsCache();
  }
}

/**
 * Optimistically remove a moment from the cache
 */
export function optimisticallyRemoveMoment(momentId: string): void {
  try {
    const cached = getCached<{ id: string }[]>(CACHE_KEYS.MOMENTS) || [];
    const updated = cached.filter((m) => m.id !== momentId);
    setCache(CACHE_KEYS.MOMENTS, updated);
  } catch (error) {
    console.error("Failed to optimistically remove moment:", error);
    invalidateMomentsCache();
  }
}
