import { describe, it, expect, vi, beforeEach } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import AdminUnmatchedGamesPage from "./AdminUnmatchedGamesPage.vue";
import { ADD_TO_STEAM_BLOCKLIST } from "@/graphql/mutations/admin";
import { GET_UNMATCHED_GAMES } from "@/graphql/queries/admin";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockRequest, mockShowSnackbar } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>(),
  mockShowSnackbar: vi.fn<(text: string, type?: "success" | "error") => void>()
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/composables/useSnackbar", () => ({
  useSnackbar: () => ({ show: mockShowSnackbar })
}));

const HALF_LIFE_OST = { externalServiceId: "12345", externalServiceName: "STEAM", name: "Half-Life OST", count: 3 };

function unmatchedPage(nodes: (typeof HALF_LIFE_OST)[], hasNextPage = false, endCursor: string | null = null) {
  return { groupedUnmatchedGames: { nodes, pageInfo: { hasNextPage, endCursor } } };
}

// Answers the list query with one Steam row, and every mutation with `{}`.
function serveOneRow(query: unknown) {
  return Promise.resolve(query === GET_UNMATCHED_GAMES ? unmatchedPage([HALF_LIFE_OST]) : {});
}

// ── Helpers ───────────────────────────────────────────────────────

async function mountPage() {
  const wrapper = mount(AdminUnmatchedGamesPage, { global: { stubs: { teleport: true } } });
  await flushPromises();
  return wrapper;
}

function blocklistButton(wrapper: Awaited<ReturnType<typeof mountPage>>) {
  return wrapper.findAll("button").find((b) => b.text() === "Add to blocklist");
}

beforeEach(() => {
  mockRequest.mockReset();
  mockRequest.mockImplementation(serveOneRow);
  mockShowSnackbar.mockReset();
});

// ── Tests ─────────────────────────────────────────────────────────

describe("AdminUnmatchedGamesPage blocklisting", () => {
  it("shows an Add to blocklist button on Steam rows", async () => {
    expect(blocklistButton(await mountPage())).toBeTruthy();
  });

  it("asks for confirmation, then adds the game to the Steam blocklist", async () => {
    const wrapper = await mountPage();
    mockRequest.mockClear();

    await blocklistButton(wrapper)?.trigger("click");
    expect(mockRequest).not.toHaveBeenCalled();
    const dialog = wrapper.find('[role="dialog"]');
    expect(dialog.text()).toContain("Half-Life OST");

    await dialog.find(".cd-btn-primary").trigger("click");
    await flushPromises();

    expect(mockRequest).toHaveBeenCalledWith(ADD_TO_STEAM_BLOCKLIST, { name: "Half-Life OST", steamAppId: 12345 });
    expect(mockShowSnackbar).toHaveBeenCalledWith("Added Half-Life OST to the Steam blocklist.");
    // The list reloads after the mutation.
    expect(mockRequest).toHaveBeenLastCalledWith(GET_UNMATCHED_GAMES, { first: 50, after: null });
    expect(wrapper.find('[role="dialog"]').exists()).toBeFalsy();
  });

  it("shows the error and keeps the dialog open when the mutation fails", async () => {
    const wrapper = await mountPage();
    mockRequest.mockRejectedValue(new Error("Steam app has already been taken"));

    await blocklistButton(wrapper)?.trigger("click");
    await wrapper.find('[role="dialog"] .cd-btn-primary').trigger("click");
    await flushPromises();

    expect(mockShowSnackbar).toHaveBeenCalledWith(expect.any(String), "error");
    expect(wrapper.find('[role="dialog"]').exists()).toBeTruthy();
  });
});

describe("AdminUnmatchedGamesPage pagination", () => {
  const OTHER_GAME = { externalServiceId: "678", externalServiceName: "STEAM", name: "Portal Demo", count: 1 };

  function loadMoreButton(wrapper: Awaited<ReturnType<typeof mountPage>>) {
    return wrapper.findAll("button").find((b) => b.text() === "Load more games");
  }

  it("appends the next page when Load more is clicked", async () => {
    // 51 rows, served by offset like the real API.
    const rows = [
      ...Array.from({ length: 50 }, (_, i) => ({ ...HALF_LIFE_OST, externalServiceId: String(1000 + i) })),
      OTHER_GAME
    ];
    mockRequest.mockImplementation((_query, variables) => {
      const offset = variables?.after ? Number(variables.after) : 0;
      const end = offset + Number(variables?.first);
      return Promise.resolve(
        unmatchedPage(rows.slice(offset, end), end < rows.length, String(Math.min(end, rows.length)))
      );
    });
    const wrapper = await mountPage();
    expect(wrapper.findAll("tbody tr")).toHaveLength(50);

    await loadMoreButton(wrapper)?.trigger("click");
    await flushPromises();

    expect(mockRequest).toHaveBeenLastCalledWith(GET_UNMATCHED_GAMES, { first: 50, after: "50" });
    const rowsShown = wrapper.findAll("tbody tr");
    expect(rowsShown).toHaveLength(51);
    expect(rowsShown[50]?.text()).toContain("Portal Demo");
    expect(loadMoreButton(wrapper)).toBeUndefined();
  });

  it("hides Load more when everything fits on one page", async () => {
    expect(loadMoreButton(await mountPage())).toBeUndefined();
  });
});
