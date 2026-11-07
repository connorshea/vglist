import { describe, it, expect } from "vitest";
import { mount } from "@vue/test-utils";
import StatisticsOverview from "./StatisticsOverview.vue";
import type { GetLiveStatisticsQuery, GetSiteStatisticsQuery } from "@/types/graphql";

type LiveStatistics = NonNullable<GetLiveStatisticsQuery["liveStatistics"]>;
type Snapshot = NonNullable<GetSiteStatisticsQuery["siteStatistics"]>["nodes"][number];

// Early in the day, so the snapshot exactly N days back is the closest one.
const NOW = new Date("2026-11-07T06:00:00Z");

const LIVE: LiveStatistics = {
  users: 40,
  games: 7685,
  platforms: 69,
  series: 2928,
  engines: 598,
  companies: 9470,
  genres: 162,
  stores: 10,
  events: 155,
  gamePurchases: 76,
  relationships: 39,
  bannedUsers: 2,
  gamesWithCovers: 44,
  gamesWithReleaseDates: 5525,
  mobygamesIds: 4560,
  pcgamingwikiIds: 2749,
  wikidataIds: 7635,
  giantbombIds: 2843,
  steamAppIds: 4046,
  epicGamesStoreIds: 453,
  gogIds: 602,
  igdbIds: 6049
};

// A snapshot `daysAgo` days before Nov 7, with every count `behind` less than
// the live value.
function snapshot(daysAgo: number, behind: number): Snapshot {
  const counts = Object.fromEntries(Object.entries(LIVE).map(([key, value]) => [key, (value ?? 0) - behind]));
  return {
    ...counts,
    id: String(daysAgo),
    timestamp: new Date(Date.UTC(2026, 10, 7 - daysAgo)).toISOString(),
    unmatchedGames: 0,
    companyVersions: null,
    gameVersions: null,
    genreVersions: null,
    engineVersions: null,
    platformVersions: null,
    seriesVersions: null
  } as Snapshot;
}

function mountOverview(history: Snapshot[]) {
  return mount(StatisticsOverview, { props: { stats: LIVE, history, now: NOW } });
}

function tile(wrapper: ReturnType<typeof mountOverview>, label: string) {
  const found = wrapper.findAll(".kpi-tile").find((t) => t.find(".kpi-label").text() === label);
  if (!found) throw new Error(`No tile labelled ${label}`);
  return found;
}

function miniTile(wrapper: ReturnType<typeof mountOverview>, label: string) {
  const found = wrapper.findAll(".mini-tile").find((t) => t.find("dt").text() === label);
  if (!found) throw new Error(`No compact tile labelled ${label}`);
  return found;
}

// Daily snapshots for the last 90 days; the count was `days` lower `days` ago.
const NINETY_DAYS = Array.from({ length: 91 }, (_, daysAgo) => snapshot(daysAgo, daysAgo));

describe("StatisticsOverview", () => {
  it("shows live values with the change over the 30 days by default", () => {
    const wrapper = mountOverview(NINETY_DAYS);
    const users = tile(wrapper, "Users");

    expect(users.find(".kpi-value").text()).toBe("40");
    expect(users.find(".kpi-delta").text()).toBe("+30 in 30 days");
    expect(users.find(".kpi-delta").classes()).toContain("is-up");
    expect(users.find("polyline").attributes("points")).toBeTruthy();
  });

  it("switches the trend range", async () => {
    const wrapper = mountOverview(NINETY_DAYS);

    await wrapper.find("button[aria-label='Past 7 days']").trigger("click");

    expect(tile(wrapper, "Games").find(".kpi-delta").text()).toBe("+7 in 7 days");
    expect(wrapper.find("button[aria-label='Past 7 days']").attributes("aria-pressed")).toBe("true");
    expect(miniTile(wrapper, "Companies").find(".kpi-delta").text()).toBe("+7");
  });

  it("says when history doesn't cover the whole range", () => {
    const wrapper = mountOverview([snapshot(0, 0), snapshot(1, 1), snapshot(2, 3)]);

    expect(tile(wrapper, "Library entries").find(".kpi-delta").text()).toMatch(/^\+3 since /);
  });

  it("doesn't highlight more banned users as growth", () => {
    const banned = miniTile(mountOverview(NINETY_DAYS), "Banned users");

    expect(banned.find(".kpi-delta").text()).toBe("+30");
    expect(banned.find(".kpi-delta").classes()).not.toContain("is-up");
  });

  it("shows values without trends before any snapshot exists", () => {
    const wrapper = mountOverview([]);
    const games = tile(wrapper, "Games");

    expect(games.find(".kpi-value").text()).toBe((7685).toLocaleString());
    expect(games.find(".kpi-delta").text()).toBe("No history yet");
    expect(games.find("svg").exists()).toBeFalsy();
    expect(miniTile(wrapper, "Stores").find(".kpi-delta").text()).toBe("—");
  });
});
