import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { effectScope, nextTick } from "vue";
import { SEARCH_DEBOUNCE_MS, useDebouncedSearch } from "./useDebouncedSearch";

type Search = (query: string) => Promise<string[]>;

function setup(search: Search) {
  const scope = effectScope();
  const state = scope.run(() => useDebouncedSearch(search));
  if (!state) {
    throw new Error("No state");
  }
  return { ...state, scope };
}

describe("useDebouncedSearch", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("searches once typing pauses, with the trimmed query", async () => {
    const search = vi.fn<Search>(async (q) => [`${q} result`]);
    const { query, results, searching } = setup(search);

    query.value = "u";
    await nextTick();
    query.value = " unity ";
    await nextTick();
    expect(searching.value).toBeTruthy();

    await vi.advanceTimersByTimeAsync(SEARCH_DEBOUNCE_MS - 1);
    expect(search).not.toHaveBeenCalled();

    await vi.advanceTimersByTimeAsync(1);
    expect(search).toHaveBeenCalledTimes(1);
    expect(search).toHaveBeenCalledWith("unity");
    expect(results.value).toEqual(["unity result"]);
    expect(searching.value).toBeFalsy();
  });

  it("clears results without searching when the query is blank", async () => {
    const search = vi.fn<Search>(async () => ["Unity"]);
    const { query, results, searching } = setup(search);

    query.value = "unity";
    await nextTick();
    await vi.advanceTimersByTimeAsync(SEARCH_DEBOUNCE_MS);
    expect(results.value).toEqual(["Unity"]);

    query.value = "   ";
    await nextTick();
    expect(results.value).toEqual([]);
    expect(searching.value).toBeFalsy();
    await vi.advanceTimersByTimeAsync(SEARCH_DEBOUNCE_MS);
    expect(search).toHaveBeenCalledTimes(1);
  });

  it("ignores an answer to a search the user has typed past", async () => {
    let resolveFirst: (value: string[]) => void = () => {};
    const search = vi.fn<Search>((q) =>
      q === "un" ? new Promise((resolve) => (resolveFirst = resolve)) : Promise.resolve(["Unreal Engine"])
    );
    const { query, results } = setup(search);

    query.value = "un";
    await nextTick();
    await vi.advanceTimersByTimeAsync(SEARCH_DEBOUNCE_MS);
    query.value = "unreal";
    await nextTick();
    await vi.advanceTimersByTimeAsync(SEARCH_DEBOUNCE_MS);
    expect(results.value).toEqual(["Unreal Engine"]);

    resolveFirst(["Unity"]);
    await vi.advanceTimersByTimeAsync(0);
    expect(results.value).toEqual(["Unreal Engine"]);
  });

  it("shows no results when the search fails", async () => {
    const { query, results, searching } = setup(() => Promise.reject(new Error("boom")));

    query.value = "unity";
    await nextTick();
    await vi.advanceTimersByTimeAsync(SEARCH_DEBOUNCE_MS);
    expect(results.value).toEqual([]);
    expect(searching.value).toBeFalsy();
  });

  it("doesn't search after its scope is disposed", async () => {
    const search = vi.fn<Search>(async () => []);
    const { query, scope } = setup(search);

    query.value = "unity";
    await nextTick();
    scope.stop();
    await vi.advanceTimersByTimeAsync(SEARCH_DEBOUNCE_MS);
    expect(search).not.toHaveBeenCalled();
  });
});
