import { describe, it, expect, vi, beforeEach } from "vitest";
import { defineComponent, nextTick, ref } from "vue";
import { mount } from "@vue/test-utils";
import { GET_PLATFORM_FOR_EDIT } from "@/graphql/queries/resources";
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
 * variables watcher is active, and hands back the id ref to drive it.
 */
function mountQuery() {
  const id = ref("1");
  // Held in a plain binding rather than a ref — a ref would deeply unwrap the
  // refs the composable returns, leaving `.value` undefined.
  let composable: ReturnType<typeof useQuery<ThingData>> | null = null;

  const wrapper = mount(
    defineComponent({
      setup() {
        composable = useQuery<ThingData>(GET_PLATFORM_FOR_EDIT, {
          variables: () => ({ id: id.value })
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

  it("still surfaces data and errors from the newest request", async () => {
    mockRequest.mockRejectedValueOnce(new Error("boom"));

    const { query } = mountQuery();
    await nextTick();
    await nextTick();

    expect(query().error.value?.message).toBe("boom");
    expect(query().loading.value).toBeFalsy();
  });
});
