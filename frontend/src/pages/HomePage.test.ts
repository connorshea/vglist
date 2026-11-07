import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises, RouterLinkStub } from "@vue/test-utils";
import type { DocumentNode } from "graphql";
import HomePage from "./HomePage.vue";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockRequest, mockOpen, auth } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: DocumentNode, variables?: Record<string, unknown>) => Promise<unknown>>(),
  mockOpen: vi.fn<(query?: string) => void>(),
  auth: { isAuthenticated: false }
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/stores/auth", () => ({
  useAuthStore: () => auth
}));

vi.mock("@/composables/useSearchOverlay", () => ({
  useSearchOverlay: () => ({ open: mockOpen })
}));

function operationName(document: DocumentNode): string {
  for (const definition of document.definitions) {
    if (definition.kind === "OperationDefinition" && definition.name) return definition.name.value;
  }
  return "";
}

function game(id: string, name: string) {
  return {
    id,
    name,
    releaseDate: "2017-02-24",
    avgRating: 93,
    coverUrl: null,
    isInLibrary: false,
    libraryCompletionStatus: null,
    ownerCount: 588
  };
}

// Answers each query the page sends with a small fixed response.
function respond(document: DocumentNode, variables?: Record<string, unknown>) {
  switch (operationName(document)) {
    case "GetBasicSiteStatistics":
      return Promise.resolve({
        basicSiteStatistics: { games: 7685, series: 2928, platforms: 69, companies: 9470, engines: 598, genres: 162 }
      });
    case "GetGamesIndexFilters":
      return Promise.resolve({
        basicSiteStatistics: { games: 7685 },
        platforms: {
          nodes: ["Windows", "macOS", "Linux", "PlayStation 4", "Xbox One"].map((name, i) => ({ id: `p${i}`, name }))
        },
        genres: { nodes: ["Action", "Adventure", "Puzzle", "RPG"].map((name, i) => ({ id: `g${i}`, name })) }
      });
    case "GetGamesIndex":
      return Promise.resolve({
        games: {
          nodes: [game(`${String(variables?.sortBy)}-1`, "Hollow Knight")],
          pageInfo: { hasNextPage: true, endCursor: "c" }
        }
      });
    default:
      return Promise.resolve({ games: { nodes: [] } });
  }
}

async function mountPage() {
  const wrapper = mount(HomePage, { global: { stubs: { RouterLink: RouterLinkStub } } });
  await flushPromises();
  return wrapper;
}

// ── Tests ─────────────────────────────────────────────────────────

describe("HomePage", () => {
  beforeEach(() => {
    mockRequest.mockReset();
    mockRequest.mockImplementation(respond);
    mockOpen.mockReset();
    auth.isAuthenticated = false;
  });

  it("puts the game count in the search box", async () => {
    const wrapper = await mountPage();
    expect(wrapper.find(".home-search").text()).toContain("Search 7,685 games, companies and more");
  });

  it("opens the search overlay when the search box is clicked", async () => {
    const wrapper = await mountPage();
    await wrapper.find(".home-search").trigger("click");
    expect(mockOpen).toHaveBeenCalledWith();
  });

  it("starts the search with whatever is typed into the search box", async () => {
    const wrapper = await mountPage();
    await wrapper.find(".home-search").trigger("keydown", { key: "h" });
    expect(mockOpen).toHaveBeenCalledWith("h");
  });

  it("links to the four biggest platforms and three biggest genres", async () => {
    const wrapper = await mountPage();
    const links = wrapper.findAll(".home-quick-link");
    expect(links.map((link) => link.text())).toEqual([
      "Windows",
      "macOS",
      "Linux",
      "PlayStation 4",
      "Action",
      "Adventure",
      "Puzzle"
    ]);
    const pills = wrapper.findAllComponents(RouterLinkStub).filter((link) => link.classes("home-quick-link"));
    expect(pills[0].props("to")).toEqual({ path: "/games", query: { platform: "p0" } });
    expect(pills[4].props("to")).toEqual({ path: "/games", query: { genre: "g0" } });
  });

  it("shows popular games, new releases and recently added games, each linking to the games index", async () => {
    const wrapper = await mountPage();
    expect(wrapper.findAll(".game-shelf-title").map((h) => h.text())).toEqual([
      "Popular",
      "New releases",
      "Recently added to vglist"
    ]);
    const seeAll = wrapper.findAllComponents(RouterLinkStub).filter((link) => link.classes("game-shelf-more"));
    expect(seeAll.map((link) => link.props("to"))).toEqual([
      { path: "/games", query: {} },
      { path: "/games", query: { sort: "new" } },
      { path: "/games", query: { sort: "added" } }
    ]);
    const sorts = mockRequest.mock.calls
      .filter(([document]) => operationName(document) === "GetGamesIndex")
      .map(([, variables]) => variables?.sortBy);
    expect(sorts).toEqual(["MOST_OWNERS", "RECENTLY_RELEASED", "NEWEST"]);
  });

  it("leaves out a shelf with no games", async () => {
    mockRequest.mockImplementation((document, variables) =>
      operationName(document) === "GetGamesIndex" && variables?.sortBy === "RECENTLY_RELEASED"
        ? Promise.resolve({ games: { nodes: [], pageInfo: { hasNextPage: false, endCursor: null } } })
        : respond(document, variables)
    );
    const wrapper = await mountPage();
    expect(wrapper.findAll(".game-shelf-title").map((h) => h.text())).toEqual(["Popular", "Recently added to vglist"]);
  });

  it("asks signed-out visitors to create an account", async () => {
    const wrapper = await mountPage();
    const banner = wrapper.find(".home-banner");
    expect(banner.exists()).toBeTruthy();
    expect(banner.findComponent(RouterLinkStub).props("to")).toBe("/signup");
  });

  it("doesn't ask signed-in users to create an account", async () => {
    auth.isAuthenticated = true;
    const wrapper = await mountPage();
    expect(wrapper.find(".home-banner").exists()).toBeFalsy();
  });

  it("sums up the site in one line and credits Wikidata", async () => {
    const wrapper = await mountPage();
    expect(wrapper.find(".home-credit").text().replace(/\s+/g, " ")).toBe(
      "7,685 games · 2,928 series · 69 platforms · 9,470 companies, with game data from Wikidata."
    );
  });

  it("hides the background mosaic from assistive technology", async () => {
    const wrapper = await mountPage();
    expect(wrapper.find(".cover-scene").attributes("aria-hidden")).toBe("true");
  });
});
