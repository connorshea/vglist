import { ref, watch, onBeforeMount, type Ref, isRef } from "vue";
import type { DocumentNode } from "graphql";
import { gqlClient } from "@/graphql/client";
import { queryCacheGeneration, queryCacheKey, readQueryCache, writeQueryCache } from "@/graphql/query-cache";
import { extractGqlError } from "@/utils/graphql-errors";

type MaybeRefOrGetter<T> = T | Ref<T> | (() => T);

function resolveValue<T>(source: MaybeRefOrGetter<T>): T {
  if (isRef(source)) {
    return source.value;
  }
  if (typeof source === "function") {
    return (source as () => T)();
  }
  return source;
}

// Errors are exposed to templates as `error.message`, so make sure that
// message is the human-readable GraphQL error rather than graphql-request's
// raw `ClientError.message`, which embeds the request variables as JSON.
function toDisplayError(e: unknown): Error {
  return new Error(extractGqlError(e));
}

interface UseQueryOptions<TVariables> {
  variables?: MaybeRefOrGetter<TVariables>;
  enabled?: MaybeRefOrGetter<boolean>;
  /**
   * Whether to show a cached result straight away while fetching a fresh one
   * (stale-while-revalidate). Defaults to true. Turn it off for queries that
   * seed a form, so a fresh result arriving a moment later can't overwrite
   * what someone has started typing.
   */
  cache?: boolean;
}

interface UseQueryReturn<TData> {
  data: Ref<TData | null>;
  // True only while nothing can be shown yet. A page showing a cached result
  // isn't loading, it's `revalidating`.
  loading: Ref<boolean>;
  error: Ref<Error | null>;
  // True while a cached result is on screen and a fresh one is on its way.
  revalidating: Ref<boolean>;
  refetch: () => Promise<void>;
  /**
   * Loads another page and merges it in. If a cached result is being
   * refreshed, this waits for the fresh one first, so pass the variables as a
   * function that reads the cursor from `data` when it's called (returning
   * null to skip, e.g. when the fresh result has no next page).
   */
  fetchMore: (variables: FetchMoreVariables, merge: (prev: TData, next: TData) => TData) => Promise<void>;
  // Resolves once no cached result is being refreshed.
  whenRevalidated: () => Promise<void>;
}

type FetchMoreVariables = Record<string, unknown> | (() => Record<string, unknown> | null);

