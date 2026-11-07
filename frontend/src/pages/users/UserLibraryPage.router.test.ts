import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import { createMemoryHistory, createRouter, type Router } from "vue-router";
import UserLibraryPage from "./UserLibraryPage.vue";
import { GET_LIBRARY_GAMES, GET_LIBRARY_PAGE, GET_LIBRARY_SHELVES } from "@/graphql/queries/library";

// The page with a real router, since what's under test is the history entries
// its filters leave behind.

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

function respond(query: unknown) {
  if (query === GET_LIBRARY_PAGE) {
    return {
      user: {
        id: "1",
        hideDaysPlayed: false,
        libraryStatistics: {
          gamesCount: 30,
          statusCounts: [{ status: "COMPLETED", count: 30 }],
          platformCounts: [],
          storeCounts: []
        }
      }
    };
  }
  if (query === GET_LIBRARY_SHELVES) {
    return {
      user: {
        id: "1",
        inProgress: EMPTY_SHELF,
        paused: EMPTY_SHELF,
        // More games than the shelf shows, so it offers "Show all".
        completed: { totalCount: 30, nodes: [] },
        fullyCompleted: EMPTY_SHELF,
        unplayed: EMPTY_SHELF,
        dropped: EMPTY_SHELF,
        notApplicable: EMPTY_SHELF,
        noStatus: EMPTY_SHELF
      }
    };
  }
  if (query === GET_LIBRARY_GAMES) {
    return {
      user: {
        id: "1",
        gamePurchases: { totalCount: 0, pageInfo: { hasNextPage: false, endCursor: null }, nodes: [] }
      }
    };
  }
  throw new Error("Unexpected query");
}

async function mountLibrary(): Promise<{ router: Router; wrapper: ReturnType<typeof mount> }> {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/users/:slug", name: "user", component: { template: "<div />" } },
      { path: "/users/:slug/library", name: "userLibrary", component: UserLibraryPage },
      { path: "/games/:id", name: "game", component: { template: "<div />" } }
    ]
  });
  await router.push("/users/connorshea");
  await router.push("/users/connorshea/library");
  const wrapper = mount({ template: "<router-view />" }, { global: { plugins: [router] } });
  await flushPromises();
  return { router, wrapper };
}

async function goBack(router: Router) {
  const done = new Promise<void>((resolve) => {
    const remove = router.afterEach(() => {
      remove();
      resolve();
    });
  });
  router.back();
  await done;
  await flushPromises();
}

describe("UserLibraryPage history", () => {
  beforeEach(() => {
    mockRequest.mockReset();
    mockRequest.mockImplementation((query) => Promise.resolve(respond(query)));
  });

  it("returns to the whole library on Back after a shelf's Show all", async () => {
    const { router, wrapper } = await mountLibrary();

    await wrapper.find(".library-shelf-more").trigger("click");
    await flushPromises();
    expect(router.currentRoute.value.query.status).toBe("COMPLETED");

    await goBack(router);
    expect(router.currentRoute.value.name).toBe("userLibrary");
    expect(router.currentRoute.value.query.status).toBeUndefined();
    expect(wrapper.find(".library-shelf-more").exists()).toBeTruthy();

    // And Back again leaves the library rather than revisiting it.
    await goBack(router);
    expect(router.currentRoute.value.name).toBe("user");
  });

  it("doesn't add an entry when the active status is picked again", async () => {
    const { router, wrapper } = await mountLibrary();

    const completed = () => wrapper.findAll(".library-rail button").find((b) => b.text().includes("Completed"));
    await completed()?.trigger("click");
    await flushPromises();
    expect(router.currentRoute.value.query.status).toBe("COMPLETED");
    await completed()?.trigger("click");
    await flushPromises();

    await goBack(router);
    expect(router.currentRoute.value.name).toBe("userLibrary");
    expect(router.currentRoute.value.query.status).toBeUndefined();
  });
});
