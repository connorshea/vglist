import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import { createMemoryHistory, createRouter, type Router } from "vue-router";
import ActivityPage from "./ActivityPage.vue";

// The page with a real router, since what's under test is the history entries
// its tabs and pages leave behind.

const { mockRequest } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>()
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/stores/auth", () => ({
  useAuthStore: () => ({ isAuthenticated: true, isModerator: false, user: { id: "1", slug: "connorshea" } })
}));

function activityPage(endCursor: string) {
  return {
    activity: { nodes: [], pageInfo: { hasNextPage: true, startCursor: "start", endCursor } }
  };
}

async function mountActivity(): Promise<{ router: Router; wrapper: ReturnType<typeof mount> }> {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
      { path: "/activity", name: "activity", component: ActivityPage }
    ]
  });
  await router.push("/");
  await router.push("/activity");
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

describe("ActivityPage history", () => {
  beforeEach(() => {
    mockRequest.mockReset();
    mockRequest.mockImplementation((_query, variables) =>
      Promise.resolve(activityPage(`${String(variables?.feedType)}-end`))
    );
  });

  it("returns to the Following feed on Back after switching to Global", async () => {
    const { router, wrapper } = await mountActivity();
    expect(mockRequest.mock.calls.at(-1)?.[1]).toMatchObject({ feedType: "FOLLOWING" });

    const global = wrapper.findAll(".activity-tab").find((tab) => tab.text() === "Global");
    await global?.trigger("click");
    await flushPromises();
    expect(router.currentRoute.value.query).toEqual({ feed: "global" });
    expect(mockRequest.mock.calls.at(-1)?.[1]).toMatchObject({ feedType: "GLOBAL" });

    await goBack(router);
    expect(router.currentRoute.value.name).toBe("activity");
    expect(router.currentRoute.value.query).toEqual({});
    expect(mockRequest.mock.calls.at(-1)?.[1]).toMatchObject({ feedType: "FOLLOWING" });
  });

  it("returns to the first page on Back after Next", async () => {
    const { router, wrapper } = await mountActivity();

    await wrapper.find('[aria-label="Next page"]').trigger("click");
    await flushPromises();
    expect(router.currentRoute.value.query).toEqual({ page: "2", after: "FOLLOWING-end" });
    expect(mockRequest.mock.calls.at(-1)?.[1]).toMatchObject({ first: 25, after: "FOLLOWING-end" });

    await goBack(router);
    expect(router.currentRoute.value.query).toEqual({});
    expect(mockRequest.mock.calls.at(-1)?.[1]).toMatchObject({ first: 25, after: null });

    await goBack(router);
    expect(router.currentRoute.value.name).toBe("home");
  });
});
