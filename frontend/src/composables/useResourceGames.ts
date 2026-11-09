import { computed, nextTick, ref, watch, type Ref, type WritableComputedRef } from "vue";
import { useRoute, useRouter } from "vue-router";
import type { DocumentNode } from "graphql";
import { gqlClient } from "@/graphql/client";
import { useQuery } from "@/composables/useGraphQL";
import { extractGqlError } from "@/utils/graphql-errors";
import type { ResourceGameFieldsFragment, ResourceGameSort } from "@/types/graphql";

export const RESOURCE_GAMES_PAGE_SIZE = 30;

export interface ResourceGameConnection {
  nodes: ResourceGameFieldsFragment[];
  pageInfo: { hasNextPage: boolean; endCursor: string | null };
}

export interface ResourceGameSortOption {
  value: ResourceGameSort;
  // How the sort appears in the URL, e.g. `?sort=owners`.
  slug: string;
  label: string;
}

export const RESOURCE_GAME_SORTS: readonly ResourceGameSortOption[] = [
  { value: "NEWEST_RELEASE", slug: "newest", label: "Newest release" },
  { value: "MOST_OWNERS", slug: "owners", label: "Most owners" },
  { value: "HIGHEST_RATED", slug: "rating", label: "Highest rated" },
  { value: "NAME", slug: "name", label: "A → Z" }
];

const DEFAULT_SORT = RESOURCE_GAME_SORTS[0];

/**
 * The sort order for a resource page's games, kept in the `sort` query
 * parameter so it survives a reload and the back button. The default sort is
 * left out of the URL.
 */
export function useResourceGameSort(): WritableComputedRef<ResourceGameSort> {
  const route = useRoute();
  const router = useRouter();

  return computed({
    get() {
      const slug = route.query.sort;
      return (RESOURCE_GAME_SORTS.find((option) => option.slug === slug) ?? DEFAULT_SORT).value;
    },
    set(value) {
      const option = RESOURCE_GAME_SORTS.find((o) => o.value === value) ?? DEFAULT_SORT;
      const query = { ...route.query };
      if (option === DEFAULT_SORT) {
        delete query.sort;
      } else {
        query.sort = option.slug;
      }
      void router.replace({ query });
    }
  });
}

interface UseResourceGamesOptions<TData> {
  // Variables other than the sort order and pagination, e.g. the resource ID.
  variables: () => Record<string, unknown>;
  // Picks the games connection out of the query's result.
  select: (data: TData) => ResourceGameConnection | null | undefined;
}

/**
 * Loads a resource (company, platform, etc.) along with a sorted, paginated
 * list of its games. The first page comes with the resource itself; further
 * pages are appended with `loadMore`. Changing the sort refetches from the
 * first page.
 */
export function useResourceGames<TData>(query: DocumentNode, options: UseResourceGamesOptions<TData>) {
  const sortBy = useResourceGameSort();

  const baseVariables = () => ({
    ...options.variables(),
    sortBy: sortBy.value,
    first: RESOURCE_GAMES_PAGE_SIZE
  });

  const { data, loading, revalidating, error, whenRevalidated } = useQuery<TData>(query, { variables: baseVariables });

  const firstPage = computed(() => (data.value ? options.select(data.value) : null));

  const morePages = ref([]) as Ref<ResourceGameFieldsFragment[]>;
  const latestPageInfo = ref<ResourceGameConnection["pageInfo"] | null>(null);
  const loadingMore = ref(false);
  const loadMoreError = ref<string | null>(null);

  // Bumped whenever the list changes (new sort, tab or resource), so a page
  // that was still loading for the old list is thrown away.
  let generation = 0;

  function resetPages() {
    generation++;
    morePages.value = [];
    latestPageInfo.value = null;
    loadingMore.value = false;
    loadMoreError.value = null;
  }

  // Reset as soon as the variables change, not only once the new first page
  // arrives. Otherwise, while it loads, the extra pages of the old list (e.g.
  // the other company tab) stay on screen, and "Show more" would use the old
  // list's cursor.
  watch(() => JSON.stringify(baseVariables()), resetPages);
  watch(data, resetPages);

  const games = computed(() => [...(firstPage.value?.nodes ?? []), ...morePages.value]);
  const pageInfo = computed(() => latestPageInfo.value ?? firstPage.value?.pageInfo ?? null);
  const hasNextPage = computed(() => pageInfo.value?.hasNextPage ?? false);

  async function loadMore() {
    const cursor = pageInfo.value?.endCursor;
    // While a new first page loads, the cursor belongs to the old list.
    if (!hasNextPage.value || !cursor || loadingMore.value || loading.value) {
      return;
    }

    // A cached first page is being refreshed. When the fresh one lands it
    // resets the pages, which would throw this one away (or drop it from the
    // screen), so wait for it and load the page after the fresh first page.
    if (revalidating.value) {
      loadingMore.value = true;
      await whenRevalidated();
      // Let `watch(data, resetPages)` run first.
      await nextTick();
      loadingMore.value = false;
      await loadMore();
      return;
    }

    const requestGeneration = generation;
    loadingMore.value = true;
    loadMoreError.value = null;

    try {
      const result = await gqlClient.request<TData>(query, { ...baseVariables(), after: cursor });
      if (requestGeneration !== generation) {
        return;
      }
      const page = options.select(result);
      if (page) {
        morePages.value = [...morePages.value, ...page.nodes];
        latestPageInfo.value = page.pageInfo;
      }
    } catch (e) {
      if (requestGeneration !== generation) {
        return;
      }
      loadMoreError.value = extractGqlError(e);
    } finally {
      if (requestGeneration === generation) {
        loadingMore.value = false;
      }
    }
  }

  return { data, loading, error, sortBy, games, hasNextPage, loadMore, loadingMore, loadMoreError };
}
