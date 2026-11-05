import type { GamePurchaseCompletionStatus, GamePurchaseSort } from "@/types/graphql";

export interface LibraryStatus {
  key: GamePurchaseCompletionStatus;
  label: string;
  // The modifier for the status' colour, e.g. `st-in-progress`.
  className: string;
}

// The statuses in the order the library's filter rail lists them.
export const LIBRARY_STATUSES: readonly LibraryStatus[] = [
  { key: "IN_PROGRESS", label: "Playing", className: "st-in-progress" },
  { key: "PAUSED", label: "Paused", className: "st-paused" },
  { key: "UNPLAYED", label: "Unplayed", className: "st-unplayed" },
  { key: "COMPLETED", label: "Completed", className: "st-completed" },
  { key: "FULLY_COMPLETED", label: "100%", className: "st-fully-completed" },
  { key: "DROPPED", label: "Dropped", className: "st-dropped" },
  { key: "NOT_APPLICABLE", label: "N/A", className: "st-na" }
];

export const LIBRARY_SORTS: readonly { key: GamePurchaseSort; label: string }[] = [
  { key: "HIGHEST_RATING", label: "Highest rating" },
  { key: "MOST_HOURS_PLAYED", label: "Most hours played" },
  { key: "GAME_NAME", label: "Name (A–Z)" }
];

export const DEFAULT_LIBRARY_SORT: GamePurchaseSort = "HIGHEST_RATING";

export function libraryStatus(key: string | null | undefined): LibraryStatus | null {
  return LIBRARY_STATUSES.find((status) => status.key === key) ?? null;
}

export function isLibraryStatus(value: unknown): value is GamePurchaseCompletionStatus {
  return typeof value === "string" && libraryStatus(value) !== null;
}

export function isLibrarySort(value: unknown): value is GamePurchaseSort {
  return LIBRARY_SORTS.some((sort) => sort.key === value);
}

// The colour tier for a rating badge, matching the design system's
// `r-great`/`r-good`/`r-ok`/`r-low` classes.
export function ratingTier(rating: number): "r-great" | "r-good" | "r-ok" | "r-low" {
  if (rating >= 90) return "r-great";
  if (rating >= 75) return "r-good";
  if (rating >= 60) return "r-ok";
  return "r-low";
}

// Up to three initials for a game with no cover, e.g. "HK" for "Hollow Knight".
export function gameInitials(name: string): string {
  return name
    .split(/[\s:]+/)
    .filter((word) => word.length > 0)
    .slice(0, 3)
    .map((word) => word[0].toUpperCase())
    .join("");
}

// "31h", "2.5h", or null when there's nothing to show.
export function formatHours(hours: number | null | undefined): string | null {
  if (hours === null || hours === undefined || hours <= 0) return null;
  return `${Number.isInteger(hours) ? hours : hours.toFixed(1)}h`;
}

// "Sep 4" for a date this year, "Sep 4, 2024" otherwise. Dates are ISO 8601
// dates with no time, so they're parsed as UTC to keep the day from shifting.
export function formatStartDate(date: string, now: Date = new Date()): string {
  const parsed = new Date(`${date}T00:00:00Z`);
  const sameYear = parsed.getUTCFullYear() === now.getUTCFullYear();
  return parsed.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: sameYear ? undefined : "numeric",
    timeZone: "UTC"
  });
}

// Query-string values arrive as a string, an array, or nothing. Turn a
// comma-separated list of IDs into an array, dropping anything malformed.
export function parseIdList(value: unknown): string[] {
  const raw = Array.isArray(value) ? value.join(",") : typeof value === "string" ? value : "";
  return raw.split(",").filter((id) => /^\d+$/.test(id));
}

// A rating bound from the query string, or null if it's missing or invalid.
export function parseRating(value: unknown): number | null {
  if (typeof value !== "string" || !/^\d+$/.test(value)) return null;
  const rating = Number(value);
  return rating >= 0 && rating <= 100 ? rating : null;
}
