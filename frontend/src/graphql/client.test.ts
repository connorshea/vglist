import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import gql from "graphql-tag";
import { createPinia, setActivePinia } from "pinia";
import { gqlClient } from "./client";
import { queryCacheGeneration, readQueryCache, writeQueryCache } from "./query-cache";

// client.ts reads the API URL when it's imported.
vi.hoisted(() => {
  vi.stubEnv("VITE_API_URL", "http://api.test");
});

function respondWith(body: unknown) {
  vi.stubGlobal(
    "fetch",
    vi.fn(
      async () =>
        new Response(JSON.stringify(body), {
          status: 200,
          headers: { "content-type": "application/json" }
        })
    )
  );
}

describe("gqlClient", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    writeQueryCache("GetThing:{}", { thing: 1 }, queryCacheGeneration());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("clears the query cache after a mutation", async () => {
    respondWith({ data: { favoriteGame: { game: { id: "1" } } } });
    await gqlClient.request(
      gql`
        mutation FavoriteGame($gameId: ID!) {
          favoriteGame(gameId: $gameId) {
            game {
              id
            }
          }
        }
      `,
      { gameId: "1" }
    );
    expect(readQueryCache("GetThing:{}")).toBeNull();
  });

  it("clears it even when the mutation fails", async () => {
    respondWith({ data: null, errors: [{ message: "nope" }] });
    await expect(
      gqlClient.request(gql`
        mutation DeleteGame {
          deleteGame {
            deleted
          }
        }
      `)
    ).rejects.toThrow("nope");
    expect(readQueryCache("GetThing:{}")).toBeNull();
  });

  it("clears it when a mutation is sent, so a dropped connection can't leave it stale", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => {
        throw new TypeError("Failed to fetch");
      })
    );
    await expect(
      gqlClient.request(gql`
        mutation DeleteGame {
          deleteGame {
            deleted
          }
        }
      `)
    ).rejects.toThrow("Failed to fetch");
    expect(readQueryCache("GetThing:{}")).toBeNull();
  });

  it("drops a result a query cached while a mutation was in flight", async () => {
    let cachedMidFlight = false;
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => {
        // A query that started after the mutation was sent finishes first.
        writeQueryCache("GetThing:{}", { thing: 2 }, queryCacheGeneration());
        cachedMidFlight = readQueryCache("GetThing:{}") !== null;
        return new Response(JSON.stringify({ data: { deleteGame: { deleted: true } } }), {
          status: 200,
          headers: { "content-type": "application/json" }
        });
      })
    );
    await gqlClient.request(gql`
      mutation DeleteGame {
        deleteGame {
          deleted
        }
      }
    `);
    expect(cachedMidFlight).toBeTruthy();
    expect(readQueryCache("GetThing:{}")).toBeNull();
  });

  it("leaves it alone after a query", async () => {
    respondWith({ data: { thing: 2 } });
    await gqlClient.request(gql`
      query GetOther {
        thing
      }
    `);
    expect(readQueryCache("GetThing:{}")).toEqual({ thing: 1 });
  });
});
