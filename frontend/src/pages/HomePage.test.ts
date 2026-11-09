import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mount, flushPromises, RouterLinkStub, enableAutoUnmount } from "@vue/test-utils";
import type { DocumentNode } from "graphql";
import HomePage from "./HomePage.vue";
import { resetSaveDataForTests } from "@/composables/useSaveData";

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
    if (definition.kind === "OperationDefinition" && definition.name) {
      return definition.name.value;
    }
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
    case "GetNewReleases":
      return Promise.resolve({ newReleases: [game("new-1", "Hades II")] });
    case "GetUpcomingReleases":
      return Promise.resolve({
        upcomingReleases: [{ ...game("upcoming-1", "Hollow Knight: Silksong"), releaseDate: "2099-02-24" }]
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
  // A page left mounted keeps its mosaic timers running. Once the file has
  // been going for 5s their fallback fires, flips start, and every new timer
  // they set while a later test has fake timers on lands on that test's
  // clock, so the flip test ends up animating every earlier page too.
  enableAutoUnmount(afterEach);

  beforeEach(() => {
    mockRequest.mockReset();
    mockRequest.mockImplementation(respond);
    mockOpen.mockReset();
    auth.isAuthenticated = false;
    Reflect.deleteProperty(navigator, "connection");
    resetSaveDataForTests();
  });

  it("puts the game count in the search box", async () => {
    const wrapper = await mountPage();
    expect(wrapper.find(".home-search").text()).toContain("Search 7,685 games and more");
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

  it("holds the pill row's place with placeholders while the pills load", async () => {
    mockRequest.mockImplementation((document, variables) =>
      operationName(document) === "GetGamesIndexFilters" ? new Promise(() => {}) : respond(document, variables)
    );
    const wrapper = await mountPage();
    expect(wrapper.find(".home-quick-slot").exists()).toBeTruthy();
    expect(wrapper.findAll(".home-quick-skeleton").length).toBeGreaterThan(0);
    expect(wrapper.find(".home-quick-link").exists()).toBeFalsy();
  });

  it("keeps the pill row's place but drops the placeholders if the pills fail to load", async () => {
    mockRequest.mockImplementation((document, variables) =>
      operationName(document) === "GetGamesIndexFilters"
        ? Promise.reject(new Error("boom"))
        : respond(document, variables)
    );
    const wrapper = await mountPage();
    expect(wrapper.find(".home-quick-slot").exists()).toBeTruthy();
    expect(wrapper.find(".home-quick-skeleton").exists()).toBeFalsy();
  });

  it("hides the pills that don't fit on the first row", async () => {
    // jsdom has no layout, so put every pill after the fourth on a second row.
    const offsetTop = vi.spyOn(HTMLElement.prototype, "offsetTop", "get").mockImplementation(function (
      this: HTMLElement
    ) {
      if (!this.classList.contains("home-quick-link")) {
        return 0;
      }
      return Array.from(this.parentElement?.children ?? []).indexOf(this) < 4 ? 0 : 44;
    });
    try {
      const wrapper = await mountPage();
      const hidden = wrapper.findAll(".home-quick-link").map((link) => link.classes("is-overflowing"));
      expect(hidden).toEqual([false, false, false, false, true, true, true]);
    } finally {
      offsetTop.mockRestore();
    }
  });

  it("shows popular games, new and upcoming releases and recently added games, linking to the games index", async () => {
    const wrapper = await mountPage();
    expect(wrapper.findAll(".game-shelf-title").map((h) => h.text())).toEqual([
      "Popular",
      "New releases",
      "Upcoming releases",
      "Recently added to vglist"
    ]);
    const seeAll = wrapper.findAllComponents(RouterLinkStub).filter((link) => link.classes("game-shelf-more"));
    expect(seeAll.map((link) => link.props("to"))).toEqual([
      { path: "/games", query: {} },
      { path: "/games", query: { sort: "new" } },
      { path: "/games", query: { sort: "upcoming" } },
      { path: "/games", query: { sort: "added" } }
    ]);
    const sorts = mockRequest.mock.calls
      .filter(([document]) => operationName(document) === "GetGamesIndex")
      .map(([, variables]) => variables?.sortBy);
    expect(sorts).toEqual(["MOST_OWNERS", "NEWEST"]);
    const newReleases = mockRequest.mock.calls.filter(([document]) => operationName(document) === "GetNewReleases");
    expect(newReleases.map(([, variables]) => variables)).toEqual([{ first: 12 }]);
    expect(wrapper.findAll(".game-shelf")[1].text()).toContain("Hades II");
    const upcoming = mockRequest.mock.calls.filter(([document]) => operationName(document) === "GetUpcomingReleases");
    expect(upcoming.map(([, variables]) => variables)).toEqual([{ first: 6 }]);
    // Upcoming games show the day they come out.
    const upcomingShelf = wrapper.findAll(".game-shelf")[2];
    expect(upcomingShelf.find(".game-tile-meta").text()).toBe("Feb 24, 2099");
  });

  it("leaves out a shelf with no games", async () => {
    mockRequest.mockImplementation((document, variables) =>
      operationName(document) === "GetUpcomingReleases"
        ? Promise.resolve({ upcomingReleases: [] })
        : operationName(document) === "GetNewReleases"
          ? Promise.resolve({ newReleases: [] })
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

  it("sums up the site in one line", async () => {
    const wrapper = await mountPage();
    expect(wrapper.find(".home-stats").text().replace(/\s+/g, " ")).toBe(
      "7,685 games · 2,928 series · 69 platforms · 9,470 companies"
    );
  });

  it("hides the background mosaic from assistive technology", async () => {
    const wrapper = await mountPage();
    expect(wrapper.find(".cover-scene").attributes("aria-hidden")).toBe("true");
  });

  it("fills the background mosaic with covers", async () => {
    await mountPage();
    expect(mockRequest.mock.calls.map(([document]) => operationName(document))).toContain("GetHeroCovers");
  });

  it("downloads the mosaic covers at low priority and only shows each one once it has loaded", async () => {
    const images: HTMLImageElement[] = [];
    class FakeImage extends EventTarget {
      fetchPriority = "auto";
      src = "";
      constructor() {
        super();
        images.push(this as unknown as HTMLImageElement);
      }
    }
    vi.stubGlobal("Image", FakeImage);
    mockRequest.mockImplementation((document, variables) =>
      operationName(document) === "GetHeroCovers"
        ? Promise.resolve({
            games: { nodes: [1, 2, 3, 4].map((n) => ({ id: String(n), coverUrl: `https://files.example/${n}.jpg` })) }
          })
        : respond(document, variables)
    );
    try {
      const wrapper = await mountPage();
      expect(images.map((img) => img.src).sort()).toEqual([1, 2, 3, 4].map((n) => `https://files.example/${n}.jpg`));
      expect(images.every((img) => img.fetchPriority === "low")).toBeTruthy();
      // Nothing points at a cover until its download finishes, so the
      // stylesheet never starts a second, normal priority request.
      expect(wrapper.find(".cover-mosaic").html()).not.toContain("files.example");

      const first = images[0];
      first.dispatchEvent(new Event("load"));
      await flushPromises();
      const html = wrapper.find(".cover-mosaic").html();
      expect(html).toContain(first.src);
      for (const img of images.slice(1)) {
        expect(html).not.toContain(img.src);
      }
    } finally {
      vi.unstubAllGlobals();
    }
  });

  it("doesn't let a cover that loads late replace what a flipped tile is showing", async () => {
    const images: HTMLImageElement[] = [];
    class FakeImage extends EventTarget {
      src = "";
      constructor() {
        super();
        images.push(this as unknown as HTMLImageElement);
      }
    }
    vi.stubGlobal("Image", FakeImage);
    // Every flip picks the same tile, which is one that gets a cover.
    vi.spyOn(Math, "random").mockReturnValue(0.5);
    vi.useFakeTimers({ toFake: ["setTimeout", "setInterval"] });
    mockRequest.mockImplementation((document, variables) =>
      operationName(document) === "GetHeroCovers"
        ? Promise.resolve({ games: { nodes: [{ id: "1", coverUrl: "https://files.example/1.jpg" }] } })
        : respond(document, variables)
    );
    try {
      const wrapper = await mountPage();
      // The cover hasn't loaded, so the 5s fallback reveals the mosaic, flips
      // start 300ms later, and the first flip swaps its tile 400ms after that.
      await vi.advanceTimersByTimeAsync(5000 + 300 + 160 + 400 + 50);
      const flipping = wrapper.findAll(".cover-tile.flipping .tile-face");
      expect(flipping.length).toBeGreaterThan(0);

      images[0].dispatchEvent(new Event("load"));
      await flushPromises();
      expect(wrapper.find(".cover-mosaic").html()).toContain("files.example/1.jpg");
      for (const face of flipping) {
        expect(face.attributes("style") ?? "").not.toContain("files.example");
      }
    } finally {
      vi.useRealTimers();
      vi.restoreAllMocks();
      vi.unstubAllGlobals();
    }
  });

  it("doesn't start flipping mosaic tiles after the page has gone", async () => {
    vi.useFakeTimers({ toFake: ["setTimeout", "setInterval", "clearTimeout", "clearInterval"] });
    try {
      const wrapper = await mountPage();
      // Unmount between the 5s reveal and the flips starting 300ms later.
      await vi.advanceTimersByTimeAsync(5100);
      wrapper.unmount();
      const setIntervalSpy = vi.spyOn(globalThis, "setInterval");
      await vi.advanceTimersByTimeAsync(1000);
      expect(setIntervalSpy).not.toHaveBeenCalled();
    } finally {
      vi.useRealTimers();
      vi.restoreAllMocks();
    }
  });

  it("ignores mosaic covers that finish loading after data saver was toggled", async () => {
    const images: HTMLImageElement[] = [];
    class FakeImage extends EventTarget {
      src = "";
      constructor() {
        super();
        images.push(this as unknown as HTMLImageElement);
      }
    }
    vi.stubGlobal("Image", FakeImage);
    const connection = Object.assign(new EventTarget(), { saveData: false });
    Object.defineProperty(navigator, "connection", { value: connection, configurable: true });
    mockRequest.mockImplementation((document, variables) =>
      operationName(document) === "GetHeroCovers"
        ? Promise.resolve({ games: { nodes: [{ id: "1", coverUrl: "https://files.example/1.jpg" }] } })
        : respond(document, variables)
    );
    try {
      const wrapper = await mountPage();
      expect(images).toHaveLength(1);

      // Data saver goes on, then off again, before the first preload finishes.
      connection.saveData = true;
      connection.dispatchEvent(new Event("change"));
      await flushPromises();
      connection.saveData = false;
      connection.dispatchEvent(new Event("change"));
      await flushPromises();
      // Turning it off again restarts the preload (twice: once straight away
      // and once more when the hero covers query refetches).
      expect(images.length).toBeGreaterThan(1);

      images[0].dispatchEvent(new Event("load"));
      await flushPromises();
      expect(wrapper.find(".cover-mosaic").html()).not.toContain("files.example");

      images[images.length - 1].dispatchEvent(new Event("load"));
      await flushPromises();
      expect(wrapper.find(".cover-mosaic").html()).toContain("files.example/1.jpg");
    } finally {
      vi.unstubAllGlobals();
    }
  });

  it("skips the cover images in the background mosaic when the browser asks to save data", async () => {
    Object.defineProperty(navigator, "connection", {
      value: Object.assign(new EventTarget(), { saveData: true }),
      configurable: true
    });
    const wrapper = await mountPage();
    expect(mockRequest.mock.calls.map(([document]) => operationName(document))).not.toContain("GetHeroCovers");
    // The gradient tiles show right away instead of waiting on covers.
    expect(wrapper.find(".cover-mosaic").classes()).toContain("covers-loaded");
  });
});
