import { onScopeDispose, ref, watch } from "vue";

export const SEARCH_DEBOUNCE_MS = 200;

/**
 * Runs `search` for the latest non-blank `query`, once typing has paused for
 * `delay` ms. Answers to superseded searches are dropped, so slow responses
 * can't overwrite newer results. A failed search shows no results.
 */
export function useDebouncedSearch<T>(search: (query: string) => Promise<T[]>, delay = SEARCH_DEBOUNCE_MS) {
  const query = ref("");
  const results = ref<T[]>([]);
  // True from the first keystroke until the matching answer arrives, so the
  // list can say "Searching…" instead of a stale "No results".
  const searching = ref(false);

  let timer: ReturnType<typeof setTimeout> | undefined;
  let latestRequest = 0;

  async function run(q: string, requestId: number) {
    try {
      const found = await search(q);
      if (requestId === latestRequest) results.value = found;
    } catch {
      if (requestId === latestRequest) results.value = [];
    } finally {
      if (requestId === latestRequest) searching.value = false;
    }
  }

  watch(query, (value) => {
    clearTimeout(timer);
    const requestId = ++latestRequest;
    const q = value.trim();
    if (!q) {
      results.value = [];
      searching.value = false;
      return;
    }
    searching.value = true;
    timer = setTimeout(() => run(q, requestId), delay);
  });

  onScopeDispose(() => clearTimeout(timer));

  return { query, results, searching };
}
