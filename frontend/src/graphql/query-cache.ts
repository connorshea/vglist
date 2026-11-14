import type { DocumentNode } from "graphql";
import { type SafeStorage, safeLocalStorage, safeSessionStorage } from "@/utils/safe-storage";

/**
 * A cache of query results, so `useQuery` can show what a page looked like
 * last time straight away (going back, switching tabs, reloading) while it
 * fetches the current data in the background: stale-while-revalidate.
 *
 * Entries live in memory and are mirrored to sessionStorage, so a reload
 * starts warm. sessionStorage rather than localStorage: it's per tab and gone
 * when the tab closes, so signed-in data doesn't sit on disk for long, and a
 * long-closed tab can't come back with very old data.
 *
 * The cache is deliberately blunt about staying correct:
 * - Any mutation clears all of it (see `client.ts`), since working out which
 *   queries a mutation affects isn't worth the bugs.
 * - Signing in or out clears it, since many fields depend on the viewer.
 * - Entries older than MAX_AGE_MS aren't shown at all; the page loads as if
 *   there were no cache.
 * - A response to a request that started before the cache was cleared isn't
 *   stored, so a query racing a mutation can't put pre-mutation data back.
 * - Stored entries remember who was signed in when they were fetched, and
 *   are dropped on load if that's changed (e.g. signed out in another tab).
 * - Stored entries from another build are dropped on load too, since a
 *   deploy can change what a query returns and the new code may not cope
 *   with the old shape.
 */

export const MAX_AGE_MS = 10 * 60 * 1000;
export const MAX_ENTRIES = 100;

interface Entry {
  data: unknown;
  storedAt: number;
}

interface StoredEntry extends Entry {
  viewer: string;
  build: string;
}

const STORAGE_PREFIX = "vglist-query-cache:";

// The commit SHA in production builds (set for Sentry, see frontend/Dockerfile).
const BUILD = import.meta.env.VITE_SENTRY_RELEASE ?? "dev";

// A Map iterates in insertion order, so re-inserting on every read and write
// keeps the least recently used entry first.
const entries = new Map<string, Entry>();
let generation = 0;
let hydrated = false;

// Whoever is signed in, read straight from what the auth store saves, since
// the auth store imports this module.
function currentViewer(): string {
  try {
    const user = JSON.parse(safeLocalStorage.getItem("auth_user") ?? "null") as { id?: unknown } | null;
    return typeof user?.id === "string" ? user.id : "";
  } catch {
    return "";
  }
}

// Storage can be missing or throw (private windows, blocked site data), and
// the cache must work the same without it. The wrapper's in-memory fallback
// would only duplicate `entries`, so skip it.
function storage(): SafeStorage | null {
  return safeSessionStorage.isPersistent() ? safeSessionStorage : null;
}

function storedKeys(store: SafeStorage): string[] {
  return store.keys().filter((key) => key.startsWith(STORAGE_PREFIX));
}

function removeStored(key: string): void {
  storage()?.removeItem(STORAGE_PREFIX + key);
}

// Loads what an earlier page load stored, oldest first so LRU order holds.
function hydrate(): void {
  if (hydrated) {
    return;
  }
  hydrated = true;
  const store = storage();
  if (!store) {
    return;
  }
  const viewer = currentViewer();
  const loaded: [string, Entry][] = [];
  for (const storageKey of storedKeys(store)) {
    let stored: StoredEntry | null = null;
    try {
      stored = JSON.parse(store.getItem(storageKey) ?? "null") as StoredEntry | null;
    } catch {
      stored = null;
    }
    if (!stored || stored.viewer !== viewer || stored.build !== BUILD || Date.now() - stored.storedAt > MAX_AGE_MS) {
      store.removeItem(storageKey);
      continue;
    }
    loaded.push([storageKey.slice(STORAGE_PREFIX.length), { data: stored.data, storedAt: stored.storedAt }]);
  }
  loaded.sort(([, a], [, b]) => a.storedAt - b.storedAt);
  for (const [key, entry] of loaded) {
    entries.set(key, entry);
  }
}

// Writes an entry to storage. When it's full, makes room by dropping the
// least recently used stored entries (they stay in memory), and gives up on
// storing this one if it still doesn't fit.
function persist(key: string, entry: Entry): void {
  const store = storage();
  if (!store) {
    return;
  }
  let value: string;
  try {
    value = JSON.stringify({ ...entry, viewer: currentViewer(), build: BUILD } satisfies StoredEntry);
  } catch {
    return;
  }
  const evictable = [...entries.keys()].filter((k) => k !== key);
  while (!store.setItem(STORAGE_PREFIX + key, value)) {
    const oldest = evictable.shift();
    if (oldest === undefined) {
      removeStored(key);
      return;
    }
    removeStored(oldest);
  }
}

function operationName(query: DocumentNode): string | null {
  for (const definition of query.definitions) {
    if (definition.kind === "OperationDefinition") {
      return definition.operation === "query" ? (definition.name?.value ?? null) : null;
    }
  }
  return null;
}

// JSON with object keys sorted, so `{ a, b }` and `{ b, a }` share an entry.
function stableStringify(value: unknown): string {
  return JSON.stringify(value, (_key, val: unknown) => {
    if (val && typeof val === "object" && !Array.isArray(val)) {
      return Object.fromEntries(Object.entries(val).sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0)));
    }
    return val;
  });
}

/**
 * The cache key for a query with these variables, or null if it can't be
 * cached (an anonymous operation, or not a query).
 */
export function queryCacheKey(query: DocumentNode, variables: unknown): string | null {
  const name = operationName(query);
  if (name === null) {
    return null;
  }
  return `${name}:${stableStringify(variables ?? {})}`;
}

/**
 * A copy of the cached result for `key`, or null. It's a copy so a page that
 * edits its data in place can't change what the next visit sees.
 */
export function readQueryCache<T>(key: string): T | null {
  hydrate();
  const entry = entries.get(key);
  if (!entry) {
    return null;
  }
  if (Date.now() - entry.storedAt > MAX_AGE_MS) {
    entries.delete(key);
    removeStored(key);
    return null;
  }
  entries.delete(key);
  entries.set(key, entry);
  return structuredClone(entry.data) as T;
}

/**
 * The current generation. Pass it back to `writeQueryCache` with the response
 * to a request that started now.
 */
export function queryCacheGeneration(): number {
  return generation;
}

/**
 * Stores a result, unless the cache has been cleared since the request for it
 * started (`requestGeneration` is out of date).
 */
export function writeQueryCache(key: string, data: unknown, requestGeneration: number): void {
  if (requestGeneration !== generation) {
    return;
  }
  hydrate();
  const entry = { data: structuredClone(data), storedAt: Date.now() };
  entries.delete(key);
  entries.set(key, entry);
  while (entries.size > MAX_ENTRIES) {
    const oldest = entries.keys().next().value;
    if (oldest === undefined) {
      break;
    }
    entries.delete(oldest);
    removeStored(oldest);
  }
  persist(key, entry);
}

export function clearQueryCache(): void {
  entries.clear();
  generation++;
  // Nothing stored by an earlier page load is wanted now either.
  hydrated = true;
  const store = storage();
  if (store) {
    for (const storageKey of storedKeys(store)) {
      store.removeItem(storageKey);
    }
  }
}
