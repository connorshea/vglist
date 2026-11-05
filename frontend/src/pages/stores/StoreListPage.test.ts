import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises, RouterLinkStub } from "@vue/test-utils";
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
      pageInfo: { hasNextPage, endCursor }
    }
  };
}

function mountPage() {
  return mount(StoreListPage, {
    global: {
      stubs: { RouterLink: RouterLinkStub, ConfirmDialog: true }
    }
  });
}

function storeNames(wrapper: ReturnType<typeof mountPage>) {
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

    const wrapper = mountPage();
    await flushPromises();

    await wrapper.find('[aria-label="Next page"]').trigger("click");
    await flushPromises();
    expect(storeNames(wrapper)).toEqual(["itch.io"]);

    await wrapper.find('[aria-label="Delete itch.io"]').trigger("click");
    wrapper.findComponent({ name: "ConfirmDialog" }).vm.$emit("confirm");
    await flushPromises();

    expect(storeNames(wrapper)).toEqual(["Steam", "GOG"]);
    expect(mockRequest.mock.calls.at(-1)?.[1]).toEqual({ first: 25, after: null });
  });
});
