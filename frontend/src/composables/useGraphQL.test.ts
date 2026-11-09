import { describe, it, expect, vi, beforeEach } from "vitest";
import { defineComponent, nextTick, ref, type Ref } from "vue";
import { mount } from "@vue/test-utils";
import { GET_PLATFORM_FOR_EDIT } from "@/graphql/queries/resources";
import { clearQueryCache } from "@/graphql/query-cache";
import { useQuery } from "./useGraphQL";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockRequest } = vi.hoisted(() => ({
  mockRequest: vi.fn<(...args: unknown[]) => Promise<unknown>>()
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

/**
 * A deferred promise, so a test can control exactly when (and in what order)
 * each in-flight request resolves.
 */
function deferred<T>() {
  let resolve!: (value: T) => void;
  let reject!: (reason: unknown) => void;
  const promise = new Promise<T>((res, rej) => {
    resolve = res;
    reject = rej;
  });
  return { promise, resolve, reject };
}

type ThingData = { platform: { id: string } };

/**
 * Mounts a component around `useQuery` so `onMounted` fires and the reactive
 * variables watcher is active, and hands back the id ref to drive it. Pass an
 * `enabled` ref to also drive the enabled flag; leaving it off exercises the
 * always-enabled path where the option is omitted entirely.
 */
function mountQuery({
  enabled,
  cache,
  id = ref("1")
}: { enabled?: Ref<boolean>; cache?: boolean; id?: Ref<string> } = {}) {
  // Held in a plain binding rather than a ref — a ref would deeply unwrap the
  // refs the composable returns, leaving `.value` undefined.
  let composable: ReturnType<typeof useQuery<ThingData>> | null = null;

  const wrapper = mount(
    defineComponent({
      setup() {
        composable = useQuery<ThingData>(GET_PLATFORM_FOR_EDIT, {
          variables: () => ({ id: id.value }),
          enabled: enabled ? () => enabled.value : undefined,
          cache
        });
        return () => null;
      }
    })
  );

  return { id, wrapper, query: () => composable! };
}

// ── Tests ─────────────────────────────────────────────────────────

describe("useQuery", () => {
  beforeEach(() => {
    mockRequest.mockReset();
  });

  it("discards a response that has been superseded by a newer request", async () => {
    const first = deferred<ThingData>();
    const second = deferred<ThingData>();
    mockRequest.mockReturnValueOnce(first.promise).mockReturnValueOnce(second.promise);

    const { id, query } = mountQuery();
    await nextTick();

    // Change the variable so a second request goes out while the first is
    // still in flight.
    id.value = "2";
    await nextTick();
    expect(mockRequest).toHaveBeenCalledTimes(2);

    // The newer request answers first, then the stale one arrives late.
    second.resolve({ platform: { id: "2" } });
    await nextTick();
    first.resolve({ platform: { id: "1" } });
    await nextTick();

    expect(query().data.value).toEqual({ platform: { id: "2" } });
  });

  it("keeps loading true until the newest request settles", async () => {
    const first = deferred<ThingData>();
    const second = deferred<ThingData>();
    mockRequest.mockReturnValueOnce(first.promise).mockReturnValueOnce(second.promise);

    const { id, query } = mountQuery();
    await nextTick();

    id.value = "2";
    await nextTick();

    // The superseded request settling must not clear the loading flag, or the
    // UI would show a form/page as ready while the real request is pending.
    first.resolve({ platform: { id: "1" } });
    await nextTick();
    expect(query().loading.value).toBeTruthy();

    second.resolve({ platform: { id: "2" } });
    await nextTick();
    expect(query().loading.value).toBeFalsy();
  });

  it("ignores an error from a superseded request", async () => {
    const first = deferred<ThingData>();
    const second = deferred<ThingData>();
    mockRequest.mockReturnValueOnce(first.promise).mockReturnValueOnce(second.promise);

    const { id, query } = mountQuery();
    await nextTick();

    id.value = "2";
    await nextTick();

    second.resolve({ platform: { id: "2" } });
    await nextTick();
    first.reject(new Error("stale request failed"));
    await nextTick();

    expect(query().error.value).toBeNull();
    expect(query().data.value).toEqual({ platform: { id: "2" } });
  });

  it("discards a response that arrives after the query is disabled", async () => {
    const first = deferred<ThingData>();
    mockRequest.mockReturnValueOnce(first.promise);

    const enabled = ref(true);
    const { query } = mountQuery({ enabled });
    await nextTick();

    // Standing in for navigating from an edit route to a new one in a reused
    // component: the query is disabled while its request is still in flight.
    enabled.value = false;
    await nextTick();
    expect(mockRequest).toHaveBeenCalledTimes(1);

    first.resolve({ platform: { id: "1" } });
    await nextTick();

    // Applying it would repopulate form fields the page just cleared.
    expect(query().data.value).toBeNull();
    expect(query().loading.value).toBeFalsy();
  });

  it("discards an error that arrives after the query is disabled", async () => {
    const first = deferred<ThingData>();
    mockRequest.mockReturnValueOnce(first.promise);

    const enabled = ref(true);
    const { query } = mountQuery({ enabled });
    await nextTick();

    enabled.value = false;
    await nextTick();

    first.reject(new Error("stale request failed"));
    await nextTick();

    expect(query().error.value).toBeNull();
    expect(query().loading.value).toBeFalsy();
  });

  it("runs again when the query is re-enabled", async () => {
    mockRequest.mockResolvedValue({ platform: { id: "1" } });

    const enabled = ref(false);
    const { query } = mountQuery({ enabled });
    await nextTick();
    expect(mockRequest).not.toHaveBeenCalled();

    enabled.value = true;
    await nextTick();
    await nextTick();

    expect(mockRequest).toHaveBeenCalledTimes(1);
    expect(query().data.value).toEqual({ platform: { id: "1" } });
  });

  it("still surfaces data and errors from the newest request", async () => {
    mockRequest.mockRejectedValueOnce(new Error("boom"));

    const { query } = mountQuery();
    await nextTick();
    await nextTick();

    expect(query().error.value?.message).toBe("boom");
    expect(query().loading.value).toBeFalsy();
  });
});

describe("useQuery stale-while-revalidate cache", () => {
  beforeEach(() => {
    mockRequest.mockReset();
  });

  async function settle() {
    await nextTick();
    await nextTick();
  }

  it("shows a cached result in the first render, then replaces it with the fresh one", async () => {
    mockRequest.mockResolvedValueOnce({ platform: { id: "1", name: "Old" } });
    const first = mountQuery();
    await settle();
    first.wrapper.unmount();

    const fresh = deferred<unknown>();
    mockRequest.mockReturnValueOnce(fresh.promise);
    const second = mountQuery();

    // No await: the cached result is there before mount finishes.
    expect(second.query().data.value).toEqual({ platform: { id: "1", name: "Old" } });
    expect(second.query().loading.value).toBeFalsy();
    expect(second.query().revalidating.value).toBeTruthy();
    expect(mockRequest).toHaveBeenCalledTimes(2);

    fresh.resolve({ platform: { id: "1", name: "New" } });
    await settle();
    expect(second.query().data.value).toEqual({ platform: { id: "1", name: "New" } });
    expect(second.query().revalidating.value).toBeFalsy();
  });

  it("shows the cached result for new variables while they load", async () => {
    mockRequest.mockResolvedValueOnce({ platform: { id: "2" } });
    mountQuery({ id: ref("2") }).wrapper.unmount();
    await settle();

    mockRequest.mockResolvedValueOnce({ platform: { id: "1" } });
    const { id, query } = mountQuery();
    await settle();

    const pending = deferred<unknown>();
    mockRequest.mockReturnValueOnce(pending.promise);
    id.value = "2";
    await nextTick();

    expect(query().data.value).toEqual({ platform: { id: "2" } });
    expect(query().loading.value).toBeFalsy();
  });

  it("hands each mount its own copy, so editing data in place doesn't change the cache", async () => {
    mockRequest.mockResolvedValueOnce({ platform: { id: "1" } });
    const first = mountQuery();
    await settle();
    first.query().data.value!.platform.id = "edited";
    first.wrapper.unmount();

    mockRequest.mockReturnValueOnce(new Promise(() => {}));
    const second = mountQuery();
    expect(second.query().data.value).toEqual({ platform: { id: "1" } });
  });

  it("doesn't read or write the cache when turned off", async () => {
    mockRequest.mockResolvedValueOnce({ platform: { id: "1" } });
    mountQuery({ cache: false }).wrapper.unmount();
    await settle();

    mockRequest.mockReturnValueOnce(new Promise(() => {}));
    const second = mountQuery();
    expect(second.query().data.value).toBeNull();
    expect(second.query().loading.value).toBeTruthy();
  });

  it("starts from nothing after the cache is cleared", async () => {
    mockRequest.mockResolvedValueOnce({ platform: { id: "1" } });
    mountQuery().wrapper.unmount();
    await settle();
    clearQueryCache();

    mockRequest.mockReturnValueOnce(new Promise(() => {}));
    expect(mountQuery().query().data.value).toBeNull();
  });

  it("doesn't cache a response to a request that started before the cache was cleared", async () => {
    const inFlight = deferred<unknown>();
    mockRequest.mockReturnValueOnce(inFlight.promise);
    const first = mountQuery();
    await nextTick();

    // Standing in for a mutation finishing while the query is in flight.
    clearQueryCache();
    inFlight.resolve({ platform: { id: "before the mutation" } });
    await settle();
    first.wrapper.unmount();

    mockRequest.mockReturnValueOnce(new Promise(() => {}));
    expect(mountQuery().query().data.value).toBeNull();
  });

  it("waits for a refresh of a cached result before loading another page", async () => {
    mockRequest.mockResolvedValueOnce({ platform: { id: "1", cursor: "old" } });
    mountQuery().wrapper.unmount();
    await settle();

    const fresh = deferred<unknown>();
    const nextPage = deferred<unknown>();
    mockRequest.mockReturnValueOnce(fresh.promise).mockReturnValueOnce(nextPage.promise);
    const { query } = mountQuery();
    await settle();
    expect(query().revalidating.value).toBeTruthy();

    const merge = vi.fn<(prev: ThingData, next: ThingData) => ThingData>((prev, next) => ({ ...prev, ...next }));
    const loaded = query().fetchMore(() => {
      const data = query().data.value as { platform: { cursor: string } } | null;
      return { id: "1", after: data?.platform.cursor };
    }, merge);
    await settle();
    // Nothing goes out until the fresh first page is in.
    expect(mockRequest).toHaveBeenCalledTimes(2);

    fresh.resolve({ platform: { id: "1", cursor: "new" } });
    await settle();
    expect(query().data.value).toEqual({ platform: { id: "1", cursor: "new" } });
    expect(mockRequest).toHaveBeenCalledTimes(3);
    // The cursor comes from the fresh first page, not the cached one.
    expect(mockRequest).toHaveBeenLastCalledWith(GET_PLATFORM_FOR_EDIT, { id: "1", after: "new" });

    nextPage.resolve({ platform: { id: "1", cursor: "next" } });
    await loaded;
    expect(merge).toHaveBeenCalledWith(
      { platform: { id: "1", cursor: "new" } },
      { platform: { id: "1", cursor: "next" } }
    );
    expect(query().data.value).toEqual({ platform: { id: "1", cursor: "next" } });
  });

  it("skips a page whose variables come back null after the refresh", async () => {
    mockRequest.mockResolvedValueOnce({ platform: { id: "1" } });
    mountQuery().wrapper.unmount();
    await settle();

    const fresh = deferred<unknown>();
    mockRequest.mockReturnValueOnce(fresh.promise);
    const { query } = mountQuery();
    await settle();

    const loaded = query().fetchMore(
      () => null,
      (prev) => prev
    );
    fresh.resolve({ platform: { id: "1" } });
    await loaded;
    expect(mockRequest).toHaveBeenCalledTimes(2);
  });

  it("drops a waiting page when the variables change during the refresh", async () => {
    mockRequest.mockResolvedValueOnce({ platform: { id: "1" } });
    mountQuery().wrapper.unmount();
    await settle();

    const fresh = deferred<unknown>();
    const otherList = deferred<unknown>();
    mockRequest.mockReturnValueOnce(fresh.promise).mockReturnValueOnce(otherList.promise);
    const { id, query } = mountQuery();
    await settle();

    const loaded = query().fetchMore({ id: "1", after: "x" }, (prev) => prev);
    // Uncached variables, so they load from scratch.
    id.value = "2";
    await settle();
    fresh.resolve({ platform: { id: "1" } });
    await loaded;
    expect(mockRequest).toHaveBeenCalledTimes(3);
    expect(mockRequest).not.toHaveBeenCalledWith(GET_PLATFORM_FOR_EDIT, { id: "1", after: "x" });
  });

  it("refetch shows loading rather than reusing the cache", async () => {
    mockRequest.mockResolvedValueOnce({ platform: { id: "1" } });
    const { query } = mountQuery();
    await settle();

    mockRequest.mockReturnValueOnce(new Promise(() => {}));
    void query().refetch();
    expect(query().loading.value).toBeTruthy();
    expect(query().revalidating.value).toBeFalsy();
  });
});
