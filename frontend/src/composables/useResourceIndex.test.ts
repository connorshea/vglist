import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { defineComponent, nextTick, reactive } from "vue";
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { parse } from "graphql";
import { useResourceIndex, type Connection } from "./useResourceIndex";

interface Node {
  id: string;
  name: string;
}
interface Data {
  genres: Connection<Node> | null;
}

const { state, replace, mockRequest } = vi.hoisted(() => ({
  state: { route: { query: {} } },
  replace: vi.fn<(location: { query: Record<string, string> }) => Promise<void>>(),
  mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>()
}));

vi.mock("vue-router", () => ({
  useRoute: () => state.route,
  useRouter: () => ({ replace })
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

enableAutoUnmount(afterEach);

const document = parse("query GetGenres { genres { totalCount } }");

function page(ids: number[], { hasNextPage = true, total = 100 } = {}): Data {
  return {
    genres: {
      totalCount: total,
      nodes: ids.map((id) => ({ id: String(id), name: `Genre ${id}` })),
      pageInfo: { hasNextPage, endCursor: ids.length ? `cursor-${ids[ids.length - 1]}` : null }
    }
  };
}

function range(from: number, to: number): number[] {
  return Array.from({ length: to - from + 1 }, (_, i) => from + i);
}

let wrapper: ReturnType<typeof mount> | null = null;

function mountIndex(pageSize = 3) {
  let result: ReturnType<typeof useResourceIndex<Data, Node>> | null = null;
  wrapper = mount(
    defineComponent({
      setup() {
        result = useResourceIndex<Data, Node>({
          document,
          connection: (data) => data.genres,
          withConnection: (data, genres) => ({ ...data, genres }),
          pageSize
        });
        return () => null;
      }
    })
  );
  return result!;
}

function lastVariables(): Record<string, unknown> | undefined {
  return mockRequest.mock.calls.at(-1)?.[1];
}

describe("useResourceIndex", () => {
  beforeEach(() => {
    state.route = reactive({ query: {} });
    replace.mockReset();
    mockRequest.mockReset();
    mockRequest.mockResolvedValue(page([1, 2, 3]));
  });

  describe("sort and search from the URL", () => {
    it("fetches the default sort with no name filter", async () => {
      mountIndex(3);
      await flushPromises();
      expect(lastVariables()).toEqual({ first: 3, after: null, sortBy: "MOST_GAMES", nameContains: null });
    });

    it("reads the sort and a trimmed name filter", async () => {
      state.route.query = { sort: "name", q: "  rpg " };
      const index = mountIndex();
      await flushPromises();
      expect(lastVariables()).toMatchObject({ sortBy: "NAME", nameContains: "rpg" });
      expect(index.nameFilter.value).toBe("rpg");
      expect(index.searchText.value).toBe("rpg");
    });

    it("falls back to the default sort for an unknown slug", async () => {
      state.route.query = { sort: "bogus" };
      mountIndex();
      await flushPromises();
      expect(lastVariables()).toMatchObject({ sortBy: "MOST_GAMES" });
    });

    it("links each sort with the search kept, leaving the default sort out of the URL", () => {
      state.route.query = { sort: "recent", q: "rpg" };
      expect(mountIndex().sortLinks.value).toEqual([
        { label: "Most games", to: { query: { q: "rpg" } }, active: false },
        { label: "A → Z", to: { query: { sort: "name", q: "rpg" } }, active: false },
        { label: "Recently added", to: { query: { sort: "recent", q: "rpg" } }, active: true }
      ]);
    });

    it("refetches when the URL changes", async () => {
      mountIndex();
      await flushPromises();
      state.route.query = { sort: "name" };
      await flushPromises();
      expect(mockRequest).toHaveBeenCalledTimes(2);
      expect(lastVariables()).toMatchObject({ sortBy: "NAME" });
    });
  });

  describe("search input", () => {
    beforeEach(() => {
      vi.useFakeTimers({ toFake: ["setTimeout", "clearTimeout"] });
    });

    afterEach(() => {
      vi.useRealTimers();
    });

    it("updates the URL once typing pauses, keeping the sort", async () => {
      state.route.query = { sort: "name" };
      const index = mountIndex();
      index.searchText.value = "r";
      await nextTick();
      vi.advanceTimersByTime(100);
      index.searchText.value = "rpg ";
      await nextTick();
      vi.advanceTimersByTime(249);
      expect(replace).not.toHaveBeenCalled();
      vi.advanceTimersByTime(1);
      expect(replace).toHaveBeenCalledTimes(1);
      expect(replace).toHaveBeenCalledWith({ query: { sort: "name", q: "rpg" } });
    });

    it("drops `q` from the URL when the input is cleared", async () => {
      state.route.query = { q: "rpg" };
      const index = mountIndex();
      index.searchText.value = "   ";
      await nextTick();
      vi.advanceTimersByTime(250);
      expect(replace).toHaveBeenCalledWith({ query: {} });
    });

    it("doesn't update the URL after unmounting", async () => {
      const index = mountIndex();
      index.searchText.value = "rpg";
      await nextTick();
      wrapper?.unmount();
      vi.advanceTimersByTime(250);
      expect(replace).not.toHaveBeenCalled();
    });
  });

  describe("back and forward", () => {
    it("puts a different search's text back in the input", async () => {
      state.route.query = { q: "rpg" };
      const index = mountIndex();
      state.route.query = { q: "puzzle" };
      await nextTick();
      expect(index.searchText.value).toBe("puzzle");
    });

    it("leaves the input alone when only trailing spaces differ", async () => {
      const index = mountIndex();
      index.searchText.value = "rpg ";
      state.route.query = { q: "rpg" };
      await nextTick();
      expect(index.searchText.value).toBe("rpg ");
    });
  });

  describe("loadMore", () => {
    it("appends the next page fetched after the end cursor", async () => {
      const index = mountIndex(3);
      await flushPromises();
      mockRequest.mockResolvedValueOnce(page([4, 5, 6]));
      await index.loadMore();
      expect(lastVariables()).toEqual({ first: 3, after: "cursor-3", sortBy: "MOST_GAMES", nameContains: null });
      expect(index.nodes.value.map((n) => n.id)).toEqual(["1", "2", "3", "4", "5", "6"]);
      expect(index.loadingMore.value).toBeFalsy();
    });

    it("does nothing without an end cursor", async () => {
      mockRequest.mockResolvedValue(page([]));
      const index = mountIndex();
      await flushPromises();
      await index.loadMore();
      expect(mockRequest).toHaveBeenCalledTimes(1);
    });

    it("doesn't load the same page twice when called again while loading", async () => {
      const index = mountIndex();
      await flushPromises();
      let resolvePage: (value: Data) => void = () => {};
      mockRequest.mockReturnValueOnce(new Promise((resolve) => (resolvePage = resolve)));
      const first = index.loadMore();
      await nextTick();
      expect(index.loadingMore.value).toBeTruthy();
      await index.loadMore();
      resolvePage(page([4, 5, 6]));
      await first;
      expect(mockRequest).toHaveBeenCalledTimes(2);
      expect(index.nodes.value).toHaveLength(6);
    });

    it("doesn't load more while a new sort or search is loading", async () => {
      const index = mountIndex();
      await flushPromises();
      mockRequest.mockReturnValueOnce(new Promise(() => {}));
      state.route.query = { sort: "name" };
      await nextTick();
      expect(index.refreshing.value).toBeTruthy();
      await index.loadMore();
      expect(mockRequest).toHaveBeenCalledTimes(2);
    });

    it("clears loadingMore when the page fails", async () => {
      const index = mountIndex();
      await flushPromises();
      mockRequest.mockRejectedValueOnce(new Error("boom"));
      await index.loadMore().catch(() => {});
      expect(index.loadingMore.value).toBeFalsy();
    });
  });

  describe("removeNode", () => {
    it("reloads the pages loaded so far as one page, minus the removed record", async () => {
      const index = mountIndex(3);
      await flushPromises();
      mockRequest.mockResolvedValueOnce(page([4, 5, 6]));
      await index.loadMore();

      mockRequest.mockResolvedValueOnce(page([1, 2, 4, 5, 6]));
      await index.removeNode("3");
      // Five left of six loaded, from the start of the list rather than a
      // cursor, since removing a record shifts every offset after it.
      expect(lastVariables()).toEqual({ first: 5, after: null, sortBy: "MOST_GAMES", nameContains: null });
      expect(index.nodes.value.map((n) => n.id)).toEqual(["1", "2", "4", "5", "6"]);
    });

    it("asks for at least one record after removing the only one", async () => {
      mockRequest.mockResolvedValue(page([1], { hasNextPage: false, total: 1 }));
      const index = mountIndex();
      await flushPromises();
      mockRequest.mockResolvedValueOnce(page([], { hasNextPage: false, total: 0 }));
      await index.removeNode("1");
      expect(lastVariables()).toMatchObject({ first: 1 });
    });

    it("never asks for more than the API's largest page", async () => {
      mockRequest.mockResolvedValue(page(range(1, 150)));
      const index = mountIndex();
      await flushPromises();
      await index.removeNode("1");
      expect(lastVariables()).toMatchObject({ first: 100 });
    });

    it("does nothing before the list has loaded", async () => {
      mockRequest.mockReturnValue(new Promise(() => {}));
      const index = mountIndex();
      await index.removeNode("1");
      expect(mockRequest).toHaveBeenCalledTimes(1);
    });
  });
});
