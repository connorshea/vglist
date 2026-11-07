import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import { createMemoryHistory, createRouter } from "vue-router";
import StoreListPage from "./StoreListPage.vue";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockRequest } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>()
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/stores/auth", () => ({
  useAuthStore: () => ({ isModerator: true })
}));

vi.mock("@/composables/useSnackbar", () => ({
  useSnackbar: () => ({ show: vi.fn<(message: string, type?: string) => void>() })
}));

function storesPage(names: string[], endCursor: string | null, hasNextPage: boolean) {
  return {
    stores: {
      nodes: names.map((name) => ({ id: name, name })),
      pageInfo: { hasNextPage, startCursor: names.length ? `start-${names[0]}` : null, endCursor }
    }
  };
}

async function mountPage() {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/stores", name: "stores", component: StoreListPage },
      { path: "/stores/new", name: "storeNew", component: { template: "<div />" } },
      { path: "/stores/:id/edit", name: "storeEdit", component: { template: "<div />" } }
    ]
  });
  await router.push("/stores");
  const wrapper = mount(
    { template: "<router-view />" },
    { global: { plugins: [router], stubs: { ConfirmDialog: true } } }
  );
  await flushPromises();
  return { router, wrapper };
}

function storeNames(wrapper: Awaited<ReturnType<typeof mountPage>>["wrapper"]) {
  return wrapper.findAll(".store-name").map((s) => s.text());
}

// ── Tests ─────────────────────────────────────────────────────────

describe("StoreListPage", () => {
  beforeEach(() => {
    mockRequest.mockReset();
  });

  it("steps back a page when the current page comes back empty", async () => {
    mockRequest
      .mockResolvedValueOnce(storesPage(["Steam", "GOG"], "cursor-1", true))
      .mockResolvedValueOnce(storesPage(["itch.io"], "cursor-2", false))
      // Deleting itch.io leaves page 2 empty when it's refetched.
      .mockResolvedValueOnce({ deleteStore: { deleted: true } })
      .mockResolvedValueOnce(storesPage([], null, false))
      .mockResolvedValueOnce(storesPage(["Steam", "GOG"], "cursor-1", false));

    const { router, wrapper } = await mountPage();

    await wrapper.find('[aria-label="Next page"]').trigger("click");
    await flushPromises();
    expect(storeNames(wrapper)).toEqual(["itch.io"]);
    expect(router.currentRoute.value.query).toEqual({ page: "2", after: "cursor-1" });

    await wrapper.find('[aria-label="Delete itch.io"]').trigger("click");
    wrapper.findComponent({ name: "ConfirmDialog" }).vm.$emit("confirm");
    await flushPromises();

    expect(storeNames(wrapper)).toEqual(["Steam", "GOG"]);
    expect(mockRequest.mock.calls.at(-1)?.[1]).toEqual({ first: 25, after: null, last: null, before: null });
    expect(router.currentRoute.value.query).toEqual({});
  });
});

describe("StoreListPage history", () => {
  beforeEach(() => {
    mockRequest.mockReset();
  });

  it("makes each page a history entry and pages back with the start cursor", async () => {
    mockRequest.mockImplementation((_query, variables) => {
      if (variables?.after === "cursor-1") return Promise.resolve(storesPage(["Humble"], "cursor-2", true));
      if (variables?.after === "cursor-2") return Promise.resolve(storesPage(["itch.io"], "cursor-3", false));
      if (variables?.before === "start-itch.io") return Promise.resolve(storesPage(["Humble"], "cursor-2", true));
      return Promise.resolve(storesPage(["Steam", "GOG"], "cursor-1", true));
    });

    const { router, wrapper } = await mountPage();
    const next = () => wrapper.find('[aria-label="Next page"]').trigger("click");

    await next();
    await flushPromises();
    await next();
    await flushPromises();
    expect(storeNames(wrapper)).toEqual(["itch.io"]);

    // Previous from page 3 fetches the page before this one's first store.
    await wrapper.find('[aria-label="Previous page"]').trigger("click");
    await flushPromises();
    expect(router.currentRoute.value.query).toEqual({ page: "2", before: "start-itch.io" });
    expect(mockRequest.mock.calls.at(-1)?.[1]).toEqual({ first: null, after: null, last: 25, before: "start-itch.io" });
    expect(storeNames(wrapper)).toEqual(["Humble"]);

    // Back retraces the pages that were visited.
    router.back();
    await flushPromises();
    await new Promise((resolve) => setTimeout(resolve));
    await flushPromises();
    expect(router.currentRoute.value.query).toEqual({ page: "3", after: "cursor-2" });
    expect(storeNames(wrapper)).toEqual(["itch.io"]);
  });
});
