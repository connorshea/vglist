import type { GamePurchaseCompletionStatus, GameSort } from "@/types/graphql";

/** The four-digit year of an ISO 8601 date, or null if there isn't one. */
export function releaseYear(releaseDate: string | null | undefined): string | null {
  if (!releaseDate) return null;
  const year = releaseDate.slice(0, 4);
  return /^\d{4}$/.test(year) ? year : null;
}

const numberFormat = new Intl.NumberFormat("en-US");

export function formatNumber(count: number): string {
  return numberFormat.format(count);
}

/** "1,812 owners" / "1 owner". */
export function countLabel(count: number, singular: string, plural = `${singular}s`): string {
  return `${formatNumber(count)} ${count === 1 ? singular : plural}`;
}

/** "2021 · 612 owners", or whichever half of it the game has. */
export function tileMeta(game: { releaseDate?: string | null; owners?: { totalCount: number } | null }): string | null {
  const parts: string[] = [];
  const year = releaseYear(game.releaseDate);
  if (year) parts.push(year);
  if (game.owners && game.owners.totalCount > 0) parts.push(countLabel(game.owners.totalCount, "owner"));
  return parts.length > 0 ? parts.join(" · ") : null;
}

export type RatingTier = "great" | "good" | "ok" | "low";

/** Colour band for an average rating out of 100. */
export function ratingTier(rating: number): RatingTier {
  if (rating >= 90) return "great";
  if (rating >= 75) return "good";
  if (rating >= 60) return "ok";
  return "low";
}

const STATUS_LABELS: Record<GamePurchaseCompletionStatus, string> = {
  UNPLAYED: "Unplayed",
  IN_PROGRESS: "Playing",
  PAUSED: "Paused",
  DROPPED: "Dropped",
  COMPLETED: "Completed",
  FULLY_COMPLETED: "100%",
  NOT_APPLICABLE: "In library"
};

/** Label for the "in your library" badge on a game tile. */
export function libraryBadgeLabel(status: GamePurchaseCompletionStatus | null | undefined): string {
  return status ? STATUS_LABELS[status] : "In library";
}

/**
 * The sort tabs on the games index, keyed by the slug used in the URL's
 * `sort` query parameter. The first one is the default.
 */
export const GAME_SORTS = [
  { slug: "popular", label: "Popular", value: "MOST_OWNERS" },
  { slug: "new", label: "New releases", value: "RECENTLY_RELEASED" },
  { slug: "top", label: "Top rated", value: "HIGHEST_AVG_RATING" },
  { slug: "favorited", label: "Most favorited", value: "MOST_FAVORITES" },
  { slug: "added", label: "Recently added to vglist", value: "NEWEST" }
] as const satisfies readonly { slug: string; label: string; value: GameSort }[];

export type GameSortOption = (typeof GAME_SORTS)[number];

export const DEFAULT_GAME_SORT: GameSortOption = GAME_SORTS[0];

export function gameSortFromSlug(slug: unknown): GameSortOption {
  return GAME_SORTS.find((sort) => sort.slug === slug) ?? DEFAULT_GAME_SORT;
}

/** The filters set on the games index, as they appear in the URL. "" means unset. */
export interface GameFilters {
  platform: string;
  genre: string;
  engine: string;
  fromYear: string;
  toYear: string;
  hideLibrary: boolean;
}

export const EMPTY_FILTERS: GameFilters = {
  platform: "",
  genre: "",
  engine: "",
  fromYear: "",
  toYear: "",
  hideLibrary: false
};

export const EARLIEST_YEAR = 1950;

function yearParam(value: unknown): string {
  if (typeof value !== "string" || !/^\d{4}$/.test(value)) return "";
  return Number(value) >= EARLIEST_YEAR ? value : "";
}

function idParam(value: unknown): string {
  return typeof value === "string" && /^\d+$/.test(value) ? value : "";
}

/** Reads the filters out of a route's query, dropping anything malformed. */
export function filtersFromQuery(query: Record<string, unknown>): GameFilters {
  return {
    platform: idParam(query.platform),
    genre: idParam(query.genre),
    engine: idParam(query.engine),
    fromYear: yearParam(query.from),
    toYear: yearParam(query.to),
    hideLibrary: query.hide === "library"
  };
}

/** The URL query for a set of filters, leaving out the unset ones. */
export function filtersToQuery(filters: GameFilters): Record<string, string> {
  const query: Record<string, string> = {};
  if (filters.platform) query.platform = filters.platform;
  if (filters.genre) query.genre = filters.genre;
  if (filters.engine) query.engine = filters.engine;
  if (filters.fromYear) query.from = filters.fromYear;
  if (filters.toYear) query.to = filters.toYear;
  if (filters.hideLibrary) query.hide = "library";
  return query;
}

/** GraphQL variables for the games query's filter arguments. */
export function filterVariables(filters: GameFilters) {
  return {
    onPlatform: filters.platform || null,
    byGenre: filters.genre || null,
    byEngine: filters.engine || null,
    fromYear: filters.fromYear ? Number(filters.fromYear) : null,
    toYear: filters.toYear ? Number(filters.toYear) : null,
    excludeLibrary: filters.hideLibrary || null
  };
}

/** How many of the filters behind "More filters" are set. A year range counts once. */
export function moreFiltersCount(filters: GameFilters): number {
  return (
    (filters.genre ? 1 : 0) +
    (filters.engine ? 1 : 0) +
    (filters.fromYear || filters.toYear ? 1 : 0) +
    (filters.hideLibrary ? 1 : 0)
  );
}
