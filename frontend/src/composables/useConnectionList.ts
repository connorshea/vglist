import { computed, onMounted, ref, type Ref } from "vue";
import type { DocumentNode } from "graphql";
import { gqlClient } from "@/graphql/client";
import { extractGqlError } from "@/utils/graphql-errors";

// The API's `default_max_page_size`. A reload asks for at most this many rows
// at once.
const MAX_PAGE_SIZE = 100;

export interface ConnectionPage<TNode> {
  nodes: TNode[];
  pageInfo: { hasNextPage: boolean; endCursor?: string | null };
}

interface UseConnectionListOptions<TData, TNode> {
  // Picks the connection out of the query's result.
  select: (data: TData) => ConnectionPage<TNode> | null | undefined;
  pageSize?: number;
}

/**
 * Loads a GraphQL connection that takes `first` and `after`, one page at a
 * time. Further pages are appended with `loadMore`.
 *
 * `reload` fetches as many rows as are already on screen, so a mutation
 * doesn't throw away the pages the user has loaded. The API's cursors are
 * offsets, so removing a row would otherwise make the next page skip one.
 */
export function useConnectionList<TData, TNode>(query: DocumentNode, options: UseConnectionListOptions<TData, TNode>) {
  const pageSize = options.pageSize ?? 50;

  const nodes = ref([]) as Ref<TNode[]>;
  const pageInfo = ref<ConnectionPage<TNode>["pageInfo"] | null>(null);
  // True once the first page has arrived. A reload keeps the old rows on
  // screen until the new ones are in.
  const loaded = ref(false);
  const loading = ref(false);
  const error = ref<string | null>(null);
  const loadingMore = ref(false);
  const loadMoreError = ref<string | null>(null);

  // Bumped by every reload, so a page that was still loading for the old
  // list is thrown away.
  let generation = 0;

  async function fetchPage(first: number, after: string | null): Promise<ConnectionPage<TNode>> {
    const data = await gqlClient.request<TData>(query, { first, after });
    return options.select(data) ?? { nodes: [], pageInfo: { hasNextPage: false, endCursor: null } };
  }

  async function reload() {
    const requestGeneration = ++generation;
    const target = Math.max(nodes.value.length, pageSize);
    loading.value = true;
    error.value = null;
    loadingMore.value = false;
    loadMoreError.value = null;

    try {
      const collected: TNode[] = [];
      let info: ConnectionPage<TNode>["pageInfo"] = { hasNextPage: false, endCursor: null };
      let after: string | null = null;
      do {
        const page = await fetchPage(Math.min(MAX_PAGE_SIZE, target - collected.length), after);
        if (requestGeneration !== generation) {
          return;
        }
        collected.push(...page.nodes);
        info = page.pageInfo;
        after = info.endCursor ?? null;
        if (page.nodes.length === 0) {
          break;
        }
      } while (collected.length < target && info.hasNextPage && after);

      nodes.value = collected;
      pageInfo.value = info;
      loaded.value = true;
    } catch (e) {
      if (requestGeneration !== generation) {
        return;
      }
      error.value = extractGqlError(e);
    } finally {
      if (requestGeneration === generation) {
        loading.value = false;
      }
    }
  }

  const hasNextPage = computed(() => pageInfo.value?.hasNextPage ?? false);

  async function loadMore() {
    const cursor = pageInfo.value?.endCursor;
    if (!hasNextPage.value || !cursor || loadingMore.value || loading.value) {
      return;
    }

    const requestGeneration = generation;
    loadingMore.value = true;
    loadMoreError.value = null;

    try {
      const page = await fetchPage(pageSize, cursor);
      if (requestGeneration !== generation) {
        return;
      }
      nodes.value = [...nodes.value, ...page.nodes];
      pageInfo.value = page.pageInfo;
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

  onMounted(() => {
    void reload();
  });

  return { nodes, loaded, loading, error, hasNextPage, loadMore, loadingMore, loadMoreError, reload };
}
