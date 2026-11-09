import { describe, it, expect, vi, beforeEach } from "vitest";
import { defineComponent, nextTick, reactive, ref } from "vue";
import { mount, flushPromises } from "@vue/test-utils";
import { GET_COMPANY } from "@/graphql/queries/resources";
import type { GetCompanyQuery, ResourceGameFieldsFragment } from "@/types/graphql";
import { useResourceGames, type ResourceGameConnection } from "./useResourceGames";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockRequest, route } = vi.hoisted(() => {
  const route: { query: Record<string, string> } = { query: {} };
  return { mockRequest: vi.fn<(...args: unknown[]) => Promise<unknown>>(), route };
});

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("vue-router", () => ({
  useRoute: () => route,
  useRouter: () => ({ replace: vi.fn<(location: unknown) => Promise<void>>() })
}));

function deferred<T>() {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((res) => {
    resolve = res;
  });
  return { promise, resolve };
}

function game(id: string): ResourceGameFieldsFragment {
  return { id, name: `Game ${id}`, coverUrl: null, releaseDate: null, isInLibrary: null };
}

function connection(ids: string[], endCursor: string, hasNextPage = true): ResourceGameConnection {
  return { nodes: ids.map(game), pageInfo: { hasNextPage, endCursor } };
}

function companyResult(games: { developed?: ResourceGameConnection; published?: ResourceGameConnection }) {
  return {
    company: {
      id: "1",
      name: "Supergiant Games",
      wikidataId: null,
      developedCount: { totalCount: 60 },
      publishedCount: { totalCount: 60 },
      developedGames: games.developed,
      publishedGames: games.published
    }
  } as GetCompanyQuery;
}

/**
 * Mounts a component around `useResourceGames` for a company, with a ref to
 * switch between the Developed and Published tabs.
 */
function mountCompanyGames() {
  const developed = ref(true);
  let composable: ReturnType<typeof useResourceGames<GetCompanyQuery>> | null = null;

  mount(
    defineComponent({
      setup() {
        composable = useResourceGames<GetCompanyQuery>(GET_COMPANY, {
          variables: () => ({ id: "1", developed: developed.value }),
          select: (result) => (developed.value ? result.company?.developedGames : result.company?.publishedGames)
        });
        return () => null;
      }
    })
  );

  return { developed, games: () => composable! };
}

// ── Tests ─────────────────────────────────────────────────────────

describe("useResourceGames", () => {
  beforeEach(() => {
    mockRequest.mockReset();
    route.query = reactive({});
  });

  it("drops the old tab's extra pages as soon as the tab changes", async () => {
    const publishedPage = deferred<GetCompanyQuery>();
    mockRequest
      .mockResolvedValueOnce(companyResult({ developed: connection(["d1"], "dev-30") }))
      .mockResolvedValueOnce(companyResult({ developed: connection(["d2"], "dev-60") }))
      .mockReturnValueOnce(publishedPage.promise);

    const { developed, games } = mountCompanyGames();
    await flushPromises();

    await games().loadMore();
    expect(games().games.value.map((g) => g.id)).toEqual(["d1", "d2"]);

    // Switch tabs while the published games are still loading.
    developed.value = false;
    await nextTick();

    expect(games().games.value.map((g) => g.id)).toEqual([]);
    expect(games().hasNextPage.value).toBeFalsy();

    publishedPage.resolve(companyResult({ published: connection(["p1"], "pub-30") }));
    await flushPromises();

    expect(games().games.value.map((g) => g.id)).toEqual(["p1"]);
  });

  it("waits for a cached first page to refresh before loading more, and keeps the page", async () => {
    // A first visit caches the first page.
    mockRequest.mockResolvedValueOnce(companyResult({ developed: connection(["d1"], "stale-30") }));
    mountCompanyGames();
    await flushPromises();

    const fresh = deferred<GetCompanyQuery>();
    mockRequest
      .mockReturnValueOnce(fresh.promise)
      .mockResolvedValueOnce(companyResult({ developed: connection(["d2"], "fresh-60") }));
    const { games } = mountCompanyGames();
    expect(games().games.value.map((g) => g.id)).toEqual(["d1"]);

    const loaded = games().loadMore();
    await flushPromises();
    expect(games().loadingMore.value).toBeTruthy();
    expect(mockRequest).toHaveBeenCalledTimes(2);

    fresh.resolve(companyResult({ developed: connection(["d1-new"], "fresh-30") }));
    await loaded;

    expect(mockRequest).toHaveBeenCalledTimes(3);
    expect(mockRequest).toHaveBeenLastCalledWith(GET_COMPANY, expect.objectContaining({ after: "fresh-30" }));
    expect(games().games.value.map((g) => g.id)).toEqual(["d1-new", "d2"]);
    expect(games().loadingMore.value).toBeFalsy();
  });

  it("doesn't load more with the old list's cursor while a new sort loads", async () => {
    const newSortPage = deferred<GetCompanyQuery>();
    mockRequest
      .mockResolvedValueOnce(companyResult({ developed: connection(["d1"], "dev-30") }))
      .mockReturnValueOnce(newSortPage.promise);

    const { games } = mountCompanyGames();
    await flushPromises();

    route.query.sort = "name";
    await nextTick();

    await games().loadMore();
    expect(mockRequest).toHaveBeenCalledTimes(2);

    newSortPage.resolve(companyResult({ developed: connection(["a1"], "name-30") }));
    await flushPromises();

    expect(games().games.value.map((g) => g.id)).toEqual(["a1"]);
  });
});
