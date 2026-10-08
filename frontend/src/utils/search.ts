import type { LocationQuery } from "vue-router";
import type { SearchableEnum, SearchGameFieldsFragment, SearchUserFieldsFragment } from "@/types/graphql";

export const MIN_QUERY_LENGTH = 2;

// Keys double as the `?type=` values, the aliases in the search queries, and
// the first segment of each record's URL (`/games/:id`, `/stores/:id`, ...).
export type SearchTypeKey = "games" | "companies" | "platforms" | "series" | "engines" | "genres" | "stores" | "users";
export type SearchTabKey = "all" | SearchTypeKey;
export type NamedSearchTypeKey = Exclude<SearchTypeKey, "games" | "users">;

export const SEARCH_TABS: readonly { key: SearchTabKey; label: string }[] = [
  { key: "all", label: "All" },
  { key: "games", label: "Games" },
  { key: "companies", label: "Companies" },
  { key: "platforms", label: "Platforms" },
  { key: "series", label: "Series" },
  { key: "engines", label: "Engines" },
  { key: "genres", label: "Genres" },
  { key: "stores", label: "Stores" },
  { key: "users", label: "Users" }
];

// Game rows select a lot more (platforms, companies, series), and signed-out
// visitors are held to the API's complexity limit, so they get smaller pages.
// `spec/requests/api/search_complexity_spec.rb` reads these constants.
export const GAMES_PAGE_SIZE = 10;
export const PAGE_SIZE = 25;

export function pageSizeFor(tab: SearchTypeKey): number {
  return tab === "games" ? GAMES_PAGE_SIZE : PAGE_SIZE;
}

function firstValue(value: LocationQuery[string] | undefined): string {
  const first = Array.isArray(value) ? value[0] : value;
  return first ?? "";
}

export function parseSearchState(params: LocationQuery): { query: string; tab: SearchTabKey } {
  const type = firstValue(params.type);
  return {
    query: firstValue(params.query).trim(),
    tab: SEARCH_TABS.find((t) => t.key === type)?.key ?? "all"
  };
}

// `id` is the user's slug for users, since their URLs use slugs.
export function recordPath(type: SearchTypeKey, id: string): string {
  return `/${type}/${id}`;
}

const SEARCHABLE_TYPE_KEYS: Record<SearchableEnum, SearchTypeKey> = {
  GAME: "games",
  COMPANY: "companies",
  PLATFORM: "platforms",
  SERIES: "series",
  ENGINE: "engines",
  GENRE: "genres",
  USER: "users"
};

// `globalSearch` (the overlay) identifies results by `SearchableEnum`.
export function searchableTypeKey(type: SearchableEnum): SearchTypeKey {
  return SEARCHABLE_TYPE_KEYS[type];
}

interface NamedRecord {
  id: string;
  name: string;
}

interface Connection<T> {
  totalCount: number;
  nodes: T[];
}

export type SearchSection =
  | { type: "games"; totalCount: number; nodes: SearchGameFieldsFragment[] }
  | { type: "users"; totalCount: number; nodes: SearchUserFieldsFragment[] }
  | { type: NamedSearchTypeKey; totalCount: number; nodes: NamedRecord[] };

// The shape both search queries share: one optional connection per type.
export type SearchConnections = {
  games?: Connection<SearchGameFieldsFragment> | null;
  users?: Connection<SearchUserFieldsFragment> | null;
} & { [K in NamedSearchTypeKey]?: Connection<NamedRecord> | null };

// One type's results out of a search response, tagged with its type so rows
// can be rendered without checking `__typename`.
export function searchSection(data: SearchConnections, type: SearchTypeKey): SearchSection | null {
  if (type === "games") return data.games ? { type, totalCount: data.games.totalCount, nodes: data.games.nodes } : null;
  if (type === "users") return data.users ? { type, totalCount: data.users.totalCount, nodes: data.users.nodes } : null;
  const connection = data[type];
  return connection ? { type, totalCount: connection.totalCount, nodes: connection.nodes } : null;
}
