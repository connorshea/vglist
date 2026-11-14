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

describe("query cache across reloads", () => {
  // A fresh copy of the module stands in for a reload: memory starts empty,
  // sessionStorage is what the last page load left.
  async function reload() {
    vi.resetModules();
    return import("./query-cache");
  }

  afterEach(() => {
    vi.useRealTimers();
    localStorage.clear();
    sessionStorage.clear();
  });

  it("restores entries from sessionStorage", async () => {
    write("a", { n: 1 });
    const fresh = await reload();
    expect(fresh.readQueryCache("a")).toEqual({ n: 1 });
  });

  it("doesn't restore entries cleared before the reload", async () => {
    write("a", { n: 1 });
    clearQueryCache();
    const fresh = await reload();
    expect(fresh.readQueryCache("a")).toBeNull();
  });

  it("doesn't restore entries fetched for someone else", async () => {
    localStorage.setItem("auth_user", JSON.stringify({ id: "1" }));
    write("a", { n: 1 });
    // Signed out in another tab, which this tab's cache never heard about.
    localStorage.removeItem("auth_user");
    const fresh = await reload();
    expect(fresh.readQueryCache("a")).toBeNull();
    expect(sessionStorage.length).toBe(0);
  });

  it("doesn't restore entries from another build", async () => {
    write("a", { n: 1 });
    vi.stubEnv("VITE_SENTRY_RELEASE", "newer-commit");
    try {
      const fresh = await reload();
      expect(fresh.readQueryCache("a")).toBeNull();
    } finally {
      vi.unstubAllEnvs();
    }
  });

  it("doesn't restore expired entries", async () => {
    vi.useFakeTimers();
    write("a", { n: 1 });
    vi.advanceTimersByTime(MAX_AGE_MS + 1);
    const fresh = await reload();
    expect(fresh.readQueryCache("a")).toBeNull();
  });

  it("makes room when storage is full, keeping everything in memory", async () => {
    write("old", { n: 1 });
    // Full for the first try, then there's room once the old entry is gone.
    const setItem = vi.spyOn(Storage.prototype, "setItem").mockImplementationOnce(() => {
      throw new DOMException("full", "QuotaExceededError");
    });
    write("new", { n: 2 });
    setItem.mockRestore();

    expect(readQueryCache("old")).toEqual({ n: 1 });
    const fresh = await reload();
    expect(fresh.readQueryCache("old")).toBeNull();
    expect(fresh.readQueryCache("new")).toEqual({ n: 2 });
  });

  it("still works when an entry can't be stored at all", () => {
    const setItem = vi.spyOn(Storage.prototype, "setItem").mockImplementation(() => {
      throw new DOMException("full", "QuotaExceededError");
    });
    write("a", { n: 1 });
    setItem.mockRestore();
    expect(readQueryCache("a")).toEqual({ n: 1 });
  });

  it("works in memory when storage is blocked", async () => {
    const blocked = () => {
      throw new DOMException("The operation is insecure.", "SecurityError");
    };
    const session = vi.spyOn(window, "sessionStorage", "get").mockImplementation(blocked);
    const local = vi.spyOn(window, "localStorage", "get").mockImplementation(blocked);
    try {
      const fresh = await reload();
      fresh.writeQueryCache("a", { n: 1 }, fresh.queryCacheGeneration());
      expect(fresh.readQueryCache("a")).toEqual({ n: 1 });
      fresh.clearQueryCache();
      expect(fresh.readQueryCache("a")).toBeNull();
    } finally {
      session.mockRestore();
      local.mockRestore();
    }
  });
});
