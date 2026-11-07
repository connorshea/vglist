import { describe, it, expect } from "vitest";
import { mount } from "@vue/test-utils";
import DataCoverage from "./DataCoverage.vue";
import type { GetLiveStatisticsQuery } from "@/types/graphql";

type LiveStatistics = NonNullable<GetLiveStatisticsQuery["liveStatistics"]>;

const STATS: LiveStatistics = {
  users: 40,
  games: 1000,
  platforms: 1,
  series: 1,
  engines: 1,
  companies: 1,
  genres: 1,
  stores: 1,
  events: 1,
  gamePurchases: 1,
  relationships: 1,
  bannedUsers: 0,
  gamesWithCovers: 6,
  gamesWithReleaseDates: 720,
  mobygamesIds: 500,
  pcgamingwikiIds: 300,
  wikidataIds: 990,
  giantbombIds: 400,
  steamAppIds: 450,
  epicGamesStoreIds: 0,
  gogIds: 80,
  igdbIds: null
};

function rows(wrapper: ReturnType<typeof mount>) {
  return wrapper.findAll(".coverage-row").map((row) => ({
    label: row.find(".coverage-label").text(),
    count: row.find(".coverage-count strong").text(),
    percent: row.find(".coverage-percent").text(),
    width: (row.find(".coverage-fill").element as HTMLElement).style.width,
    low: row.find(".coverage-fill").classes().includes("is-low")
  }));
}

describe("DataCoverage", () => {
  it("shows each count as a share of all games", () => {
    const result = rows(mount(DataCoverage, { props: { stats: STATS } }));

    expect(result[0]).toEqual({ label: "Release dates", count: "720", percent: "72.0%", width: "72%", low: false });
    // Tiny shares keep a visible sliver and are flagged as low.
    expect(result[1]).toEqual({ label: "Covers", count: "6", percent: "0.6%", width: "0.8%", low: true });
  });

  it("sorts external IDs by coverage and treats a missing count as zero", () => {
    const result = rows(mount(DataCoverage, { props: { stats: STATS } }));
    const externalIds = result.slice(2);

    expect(externalIds.map((r) => r.label)).toEqual([
      "Wikidata",
      "MobyGames",
      "Steam",
      "GiantBomb",
      "PCGamingWiki",
      "GOG",
      "IGDB",
      "Epic Games Store"
    ]);
    expect(externalIds.at(-1)).toMatchObject({ count: "0", percent: "0.0%", width: "0%", low: true });
  });
});
