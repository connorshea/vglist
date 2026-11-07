import { computed } from "vue";
import type { DocumentNode } from "graphql";
import { useQuery } from "@/composables/useGraphQL";
import { useUrlPage } from "@/composables/useUrlPage";
import { offsetCursor } from "@/utils/pagination";

export const FOLLOW_LIST_PAGE_SIZE = 48;

export interface FollowListUser {
  id: string;
  slug: string;
  username: string;
  avatarUrl?: string | null;
}

interface FollowConnection {
  nodes: FollowListUser[];
  pageInfo: { hasNextPage: boolean };
}

/**
 * Loads one page of a user's followers or following. The page number lives
 * in the URL (`?page=N`), so Back and Forward step between pages.
 */
interface UseFollowListOptions<TData> {
  slug: () => string;
  // Picks the followers or following connection out of the query's result.
  select: (data: TData) => FollowConnection | null | undefined;
}

export function useFollowList<TData>(query: DocumentNode, { slug, select }: UseFollowListOptions<TData>) {
  const { page, goToPage } = useUrlPage();

  const { data, loading, error } = useQuery<TData>(query, {
    variables: () => ({
      slug: slug(),
      first: FOLLOW_LIST_PAGE_SIZE,
      after: offsetCursor((page.value - 1) * FOLLOW_LIST_PAGE_SIZE)
    })
  });

  const connection = computed(() => (data.value ? select(data.value) : null));
  const users = computed(() => connection.value?.nodes ?? []);
  const hasNextPage = computed(() => connection.value?.pageInfo.hasNextPage ?? false);

  return { users, loading, error, page, hasNextPage, goToPage };
}
