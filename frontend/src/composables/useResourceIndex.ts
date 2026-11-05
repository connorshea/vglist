import { computed, onBeforeUnmount, ref, watch } from "vue";
import { useRoute, useRouter, type RouteLocationRaw } from "vue-router";
import type { DocumentNode } from "graphql";
import { useQuery } from "@/composables/useGraphQL";

/** The `sortBy` values shared by `SeriesSort` and `ResourceSort`. */
export type ResourceIndexSortValue = "MOST_GAMES" | "NAME" | "RECENTLY_ADDED";

export interface ResourceIndexSort {
  slug: string;
  label: string;
  value: ResourceIndexSortValue;
}

export const RESOURCE_INDEX_SORTS: ResourceIndexSort[] = [
  { slug: "most", label: "Most games", value: "MOST_GAMES" },
  { slug: "name", label: "A → Z", value: "NAME" },
  { slug: "recent", label: "Recently added", value: "RECENTLY_ADDED" }
];
const DEFAULT_SORT = RESOURCE_INDEX_SORTS[0];

export interface ResourceIndexSortLink {
  label: string;
  to: RouteLocationRaw;
  active: boolean;
}

export interface Connection<TNode> {
  totalCount: number;
  nodes: TNode[];
  pageInfo: { hasNextPage: boolean; endCursor: string | null };
}

interface Options<TData, TNode> {
  document: DocumentNode;
  /** The list connection in a response, e.g. `(data) => data.genres`. */
  connection: (data: TData) => Connection<TNode> | null | undefined;
  /** A copy of the response with the connection replaced. */
  withConnection: (data: TData, connection: Connection<TNode>) => TData;
  pageSize?: number;
}

const SEARCH_DEBOUNCE_MS = 250;
// The API's largest page (default_max_page_size in VideoGameListSchema).
const MAX_PAGE_SIZE = 100;

/**
 * State for a series, genre or platform index page: the sort and name search
 * (kept in the URL as `?sort=` and `?q=`, so a view can be reloaded, shared
 * and navigated back to), the list query, and loading more pages.
 */
export function useResourceIndex<TData, TNode extends { id: string }>(options: Options<TData, TNode>) {
  const route = useRoute();
  const router = useRouter();

  const sort = computed(() => RESOURCE_INDEX_SORTS.find((o) => o.slug === route.query.sort) ?? DEFAULT_SORT);
  const nameFilter = computed(() => (typeof route.query.q === "string" ? route.query.q.trim() : ""));

  function queryFor(option: ResourceIndexSort, q: string) {
    return {
      ...(option === DEFAULT_SORT ? {} : { sort: option.slug }),
      ...(q ? { q } : {})
    };
  }

  const sortLinks = computed<ResourceIndexSortLink[]>(() =>
    RESOURCE_INDEX_SORTS.map((option) => ({
      label: option.label,
      to: { query: queryFor(option, nameFilter.value) },
      active: option === sort.value
    }))
  );

  // The input updates the URL after a pause in typing rather than on every key.
  const searchText = ref(nameFilter.value);
  let searchTimer: ReturnType<typeof setTimeout> | undefined;

  watch(searchText, (text) => {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
      void router.replace({ query: queryFor(sort.value, text.trim()) });
    }, SEARCH_DEBOUNCE_MS);
  });

  // Back/forward to a different search puts its text back in the input.
  watch(nameFilter, (q) => {
    if (q !== searchText.value.trim()) searchText.value = q;
  });

  onBeforeUnmount(() => clearTimeout(searchTimer));

  const variables = computed(() => ({
    first: options.pageSize ?? 24,
    after: null as string | null,
    sortBy: sort.value.value,
    nameContains: nameFilter.value || null
  }));

  const { data, loading, error, fetchMore } = useQuery<TData>(options.document, {
    variables: () => variables.value
  });

  const list = computed(() => (data.value ? options.connection(data.value) : null));
  const nodes = computed(() => list.value?.nodes ?? []);
  const totalCount = computed(() => list.value?.totalCount ?? null);
  const hasNextPage = computed(() => list.value?.pageInfo.hasNextPage ?? false);

  const loadingMore = ref(false);
  // The grid is showing results for the previous sort or search.
  const refreshing = computed(() => loading.value && !loadingMore.value);

  async function loadMore() {
    const cursor = list.value?.pageInfo.endCursor;
    if (!cursor || loadingMore.value || refreshing.value) return;
    loadingMore.value = true;
    try {
      await fetchMore({ ...variables.value, after: cursor }, (prev, next) => {
        const prevList = options.connection(prev);
        const nextList = options.connection(next);
        if (!prevList || !nextList) return next;
        return options.withConnection(next, { ...nextList, nodes: [...prevList.nodes, ...nextList.nodes] });
      });
    } finally {
      loadingMore.value = false;
    }
  }

  /**
   * Drops a deleted record from the list without losing the reader's place.
   * Refetching would reload only the first page, so instead the pages loaded
   * so far are reloaded as one page. The rendered tiles are keyed by ID, so
   * the grid and the scroll position stay put. (Removing the record locally
   * isn't enough: cursors are offsets, so the next page would skip one.)
   */
  async function removeNode(id: string) {
    if (!data.value || !list.value) return;
    const loadedCount = list.value.nodes.filter((node) => node.id !== id).length;
    await fetchMore(
      { ...variables.value, first: Math.min(Math.max(loadedCount, 1), MAX_PAGE_SIZE) },
      (_prev, next) => next
    );
  }

  return {
    sortLinks,
    nameFilter,
    searchText,
    nodes,
    totalCount,
    hasNextPage,
    loaded: computed(() => data.value !== null),
    loading,
    loadingMore,
    refreshing,
    error,
    loadMore,
    removeNode
  };
}
