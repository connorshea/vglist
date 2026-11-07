import { describe, it, expect, vi, beforeEach } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { GET_UNMATCHED_GAMES } from "@/graphql/queries/admin";
import { useConnectionList } from "./useConnectionList";

const { mockRequest } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>()
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

// Any connection query will do: the client is mocked.
const QUERY = GET_UNMATCHED_GAMES;

interface Item {
  id: number;
}
interface ItemsQuery {
  items: { nodes: Item[]; pageInfo: { hasNextPage: boolean; endCursor: string | null } };
}

// A fake offset-paginated API over `rows`, like graphql-ruby's
// ActiveRecord connections.
let rows: Item[] = [];
function serve(_query: unknown, variables?: Record<string, unknown>): Promise<ItemsQuery> {
  const first = Number(variables?.first);
  const offset = variables?.after ? Number(variables.after) : 0;
  const nodes = rows.slice(offset, offset + first);
  const end = offset + nodes.length;
  return Promise.resolve({
    items: { nodes, pageInfo: { hasNextPage: end < rows.length, endCursor: nodes.length ? String(end) : null } }
  });
}

function mountList(pageSize = 2) {
  let list!: ReturnType<typeof useConnectionList<ItemsQuery, Item>>;
  mount(
    defineComponent({
      setup() {
        list = useConnectionList<ItemsQuery, Item>(QUERY, { select: (data) => data.items, pageSize });
        return () => h("div");
      }
    })
  );
  return list;
}

function ids(list: ReturnType<typeof mountList>) {
  return list.nodes.value.map((n) => n.id);
}

beforeEach(() => {
  rows = Array.from({ length: 5 }, (_, i) => ({ id: i + 1 }));
  mockRequest.mockReset();
  mockRequest.mockImplementation(serve);
});

describe("useConnectionList", () => {
  it("loads the first page on mount", async () => {
    const list = mountList();
    expect(list.loaded.value).toBeFalsy();
    await flushPromises();

    expect(ids(list)).toEqual([1, 2]);
    expect(list.loaded.value).toBeTruthy();
    expect(list.hasNextPage.value).toBeTruthy();
    expect(mockRequest).toHaveBeenCalledWith(QUERY, { first: 2, after: null });
  });

  it("appends pages with loadMore until there are none left", async () => {
    const list = mountList();
    await flushPromises();

    await list.loadMore();
    expect(ids(list)).toEqual([1, 2, 3, 4]);
    await list.loadMore();
    expect(ids(list)).toEqual([1, 2, 3, 4, 5]);
    expect(list.hasNextPage.value).toBeFalsy();

    mockRequest.mockClear();
    await list.loadMore();
    expect(mockRequest).not.toHaveBeenCalled();
  });

  it("keeps the loaded rows and the next cursor in step after a reload", async () => {
    const list = mountList();
    await flushPromises();
    await list.loadMore();

    // Remove row 2, as a mutation would, then reload.
    rows = rows.filter((r) => r.id !== 2);
    await list.reload();
    expect(ids(list)).toEqual([1, 3, 4, 5]);
    expect(list.hasNextPage.value).toBeFalsy();
  });

  it("reloads in chunks of at most 100 rows", async () => {
    rows = Array.from({ length: 250 }, (_, i) => ({ id: i + 1 }));
    const list = mountList(60);
    await flushPromises();
    await list.loadMore();
    await list.loadMore();
    expect(list.nodes.value).toHaveLength(180);

    mockRequest.mockClear();
    await list.reload();
    expect(list.nodes.value).toHaveLength(180);
    expect(mockRequest.mock.calls.map(([, v]) => v?.first)).toEqual([100, 80]);
  });

  it("reports a failed page and lets the user retry", async () => {
    const list = mountList();
    await flushPromises();

    mockRequest.mockRejectedValueOnce(new Error("Network down"));
    await list.loadMore();
    expect(list.loadMoreError.value).toBe("Network down");
    expect(ids(list)).toEqual([1, 2]);

    await list.loadMore();
    expect(list.loadMoreError.value).toBeNull();
    expect(ids(list)).toEqual([1, 2, 3, 4]);
  });

  it("drops a page that was loading when a reload started", async () => {
    const list = mountList();
    await flushPromises();

    let resolveStale!: (value: ItemsQuery) => void;
    mockRequest.mockImplementationOnce(() => new Promise((resolve) => (resolveStale = resolve)));
    const pending = list.loadMore();
    await list.reload();
    resolveStale({ items: { nodes: [{ id: 99 }], pageInfo: { hasNextPage: false, endCursor: "3" } } });
    await pending;

    expect(ids(list)).toEqual([1, 2]);
    expect(list.loadingMore.value).toBeFalsy();
  });
});
