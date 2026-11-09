import type { DocumentNode } from "graphql";

/**
 * An in-memory cache of query results, so `useQuery` can show what a page
 * looked like last time straight away (going back, switching tabs) while it
 * fetches the current data in the background: stale-while-revalidate.
 *
 * The cache is deliberately blunt about staying correct:
 * - Any mutation clears all of it (see `client.ts`), since working out which
 *   queries a mutation affects isn't worth the bugs.
 * - Signing in or out clears it, since many fields depend on the viewer.
 * - Entries older than MAX_AGE_MS aren't shown at all; the page loads as if
 *   there were no cache.
 * - A response to a request that started before the cache was cleared isn't
 *   stored, so a query racing a mutation can't put pre-mutation data back.
 */

export const MAX_AGE_MS = 10 * 60 * 1000;
export const MAX_ENTRIES = 100;

interface Entry {
  data: unknown;
  storedAt: number;
}

// A Map iterates in insertion order, so re-inserting on every read and write
// keeps the least recently used entry first.
const entries = new Map<string, Entry>();
let generation = 0;

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
  const entry = entries.get(key);
  if (!entry) {
    return null;
  }
  if (Date.now() - entry.storedAt > MAX_AGE_MS) {
    entries.delete(key);
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
  entries.delete(key);
  entries.set(key, { data: structuredClone(data), storedAt: Date.now() });
  while (entries.size > MAX_ENTRIES) {
    const oldest = entries.keys().next().value;
    if (oldest === undefined) {
      break;
    }
    entries.delete(oldest);
  }
}

export function clearQueryCache(): void {
  entries.clear();
  generation++;
}
