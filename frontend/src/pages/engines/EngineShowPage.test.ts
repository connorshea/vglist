import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises, RouterLinkStub } from "@vue/test-utils";
import { nextTick, reactive } from "vue";
import type * as Vue from "vue";
import EngineShowPage from "./EngineShowPage.vue";
import ResourceShowSkeleton from "@/components/resource/ResourceShowSkeleton.vue";

const { mockRequest, mockRoute } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>(),
  mockRoute: { params: { id: "1" }, query: {} }
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/stores/auth", () => ({
  useAuthStore: () => ({ isAuthenticated: false, isModerator: false, isAdmin: false })
}));

vi.mock("vue-router", async () => {
  const { reactive: makeReactive } = await vi.importActual<typeof Vue>("vue");
  const route = makeReactive(mockRoute);
  return {
    useRoute: () => route,
    useRouter: () => ({ push: vi.fn<() => Promise<void>>(), replace: vi.fn<() => Promise<void>>() })
  };
});

function engineFixture() {
  return {
    engine: {
      id: "1",
      name: "Source",
      wikidataId: null,
      games: {
        totalCount: 1,
        nodes: [{ id: "10", name: "Half-Life 2", coverUrl: null, releaseDate: "2004-11-16", isInLibrary: false }],
        pageInfo: { hasNextPage: false, endCursor: null }
      }
    }
  };
}

describe("EngineShowPage loading skeleton", () => {
  let pending: (() => void)[] = [];

  beforeEach(() => {
    pending = [];
    mockRoute.query = {};
    mockRequest.mockReset();
    mockRequest.mockImplementation(
      () =>
        new Promise((resolve) => {
          pending.push(() => resolve(engineFixture()));
        })
    );
  });

  async function resolveAll() {
    for (const resolve of pending.splice(0)) {
      resolve();
    }
    await flushPromises();
  }

  function mountPage() {
    return mount(EngineShowPage, { global: { stubs: { RouterLink: RouterLinkStub, ConfirmDialog: true } } });
  }

  it("shows the skeleton until the engine loads", async () => {
    const wrapper = mountPage();
    await flushPromises();

    expect(wrapper.findComponent(ResourceShowSkeleton).exists()).toBeTruthy();
    expect(wrapper.find("[role='status']").text()).toBe("Loading engine…");
    expect(wrapper.find("h1").exists()).toBeFalsy();

    await resolveAll();

    expect(wrapper.findComponent(ResourceShowSkeleton).exists()).toBeFalsy();
    expect(wrapper.find("h1").text()).toBe("Source");
    expect(wrapper.find("[role='status']").text()).toBe("");
  });

  it("keeps the page up while a new sort loads", async () => {
    const wrapper = mountPage();
    await resolveAll();

    reactive(mockRoute).query = { sort: "name" };
    await nextTick();
    await flushPromises();

    expect(pending.length).toBeGreaterThan(0);
    expect(wrapper.findComponent(ResourceShowSkeleton).exists()).toBeFalsy();
    expect(wrapper.find("h1").text()).toBe("Source");
  });
});
