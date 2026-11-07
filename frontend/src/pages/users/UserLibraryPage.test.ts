import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import { createMemoryHistory, createRouter } from "vue-router";
import UserLibraryPage from "./UserLibraryPage.vue";
import LibraryPageSkeleton from "@/components/library/LibraryPageSkeleton.vue";
import LibrarySkeleton from "@/components/library/LibrarySkeleton.vue";
import { GET_LIBRARY_GAMES, GET_LIBRARY_PAGE, GET_LIBRARY_SHELVES } from "@/graphql/queries/library";

// The loading skeletons: which one shows while each query is in flight.

const { mockRequest } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>()
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/stores/auth", () => ({
  useAuthStore: () => ({ isAuthenticated: true, user: { id: "1", slug: "connorshea" } })
}));

const EMPTY_SHELF = { totalCount: 0, nodes: [] };

const PAGE = {
  user: {
    id: "1",
    hideDaysPlayed: false,
    libraryStatistics: {
      gamesCount: 0,
      statusCounts: [],
      platformCounts: [],
      storeCounts: []
    }
  }
};

const SHELVES = {
  user: {
    id: "1",
    inProgress: EMPTY_SHELF,
    paused: EMPTY_SHELF,
    completed: EMPTY_SHELF,
    fullyCompleted: EMPTY_SHELF,
    unplayed: EMPTY_SHELF,
    dropped: EMPTY_SHELF,
    notApplicable: EMPTY_SHELF,
    noStatus: EMPTY_SHELF
  }
};

const GAMES = {
  user: {
    id: "1",
    gamePurchases: { totalCount: 0, pageInfo: { hasNextPage: false, endCursor: null }, nodes: [] }
  }
};

// Resolves each query only when the test says so.
function deferQueries() {
  const pending = new Map<unknown, (value: unknown) => void>();
  mockRequest.mockImplementation(
    (query) =>
      new Promise((resolve) => {
        pending.set(query, resolve);
      })
  );
  return async (query: unknown, value: unknown) => {
    pending.get(query)?.(value);
    await flushPromises();
  };
}

async function mountLibrary(path = "/users/connorshea/library") {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/users/:slug/library", name: "userLibrary", component: UserLibraryPage },
      { path: "/games/:id", name: "game", component: { template: "<div />" } }
    ]
  });
  await router.push(path);
  const wrapper = mount({ template: "<router-view />" }, { global: { plugins: [router] } });
  await flushPromises();
  return wrapper;
}

describe("UserLibraryPage loading state", () => {
  beforeEach(() => {
    mockRequest.mockReset();
  });

  it("outlines the whole tab, then the shelves, then shows the library", async () => {
    const resolve = deferQueries();
    const wrapper = await mountLibrary();
    const page = wrapper.find(".library-page");
    const status = wrapper.find("[role='status']");

    expect(wrapper.findComponent(LibraryPageSkeleton).exists()).toBeTruthy();
    expect(page.attributes("aria-busy")).toBe("true");
    expect(status.text()).toBe("Loading library…");

    await resolve(GET_LIBRARY_PAGE, PAGE);
    expect(wrapper.findComponent(LibraryPageSkeleton).exists()).toBeFalsy();
    expect(wrapper.findComponent(LibrarySkeleton).props("variant")).toBe("shelves");
    expect(wrapper.text()).not.toContain("No games in this library yet");

    await resolve(GET_LIBRARY_SHELVES, SHELVES);
    expect(wrapper.findComponent(LibrarySkeleton).exists()).toBeFalsy();
    expect(page.attributes("aria-busy")).toBe("false");
    expect(status.text()).toBe("");
    expect(wrapper.text()).toContain("No games in this library yet");
  });

  it("outlines a single grid when a status is picked", async () => {
    const resolve = deferQueries();
    const wrapper = await mountLibrary("/users/connorshea/library?status=COMPLETED");

    expect(wrapper.findComponent(LibraryPageSkeleton).props("grouped")).toBeFalsy();

    await resolve(GET_LIBRARY_PAGE, PAGE);
    expect(wrapper.findComponent(LibrarySkeleton).props("variant")).toBe("grid");
    expect(wrapper.find(".library-result-count").exists()).toBeFalsy();

    await resolve(GET_LIBRARY_GAMES, GAMES);
    expect(wrapper.findComponent(LibrarySkeleton).exists()).toBeFalsy();
    expect(wrapper.find(".library-result-count").text()).toBe("0 games");
  });
});