export function useQuery<TData = Record<string, unknown>, TVariables = Record<string, unknown>>(
  query: DocumentNode,
  options?: UseQueryOptions<TVariables>
): UseQueryReturn<TData> {
  const data = ref<TData | null>(null) as Ref<TData | null>;
  const loading = ref(false);
  const revalidating = ref(false);
  const error = ref<Error | null>(null);
  const useCache = options?.cache !== false;

  // Requests are numbered so a response that has been superseded by a newer
  // one can be discarded. Without this, two in-flight requests (e.g. after a
  // reactive variable changes twice) race, and whichever the server answers
  // last wins — which may be the older one.
  let latestRequestId = 0;

  // Settles when the newest refresh of a cached result does (see
  // `whenRevalidated`).
  let revalidation: Promise<void> = Promise.resolve();

  // A disabled query must not write state, and `enabled` can flip to false
  // while a request is in flight (e.g. navigating from an edit route to a new
  // one in a component vue-router reuses). Bailing out of `execute` doesn't
  // touch `latestRequestId`, so the in-flight request would otherwise still
  // count as the newest and apply its result.
  function isEnabled() {
    return options?.enabled === undefined || resolveValue(options.enabled);
  }

  // With `showCached`, a cached result for these variables is shown right away
  // and the request only refreshes it. `refetch` leaves it off: whoever calls
  // it wants the fresh result, and is showing their own data meanwhile.
  async function execute(showCached = false) {
    if (!isEnabled()) {
      return;
    }

    const requestId = ++latestRequestId;
    const variables = options?.variables ? resolveValue(options.variables) : undefined;
    const cacheKey = useCache ? queryCacheKey(query, variables) : null;
    const cached = showCached && cacheKey ? readQueryCache<TData>(cacheKey) : null;
    const generation = queryCacheGeneration();
    let settleRevalidation: (() => void) | undefined;
    if (cached) {
      data.value = cached;
      loading.value = false;
      revalidating.value = true;
      revalidation = new Promise((resolve) => {
        settleRevalidation = resolve;
      });
    } else {
      loading.value = true;
      revalidating.value = false;
    }
    error.value = null;

    try {
      const result = await gqlClient.request<TData>(query, variables as Record<string, unknown>);
      // Stored even when superseded: it's still the right result for its own
      // variables.
      if (cacheKey) {
        writeQueryCache(cacheKey, result, generation);
      }
      if (requestId !== latestRequestId || !isEnabled()) {
        return;
      }
      data.value = result;
    } catch (e) {
      if (requestId !== latestRequestId || !isEnabled()) {
        return;
      }
      error.value = toDisplayError(e);
    } finally {
      // Only the newest request owns the loading flag, so a superseded
      // response can't clear it while its replacement is still in flight.
      if (requestId === latestRequestId) {
        loading.value = false;
        revalidating.value = false;
      }
      settleRevalidation?.();
    }
  }

  async function whenRevalidated() {
    // A newer refresh may have started by the time this one settles.
    while (revalidating.value) {
      await revalidation;
    }
  }

  async function fetchMore(variables: FetchMoreVariables, merge: (prev: TData, next: TData) => TData) {
    // Loading a page now would supersede the refresh, leaving the stale first
    // page on screen with a fresh second page after it. Wait for the fresh
    // first page and take the cursor from that instead.
    if (revalidating.value) {
      await whenRevalidated();
      // Different variables are loading meanwhile, so this page belongs to
      // the old list.
      if (loading.value) {
        return;
      }
    }
    const resolvedVariables = typeof variables === "function" ? variables() : variables;
    if (!resolvedVariables) {
      return;
    }

    // Shares the counter with `execute` so that loading another page and
    // re-running the base query can't interleave into a mangled result.
    const requestId = ++latestRequestId;
    loading.value = true;
    revalidating.value = false;
    try {
      const nextData = await gqlClient.request<TData>(query, resolvedVariables);
      if (requestId !== latestRequestId || !isEnabled()) {
        return;
      }
      if (data.value) {
        data.value = merge(data.value, nextData);
      } else {
        data.value = nextData;
      }
    } catch (e) {
      if (requestId !== latestRequestId || !isEnabled()) {
        return;
      }
      error.value = toDisplayError(e);
    } finally {
      if (requestId === latestRequestId) {
        loading.value = false;
      }
    }
  }

  // Re-execute when the reactive variables or the enabled flag change. One
  // watcher covers both, so a change that does both at once (new variables
  // and newly enabled) sends one request rather than two. `execute` bails out
  // while disabled.
  const sources: (() => unknown)[] = [];
  if (options?.variables && (isRef(options.variables) || typeof options.variables === "function")) {
    sources.push(
      typeof options.variables === "function"
        ? (options.variables as () => TVariables)
        : () => (options.variables as Ref<TVariables>).value
    );
  }
  if (options?.enabled && (isRef(options.enabled) || typeof options.enabled === "function")) {
    sources.push(
      typeof options.enabled === "function" ? options.enabled : () => (options.enabled as Ref<boolean>).value
    );
  }
  if (sources.length) {
    watch(
      sources,
      () => {
        void execute(true);
      },
      { deep: true }
    );
  }

  // Before mount rather than on it, so a cached result is in the first render
  // instead of replacing a loading state a frame later.
  onBeforeMount(() => {
    void execute(true);
  });

  return { data, loading, revalidating, error, refetch: () => execute(), fetchMore, whenRevalidated };
}

interface UseMutationReturn<TData, TVariables> {
  mutate: (variables?: TVariables) => Promise<TData>;
  data: Ref<TData | null>;
  loading: Ref<boolean>;
  error: Ref<Error | null>;
}

export function useMutation<TData = Record<string, unknown>, TVariables = Record<string, unknown>>(
  mutation: DocumentNode
): UseMutationReturn<TData, TVariables> {
  const data = ref<TData | null>(null) as Ref<TData | null>;
  const loading = ref(false);
  const error = ref<Error | null>(null);

  async function mutate(variables?: TVariables): Promise<TData> {
    loading.value = true;
    error.value = null;

    try {
      const result = await gqlClient.request<TData>(mutation, variables as Record<string, unknown>);
      data.value = result;
      return result;
    } catch (e) {
      error.value = toDisplayError(e);
      throw e;
    } finally {
      loading.value = false;
    }
  }

  return { mutate, data, loading, error };
}
