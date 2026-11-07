import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises, RouterLinkStub } from "@vue/test-utils";
import UserComparePage from "./UserComparePage.vue";
import { GET_COMPARISON_IN_COMMON, GET_COMPARISON_ONLY, GET_LIBRARY_COMPARISON } from "@/graphql/queries/compare";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockRequest, mockReplace, mockPush, mockRoute } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>(),
  mockReplace: vi.fn<(to: unknown) => Promise<void>>(),
  mockPush: vi.fn<(to: unknown) => Promise<void>>(),
  mockRoute: { params: { slug: "connorshea", otherSlug: "kestrel" }, query: {} as Record<string, string> }
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("vue-router", async () => {
  const { reactive: makeReactive } = await import("vue");
  const route = makeReactive(mockRoute);
  return {
    useRoute: () => route,
    useRouter: () => ({ replace: mockReplace, push: mockPush })
  };
});

vi.mock("@/stores/auth", () => ({
  useAuthStore: () => ({ isAuthenticated: true, user: { id: "1", slug: "connorshea" } })
}));

// ── Fixtures ──────────────────────────────────────────────────────

function user(id: string, username: string) {
  return { id, username, slug: username, avatarUrl: null };
}

function tile(id: string, name: string, rating: number) {
  return { id, game: { id: `g${id}`, name, coverUrl: null }, hoursPlayed: null, completionStatus: "COMPLETED", rating };
}

const SUMMARY = {
  libraryComparison: {
    userA: user("1", "connorshea"),
    userB: user("2", "kestrel"),
    inCommonCount: 168,
    onlyACount: 244,
    onlyBCount: 936,
    bothRatedCount: 121,
    averageRatingGap: 7.2,
    onlyA: { nodes: [tile("10", "Portal 2", 95)] },
    onlyB: { nodes: [tile("20", "Bloodborne", 97)] }
  }
};

function row(name: string, a: number | null, b: number | null) {
  return {
    game: { id: name, name, coverUrl: null, developers: { nodes: [{ id: "d", name: "FromSoftware" }] } },
    purchaseA: { id: `${name}-a`, rating: a, completionStatus: "PAUSED" },
    purchaseB: { id: `${name}-b`, rating: b, completionStatus: "COMPLETED" },
    ratingDifference: a !== null && b !== null ? a - b : null
  };
}

const IN_COMMON = {
  libraryComparison: {
    inCommon: {
      totalCount: 121,
      pageInfo: { hasNextPage: true, endCursor: "c1" },
      nodes: [row("Elden Ring", 79, 98), row("Disco Elysium", 97, 78)]
    }
  }
};

const ONLY_B = {
  libraryComparison: {
    onlyB: {
      totalCount: 936,
      pageInfo: { hasNextPage: false, endCursor: null },
      nodes: [tile("20", "Bloodborne", 97), tile("21", "Slay the Spire", 95)]
    }
  }
};

function respond(summary: unknown = SUMMARY) {
  mockRequest.mockImplementation((query) => {
    if (query === GET_LIBRARY_COMPARISON) return Promise.resolve(summary);
    if (query === GET_COMPARISON_IN_COMMON) return Promise.resolve(IN_COMMON);
    if (query === GET_COMPARISON_ONLY) return Promise.resolve(ONLY_B);
    return Promise.reject(new Error("unexpected query"));
  });
}

function callsFor(query: unknown) {
  return mockRequest.mock.calls.filter(([q]) => q === query).map(([, variables]) => variables);
}

async function mountPage() {
  const wrapper = mount(UserComparePage, {
    global: { stubs: { RouterLink: RouterLinkStub, CompareUserDialog: true } }
  });
  await flushPromises();
  return wrapper;
}

// ── Tests ─────────────────────────────────────────────────────────

