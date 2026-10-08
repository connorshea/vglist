import { describe, it, expect } from "vitest";
import { SEARCH_TABS, pageSizeFor, parseSearchState, recordPath, searchSection, searchableTypeKey } from "./search";

describe("parseSearchState", () => {
  it("reads the query and tab from the URL", () => {
    expect(parseSearchState({ query: "ratatouille", type: "games" })).toEqual({ query: "ratatouille", tab: "games" });
  });

  it("defaults to the All tab with an empty query", () => {
    expect(parseSearchState({})).toEqual({ query: "", tab: "all" });
  });

  it("trims the query", () => {
    expect(parseSearchState({ query: "  halo  " }).query).toBe("halo");
  });

  it("falls back to All for unknown or mis-cased types", () => {
    expect(parseSearchState({ query: "x", type: "consoles" }).tab).toBe("all");
    expect(parseSearchState({ query: "x", type: "GAMES" }).tab).toBe("all");
  });

  it("accepts the Stores tab", () => {
    expect(parseSearchState({ query: "x", type: "stores" }).tab).toBe("stores");
  });

  it("uses the first value when a param is repeated", () => {
    expect(parseSearchState({ query: ["a", "b"], type: ["users", "games"] })).toEqual({ query: "a", tab: "users" });
  });
});

describe("pageSizeFor", () => {
  it("pages games in tens to stay under the API's complexity limit, and everything else in 25s", () => {
    expect(pageSizeFor("games")).toBe(10);
    expect(pageSizeFor("users")).toBe(25);
  });
});

describe("SEARCH_TABS", () => {
  it("starts with All, then one tab per searchable type", () => {
    expect(SEARCH_TABS.map((t) => t.key)).toEqual([
      "all",
      "games",
      "companies",
      "platforms",
      "series",
      "engines",
      "genres",
      "stores",
      "users"
    ]);
  });
});

describe("recordPath", () => {
  it("links each type to its show page", () => {
    expect(recordPath("games", "7")).toBe("/games/7");
    expect(recordPath("stores", "3")).toBe("/stores/3");
    expect(recordPath("users", "among-us-fan")).toBe("/users/among-us-fan");
  });
});

describe("searchableTypeKey", () => {
  it("maps globalSearch's searchable types to tab keys", () => {
    expect(searchableTypeKey("GAME")).toBe("games");
    expect(searchableTypeKey("SERIES")).toBe("series");
    expect(searchableTypeKey("USER")).toBe("users");
  });
});

describe("searchSection", () => {
  const game = {
    id: "1",
    name: "Halo",
    releaseDate: null,
    coverUrl: null,
    isInLibrary: null,
    platforms: { totalCount: 0, nodes: [] },
    developers: { nodes: [] },
    publishers: { nodes: [] },
    series: null
  };

  it("pulls one type's connection out of a response", () => {
    const data = {
      games: { totalCount: 4, nodes: [game] },
      stores: { totalCount: 1, nodes: [{ id: "2", name: "GOG" }] }
    };

    expect(searchSection(data, "games")).toEqual({ type: "games", totalCount: 4, nodes: [game] });
    expect(searchSection(data, "stores")).toEqual({ type: "stores", totalCount: 1, nodes: [{ id: "2", name: "GOG" }] });
  });

  it("is null when the response doesn't include that type", () => {
    expect(searchSection({ games: { totalCount: 4, nodes: [game] } }, "users")).toBeNull();
  });
});
