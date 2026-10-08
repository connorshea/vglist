import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mount, flushPromises, RouterLinkStub, type VueWrapper } from "@vue/test-utils";
import { nextTick } from "vue";
import SearchPage from "./SearchPage.vue";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockRoute, pushMock, mockRequest } = vi.hoisted(() => ({
  mockRoute: { query: {} as Record<string, string> },
  pushMock: vi.fn<(to: { name: string; query: Record<string, string> }) => void>(),
  mockRequest: vi.fn<(query: string, variables: Record<string, unknown>) => Promise<unknown>>()
}));

// A reactive route that `push` updates, so tab switches and new searches
// re-render the mounted page the way vue-router would.
vi.mock("vue-router", async () => {
  const { reactive } = await import("vue");
  const route = reactive(mockRoute);
  pushMock.mockImplementation((to) => {
    route.query = to.query;
  });
  return {
    useRoute: () => route,
    useRouter: () => ({ push: pushMock })
  };
});

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/graphql/queries/search", () => ({
  SEARCH_OVERVIEW: "SEARCH_OVERVIEW",
  SEARCH_TAB: "SEARCH_TAB"
}));

// ── Helpers ───────────────────────────────────────────────────────

const TYPES = ["games", "companies", "platforms", "series", "engines", "genres", "stores", "users"];

function game(id: string, name: string) {
  return {
    id,
    name,
    releaseDate: null,
    coverUrl: null,
    isInLibrary: null,
    platforms: { totalCount: 0, nodes: [] },
    developers: { nodes: [] },
    publishers: { nodes: [] },
    series: null
  };
}

function overview(overrides: Record<string, { totalCount: number; nodes: unknown[] }> = {}) {
  return Object.fromEntries(TYPES.map((t) => [t, overrides[t] ?? { totalCount: 0, nodes: [] }]));
}

function tabPage(
  type: string,
  nodes: unknown[],
  { hasNextPage = false, endCursor = "cursor-1", totalCount = 30 } = {}
) {
  return { [type]: { totalCount, pageInfo: { hasNextPage, endCursor }, nodes } };
}

function respondWith({ overviewData = overview(), tabData = {} as Record<string, unknown> } = {}) {
  mockRequest.mockImplementation((query) => Promise.resolve(query === "SEARCH_OVERVIEW" ? overviewData : tabData));
}

// Every test shares the reactive route, so pages from earlier tests are
// unmounted (see afterEach) rather than left reacting to later route changes.
let mounted: VueWrapper[] = [];

async function mountPage(query: Record<string, string>) {
  pushMock({ name: "search", query });
  pushMock.mockClear();
  const wrapper = mount(SearchPage, { global: { stubs: { RouterLink: RouterLinkStub } }, attachTo: document.body });
  mounted.push(wrapper);
  await flushPromises();
  return wrapper;
}

async function settle() {
  await nextTick();
  await flushPromises();
}

function requestsFor(document: string) {
  return mockRequest.mock.calls.filter(([query]) => query === document);
}

function tab(wrapper: VueWrapper, label: string) {
  const found = wrapper.findAll('[role="tab"]').find((t) => t.text().startsWith(label));
  if (!found) throw new Error(`No tab labelled ${label}`);
  return found;
}

// ── Tests ─────────────────────────────────────────────────────────