describe("UserComparePage", () => {
  beforeEach(() => {
    mockRequest.mockReset();
    mockReplace.mockReset();
    mockRoute.query = {};
  });

  it("shows both users, the overlap counts and the games in common", async () => {
    respond();
    const wrapper = await mountPage();

    expect(callsFor(GET_LIBRARY_COMPARISON)[0]).toEqual({
      userASlug: "connorshea",
      userBSlug: "kestrel",
      shelfCount: 6
    });
    expect(wrapper.find("h1").text()).toBe("connorshea & kestrel");
    expect(wrapper.find(".compare-stats").text()).toContain("412 and 1,104 games");
    expect(wrapper.find(".compare-overlap").attributes("aria-label")).toBe(
      "244 games only connorshea has, 168 in common, 936 games only kestrel has"
    );
    expect(wrapper.findAll(".compare-table tbody tr")).toHaveLength(2);
  });

  it("spells out who rated each game higher for screen readers", async () => {
    respond();
    const wrapper = await mountPage();

    const gaps = wrapper.findAll(".compare-table tbody tr").map((tr) => tr.findAll(".is-sr-only").at(-1)?.text());
    expect(gaps).toEqual(["kestrel rated it 19 higher", "connorshea rated it 19 higher"]);
  });

  it("asks for the overview's ten biggest disagreements among games both users rated", async () => {
    respond();
    await mountPage();

    expect(callsFor(GET_COMPARISON_IN_COMMON)[0]).toMatchObject({
      first: 10,
      sortBy: "RATING_GAP",
      bothRated: true,
      search: null
    });
  });

  it("re-sorts by a column when its header is clicked, and shows all shared games on request", async () => {
    respond();
    const wrapper = await mountPage();

    const gameHeader = wrapper.findAll(".compare-th").find((button) => button.text() === "Game");
    await gameHeader?.trigger("click");
    await flushPromises();
    expect(callsFor(GET_COMPARISON_IN_COMMON).at(-1)).toMatchObject({ sortBy: "GAME_NAME" });
    expect(wrapper.find('th[aria-sort="ascending"]').text()).toBe("Game");

    const allShared = wrapper.findAll(".compare-seg button").find((button) => button.text() === "All shared");
    await allShared?.trigger("click");
    await flushPromises();
    expect(callsFor(GET_COMPARISON_IN_COMMON).at(-1)).toMatchObject({ bothRated: false });
    expect(allShared?.attributes("aria-pressed")).toBe("true");
  });

  it("shows every shared game, not just the rated ones, after following See all", async () => {
    respond();
    const wrapper = await mountPage();

    const seeAll = wrapper.findAllComponents(RouterLinkStub).find((link) => link.text().startsWith("See all"));
    await seeAll?.trigger("click");
    await flushPromises();

    expect(seeAll?.props("to")).toMatchObject({ query: { tab: "common" } });
    expect(callsFor(GET_COMPARISON_IN_COMMON).at(-1)).toMatchObject({ bothRated: false });
  });

  it("shows the highest-rated games only each user has on the overview", async () => {
    respond();
    const wrapper = await mountPage();

    const shelves = wrapper.findAll(".compare-shelf");
    expect(shelves.map((shelf) => shelf.find("h3").text())).toEqual([
      "Only in your library",
      "Only in kestrel's library"
    ]);
    expect(shelves[1].text()).toContain("Bloodborne");
  });

  it("loads one side's games on its Only tab", async () => {
    mockRoute.query = { tab: "only-b" };
    respond();
    const wrapper = await mountPage();

    expect(callsFor(GET_COMPARISON_IN_COMMON)).toHaveLength(0);
    expect(callsFor(GET_COMPARISON_ONLY)[0]).toMatchObject({ sideA: false, sortBy: "HIGHEST_RATING", first: 50 });
    expect(wrapper.find("#compare-only-heading").text()).toContain("Only in kestrel's library");
    expect(wrapper.findAll(".library-tile")).toHaveLength(2);
  });

  it("swaps sides, flipping the Only tab so it shows the same games", async () => {
    mockRoute.query = { tab: "only-b" };
    respond();
    const wrapper = await mountPage();

    const swap = wrapper.findAllComponents(RouterLinkStub).find((link) => link.text().includes("Swap sides"));
    expect(swap?.props("to")).toEqual({
      name: "userCompare",
      params: { slug: "kestrel", otherSlug: "connorshea" },
      query: { tab: "only-a" }
    });
  });

  it("goes to the not found page when either user doesn't exist", async () => {
    respond({ libraryComparison: null });
    await mountPage();

    expect(mockReplace).toHaveBeenCalledWith({ name: "notFound" });
  });

  it("explains why when a library can't be compared", async () => {
    mockRequest.mockRejectedValue(new Error("You aren't allowed to see kestrel's library."));
    const wrapper = await mountPage();

    expect(wrapper.find(".compare-message-title").text()).toBe("You aren't allowed to see kestrel's library.");
    expect(mockReplace).not.toHaveBeenCalled();
  });
});
