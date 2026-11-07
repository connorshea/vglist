import { computed } from "vue";
import { useRoute, useRouter, type LocationQuery } from "vue-router";

// The query parameters a paged list keeps its place in.
const PAGE_KEYS = ["page", "after", "before"] as const;

/**
 * A query without a paged list's place in it, for a navigation that should
 * start the list over (a different tab or sort, say).
 */
export function withoutPage(query: LocationQuery): LocationQuery {
  const next = { ...query };
  for (const key of PAGE_KEYS) delete next[key];
  return next;
}

/**
 * Previous/next pagination over a GraphQL connection, kept in the query string
 * so each page is its own history entry: Back and Forward step through pages,
 * and a page survives a reload or being linked to.
 *
 * Next pages are fetched `after` the current page's end cursor and previous
 * pages `before` its start cursor, so no cursors need remembering between
 * pages. `page` is only the number shown; a page past the first needs a cursor.
 */
export function useCursorPages(pageSize: number) {
  const route = useRoute();
  const router = useRouter();

  const after = computed(() => (typeof route.query.after === "string" ? route.query.after : null));
  const before = computed(() =>
    after.value === null && typeof route.query.before === "string" ? route.query.before : null
  );

  const currentPage = computed(() => {
    if (after.value === null && before.value === null) return 1;
    const page = Number(route.query.page);
    return Number.isInteger(page) && page > 1 ? page : 2;
  });

  const variables = computed(() =>
    before.value === null
      ? { first: pageSize, after: currentPage.value > 1 ? after.value : null, last: null, before: null }
      : { first: null, after: null, last: pageSize, before: before.value }
  );

  function nextPage(endCursor: string | null | undefined) {
    if (!endCursor) return;
    void router.push({ query: { ...withoutPage(route.query), page: String(currentPage.value + 1), after: endCursor } });
  }

  function prevPage(startCursor: string | null | undefined) {
    if (currentPage.value <= 1) return;
    // The first page is the list with no cursor, whichever way it's reached.
    if (currentPage.value === 2 || !startCursor) {
      void router.push({ query: withoutPage(route.query) });
      return;
    }
    void router.push({
      query: { ...withoutPage(route.query), page: String(currentPage.value - 1), before: startCursor }
    });
  }

  return { currentPage, variables, nextPage, prevPage };
}