describe("SearchPage", () => {
  beforeEach(() => {
    pushMock.mockClear();
    mockRequest.mockReset();
  });

  afterEach(() => {
    for (const wrapper of mounted) wrapper.unmount();
    mounted = [];
  });

  it("prompts for a longer query and makes no requests when the query is too short", async () => {
    const wrapper = await mountPage({ query: " a " });

    expect(wrapper.text()).toContain("Enter at least 2 characters");
    expect(mockRequest).not.toHaveBeenCalled();
    expect(wrapper.find('[role="tablist"]').exists()).toBeFalsy();
  });

  it("fills the search box from the URL and submits a new search", async () => {
    respondWith();
    const wrapper = await mountPage({ query: "halo", type: "games" });

    const input = wrapper.find<HTMLInputElement>('input[type="search"]');
    expect(input.element.value).toBe("halo");

    await input.setValue("  ratatouille ");
    await wrapper.find("form").trigger("submit");

    expect(pushMock).toHaveBeenCalledWith({ name: "search", query: { query: "ratatouille" } });
  });

  it("shows tab counts and sections on the All tab, hiding empty types", async () => {
    respondWith({
      overviewData: overview({
        games: { totalCount: 12, nodes: [game("1", "Ratatouille"), game("2", "Ratatouille")] },
        stores: { totalCount: 1, nodes: [{ id: "5", name: "Ratatouille Shop" }] }
      })
    });
    const wrapper = await mountPage({ query: "ratatouille" });

    expect(wrapper.findAll('[role="tab"]').map((t) => t.text())).toEqual([
      "All",
      "Games (12)",
      "Companies (0)",
      "Platforms (0)",
      "Series (0)",
      "Engines (0)",
      "Genres (0)",
      "Stores (1)",
      "Users (0)"
    ]);
    expect(tab(wrapper, "All").attributes("aria-selected")).toBe("true");
    expect(wrapper.findAll("h2").map((h) => h.text())).toEqual(["Games", "Stores"]);

    const seeAll = wrapper.findAllComponents(RouterLinkStub).find((l) => l.text().includes("See all 12 games"));
    expect(seeAll?.props("to")).toEqual({ name: "search", query: { query: "ratatouille", type: "games" } });
    expect(requestsFor("SEARCH_TAB")).toHaveLength(0);
  });

  it("says so when nothing matches", async () => {
    respondWith();
    const wrapper = await mountPage({ query: "zzzz" });

    expect(wrapper.text()).toContain('No results for "zzzz"');
  });

  it("treats an unknown type as the All tab", async () => {
    respondWith();
    const wrapper = await mountPage({ query: "halo", type: "consoles" });

    expect(wrapper.find('[role="tab"][aria-selected="true"]').text()).toBe("All");
  });

  it("loads a tab with one request, fetching only that type, without refetching the overview", async () => {
    respondWith({ tabData: tabPage("games", [game("9", "Halo 3")]) });
    const wrapper = await mountPage({ query: "halo" });

    await tab(wrapper, "Games").trigger("click");
    await settle();

    expect(pushMock).toHaveBeenCalledWith({ name: "search", query: { query: "halo", type: "games" } });
    expect(requestsFor("SEARCH_TAB")).toHaveLength(1);
    expect(requestsFor("SEARCH_TAB")[0][1]).toEqual({
      query: "halo",
      first: 10,
      after: null,
      ...Object.fromEntries(TYPES.map((t) => [t, t === "games"]))
    });
    expect(requestsFor("SEARCH_OVERVIEW")).toHaveLength(1);
    expect(wrapper.text()).toContain("Halo 3");

    respondWith({ tabData: tabPage("stores", [{ id: "4", name: "Halo Store" }]) });
    await tab(wrapper, "Stores").trigger("click");
    await settle();

    expect(requestsFor("SEARCH_TAB")).toHaveLength(2);
    expect(requestsFor("SEARCH_TAB")[1][1]).toMatchObject({ first: 25, stores: true, games: false });
    expect(requestsFor("SEARCH_OVERVIEW")).toHaveLength(1);
    expect(wrapper.text()).toContain("Halo Store");
  });

  it("pages with the cursor history and keeps the pagination controls mounted while loading", async () => {
    respondWith({ tabData: tabPage("games", [game("1", "Halo")], { hasNextPage: true, endCursor: "after-page-1" }) });
    const wrapper = await mountPage({ query: "halo", type: "games" });

    let resolveNext!: (value: unknown) => void;
    mockRequest.mockImplementationOnce(() => new Promise((resolve) => (resolveNext = resolve)));

    const next = wrapper.find<HTMLButtonElement>('[aria-label="Next page"]');
    next.element.focus();
    await next.trigger("click");
    await nextTick();

    // Still on screen (and focused) while page 2 loads.
    expect(wrapper.find('[aria-label="Next page"]').exists()).toBeTruthy();
    expect(document.activeElement).toBe(next.element);
    expect(requestsFor("SEARCH_TAB").at(-1)?.[1]).toMatchObject({ after: "after-page-1" });

    resolveNext(tabPage("games", [game("2", "Halo 2")], { hasNextPage: false }));
    await settle();
    expect(wrapper.text()).toContain("Halo 2");
    expect(wrapper.find('[aria-current="page"]').text()).toBe("2");

    await wrapper.find('[aria-label="Previous page"]').trigger("click");
    await settle();
    expect(requestsFor("SEARCH_TAB").at(-1)?.[1]).toMatchObject({ after: null });
  });

  it("goes back to page 1 when the search changes", async () => {
    respondWith({ tabData: tabPage("games", [game("1", "Halo")], { hasNextPage: true, endCursor: "after-page-1" }) });
    const wrapper = await mountPage({ query: "halo", type: "games" });

    await wrapper.find('[aria-label="Next page"]').trigger("click");
    await settle();
    pushMock({ name: "search", query: { query: "zelda", type: "games" } });
    await settle();

    expect(requestsFor("SEARCH_TAB").at(-1)?.[1]).toMatchObject({ query: "zelda", after: null });
  });

  it("moves focus between tabs with the arrow keys and selects on Enter, like the ARIA tabs pattern", async () => {
    respondWith();
    const wrapper = await mountPage({ query: "halo" });
    const tablist = wrapper.find('[role="tablist"]');

    (tab(wrapper, "All").element as HTMLElement).focus();
    await tablist.trigger("keydown", { key: "ArrowLeft" });
    await nextTick();

    expect(document.activeElement).toBe(tab(wrapper, "Users").element);
    expect(tab(wrapper, "Users").attributes("tabindex")).toBe("0");
    expect(tab(wrapper, "All").attributes("tabindex")).toBe("-1");
    expect(pushMock).not.toHaveBeenCalled();

    await tab(wrapper, "Users").trigger("click");
    expect(pushMock).toHaveBeenCalledWith({ name: "search", query: { query: "halo", type: "users" } });
  });

  it("leaves Alt+Arrow alone so browser back/forward still work", async () => {
    respondWith();
    const wrapper = await mountPage({ query: "halo" });
    (tab(wrapper, "All").element as HTMLElement).focus();

    const event = new KeyboardEvent("keydown", { key: "ArrowLeft", altKey: true, bubbles: true, cancelable: true });
    wrapper.find('[role="tablist"]').element.dispatchEvent(event);

    expect(event.defaultPrevented).toBeFalsy();
    expect(document.activeElement).toBe(tab(wrapper, "All").element);
  });

  it("shows the API's error message (not the raw response) with a Retry button that refetches", async () => {
    mockRequest.mockRejectedValueOnce(
      Object.assign(new Error('{"response":{"errors":[{"message":"query is too long"}]}}'), {
        response: { errors: [{ message: "query is too long" }] }
      })
    );
    const wrapper = await mountPage({ query: "halo" });

    expect(wrapper.text()).toContain("Search failed: query is too long");
    expect(wrapper.text()).not.toContain('"response"');
    expect(wrapper.find('[role="tablist"]').exists()).toBeTruthy();

    respondWith({ overviewData: overview({ games: { totalCount: 1, nodes: [game("1", "Halo")] } }) });
    await wrapper.find(".retry-button").trigger("click");
    await flushPromises();

    expect(wrapper.text()).not.toContain("Search failed");
    expect(wrapper.text()).toContain("Halo");
  });
});
