import { describe, it, expect, vi, afterEach } from "vitest";
import gql from "graphql-tag";
import {
  MAX_AGE_MS,
  MAX_ENTRIES,
  clearQueryCache,
  queryCacheGeneration,
  queryCacheKey,
  readQueryCache,
  writeQueryCache
} from "./query-cache";

const QUERY = gql`
  query GetThing($id: ID!, $first: Int) {
    thing(id: $id, first: $first) {
      id
    }
  }
`;

function write(key: string, data: unknown) {
  writeQueryCache(key, data, queryCacheGeneration());
}

describe("query cache", () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it("keys by operation name and variables, whatever their order", () => {
    expect(queryCacheKey(QUERY, { id: "1", first: 2 })).toBe(queryCacheKey(QUERY, { first: 2, id: "1" }));
    expect(queryCacheKey(QUERY, { id: "1" })).not.toBe(queryCacheKey(QUERY, { id: "2" }));
    expect(queryCacheKey(QUERY, undefined)).toBe("GetThing:{}");
  });

  it("doesn't key mutations or anonymous queries", () => {
    expect(
      queryCacheKey(
        gql`
          mutation DoThing {
            doThing
          }
        `,
        {}
      )
    ).toBeNull();
    expect(
      queryCacheKey(
        gql`
          {
            thing
          }
        `,
        {}
      )
    ).toBeNull();
  });

  it("forgets entries older than the max age", () => {
    vi.useFakeTimers();
    write("a", { n: 1 });
    vi.advanceTimersByTime(MAX_AGE_MS + 1);
    expect(readQueryCache("a")).toBeNull();
  });

  it("evicts the least recently used entry past the limit", () => {
    for (let i = 0; i < MAX_ENTRIES; i++) {
      write(`k${i}`, i);
    }
    // Reading k0 makes k1 the least recently used.
    expect(readQueryCache("k0")).toBe(0);
    write("extra", "x");
    expect(readQueryCache("k0")).toBe(0);
    expect(readQueryCache("k1")).toBeNull();
    expect(readQueryCache("extra")).toBe("x");
  });

  it("drops writes for requests that started before a clear", () => {
    const generation = queryCacheGeneration();
    clearQueryCache();
    writeQueryCache("a", { n: 1 }, generation);
    expect(readQueryCache("a")).toBeNull();
  });
});
