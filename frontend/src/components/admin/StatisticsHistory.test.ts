import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount } from "@vue/test-utils";
import { ref } from "vue";
import StatisticsHistory from "./StatisticsHistory.vue";
import type { GetSiteStatisticsQuery } from "@/types/graphql";

type StatisticRow = NonNullable<GetSiteStatisticsQuery["siteStatistics"]>["nodes"][number];

// ── Hoisted mocks ─────────────────────────────────────────────────

const { queryState } = vi.hoisted(() => ({
  queryState: {
    data: null as unknown,
    variables: null as null | (() => Record<string, unknown>)
  }
}));

vi.mock("@/composables/useGraphQL", () => ({
  useQuery: (_query: unknown, options: { variables: () => Record<string, unknown> }) => {
    queryState.variables = options.variables;
    return { data: ref(queryState.data), loading: ref(false), error: ref(null) };
  }
}));

function statistic(overrides: Partial<StatisticRow> = {}): StatisticRow {
  return {
    id: "1",
    timestamp: "2026-11-07T00:00:00Z",
    users: 1234,
    games: 56789,
    platforms: 1,
    series: 2,
    engines: 3,
    companies: 4,
    genres: 5,
    stores: 6,
    events: 7,
    gamePurchases: 8,
    relationships: 9,
    gamesWithCovers: 10,
    gamesWithReleaseDates: 11,
    bannedUsers: 12,
    unmatchedGames: 13,
    mobygamesIds: 14,
    pcgamingwikiIds: 15,
    wikidataIds: 16,
    giantbombIds: 17,
    steamAppIds: 18,
    epicGamesStoreIds: 19,
    gogIds: 20,
    igdbIds: null,
    companyVersions: 21,
    gameVersions: 22,
    genreVersions: 23,
    engineVersions: 24,
    platformVersions: 25,
    seriesVersions: null,
    ...overrides
  };
}

function setRows(nodes: StatisticRow[], hasNextPage = false) {
  queryState.data = {
    siteStatistics: { nodes, pageInfo: { hasNextPage, endCursor: hasNextPage ? "cursor-1" : null } }
  };
}

function mountHistory() {
  return mount(StatisticsHistory, { attachTo: document.body });
}

function headers(wrapper: ReturnType<typeof mountHistory>) {
  return wrapper.findAll("thead th").map((th) => th.text());
}

// ── Tests ─────────────────────────────────────────────────────────

describe("StatisticsHistory", () => {
  beforeEach(() => {
    setRows([statistic()]);
  });

  it("requests the first page of statistics", () => {
    mountHistory();

    expect(queryState.variables?.()).toEqual({ first: 30, after: null });
  });

  it("shows the counts columns by default", () => {
    const wrapper = mountHistory();

    expect(headers(wrapper)).toEqual(expect.arrayContaining(["Date", "Users", "Games", "Unmatched Games"]));
    const cells = wrapper.findAll("tbody td").map((td) => td.text());
    expect(cells).toContain((1234).toLocaleString());
    expect(cells).toContain((56789).toLocaleString());
  });

  it("switches column groups and renders null values as a dash", async () => {
    const wrapper = mountHistory();

    await wrapper.find("#statistics-history-tab-externalIds").trigger("click");
    expect(headers(wrapper)).toEqual([
      "Date",
      "MobyGames",
      "PCGamingWiki",
      "Wikidata",
      "GiantBomb",
      "Steam",
      "Epic Games Store",
      "GOG",
      "IGDB"
    ]);
    expect(wrapper.findAll("tbody td").at(-1)?.text()).toBe("—");

    await wrapper.find("#statistics-history-tab-versions").trigger("click");
    expect(headers(wrapper)).toEqual(["Date", "Companies", "Games", "Genres", "Engines", "Platforms", "Series"]);
  });

  it("moves between tabs with the arrow keys", async () => {
    const wrapper = mountHistory();
    const countsTab = wrapper.find("#statistics-history-tab-counts");

    await countsTab.trigger("keydown", { key: "ArrowLeft" });

    const versionsTab = wrapper.find("#statistics-history-tab-versions");
    expect(versionsTab.attributes("aria-selected")).toBe("true");
    expect(document.activeElement).toBe(versionsTab.element);
    expect(countsTab.attributes("tabindex")).toBe("-1");
  });

  it("shows an empty state when nothing has been recorded", () => {
    setRows([]);
    const wrapper = mountHistory();

    expect(wrapper.text()).toContain("No statistics have been recorded yet.");
    expect(wrapper.find("table").exists()).toBeFalsy();
  });

  it("shows pagination only when there is another page", () => {
    expect(mountHistory().find(".pagination-nav").exists()).toBeFalsy();

    setRows([statistic()], true);
    expect(mountHistory().find(".pagination-nav").exists()).toBeTruthy();
  });
});
