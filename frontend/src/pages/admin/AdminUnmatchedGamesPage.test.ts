import { describe, it, expect, vi, beforeEach } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { ref } from "vue";
import AdminUnmatchedGamesPage from "./AdminUnmatchedGamesPage.vue";
import { ADD_TO_STEAM_BLOCKLIST } from "@/graphql/mutations/admin";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockRequest, mockShowSnackbar, mockRefetch } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>(),
  mockShowSnackbar: vi.fn<(text: string, type?: "success" | "error") => void>(),
  mockRefetch: vi.fn<() => Promise<void>>()
}));

vi.mock("@/composables/useGraphQL", () => ({
  useQuery: () => ({
    data: ref({
      groupedUnmatchedGames: {
        nodes: [{ externalServiceId: "12345", externalServiceName: "STEAM", name: "Half-Life OST", count: 3 }]
      }
    }),
    loading: ref(false),
    error: ref(null),
    refetch: mockRefetch
  })
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/composables/useSnackbar", () => ({
  useSnackbar: () => ({ show: mockShowSnackbar })
}));

// ── Helpers ───────────────────────────────────────────────────────

function mountPage() {
  return mount(AdminUnmatchedGamesPage, { global: { stubs: { teleport: true } } });
}

function blocklistButton(wrapper: ReturnType<typeof mountPage>) {
  return wrapper.findAll("button").find((b) => b.text() === "Add to blocklist");
}

beforeEach(() => {
  mockRequest.mockReset();
  mockShowSnackbar.mockReset();
  mockRefetch.mockReset();
});

// ── Tests ─────────────────────────────────────────────────────────

describe("AdminUnmatchedGamesPage blocklisting", () => {
  it("shows an Add to blocklist button on Steam rows", () => {
    expect(blocklistButton(mountPage())).toBeTruthy();
  });

  it("asks for confirmation, then adds the game to the Steam blocklist", async () => {
    mockRequest.mockResolvedValue({});
    const wrapper = mountPage();

    await blocklistButton(wrapper)?.trigger("click");
    expect(mockRequest).not.toHaveBeenCalled();
    const dialog = wrapper.find('[role="dialog"]');
    expect(dialog.text()).toContain("Half-Life OST");

    await dialog.find(".cd-btn-primary").trigger("click");
    await flushPromises();

    expect(mockRequest).toHaveBeenCalledWith(ADD_TO_STEAM_BLOCKLIST, { name: "Half-Life OST", steamAppId: 12345 });
    expect(mockShowSnackbar).toHaveBeenCalledWith("Added Half-Life OST to the Steam blocklist.");
    expect(mockRefetch).toHaveBeenCalled();
    expect(wrapper.find('[role="dialog"]').exists()).toBeFalsy();
  });

  it("shows the error and keeps the dialog open when the mutation fails", async () => {
    mockRequest.mockRejectedValue(new Error("Steam app has already been taken"));
    const wrapper = mountPage();

    await blocklistButton(wrapper)?.trigger("click");
    await wrapper.find('[role="dialog"] .cd-btn-primary').trigger("click");
    await flushPromises();

    expect(mockShowSnackbar).toHaveBeenCalledWith(expect.any(String), "error");
    expect(wrapper.find('[role="dialog"]').exists()).toBeTruthy();
  });
});
