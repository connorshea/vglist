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
