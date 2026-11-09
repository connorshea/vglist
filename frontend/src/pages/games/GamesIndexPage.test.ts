import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mount, flushPromises, RouterLinkStub } from "@vue/test-utils";
import GamesIndexPage from "./GamesIndexPage.vue";
import GameTileSkeleton from "@/components/games-index/GameTileSkeleton.vue";
import { GET_GAMES_INDEX } from "@/graphql/queries/games-index";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockRequest, authState } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>(),
  authState: { isModerator: false, isAuthenticated: false }
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/stores/auth", () => ({
  useAuthStore: () => authState
}));

vi.mock("vue-router", () => ({
  useRoute: () => ({ query: {} }),
  useRouter: () => ({ push: vi.fn<() => Promise<void>>(), replace: vi.fn<() => Promise<void>>() })
}));

class IntersectionObserverStub {
  observe() {}
  unobserve() {}
  disconnect() {}
}

function mountPage() {
  return mount(GamesIndexPage, {
    global: {
      stubs: { RouterLink: RouterLinkStub, GamesFilterPanel: true, GameTile: true }
    }
  });
}

// ── Tests ─────────────────────────────────────────────────────────

describe("GamesIndexPage", () => {
  beforeEach(() => {
    mockRequest.mockReset();
    mockRequest.mockResolvedValue({
      games: { nodes: [], totalCount: 0, pageInfo: { hasNextPage: false, endCursor: null } },
      platforms: { nodes: [] },
      genres: { nodes: [] }
    });
    vi.stubGlobal("IntersectionObserver", IntersectionObserverStub);
    vi.stubGlobal(
      "matchMedia",
      vi.fn<(query: string) => Partial<MediaQueryList>>(() => ({
        matches: false,
        addEventListener: () => {},
        removeEventListener: () => {}
      }))
    );
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("links moderators to the new game form", async () => {
    authState.isModerator = true;
    const wrapper = mountPage();
    await flushPromises();

    const link = wrapper.findAllComponents(RouterLinkStub).find((l) => l.classes("new-btn"));
    expect(link).toBeDefined();
    expect(link?.text()).toBe("New game");
    expect(link?.props("to")).toEqual({ name: "gameNew" });
  });

  it("hides the new game button from everyone else", async () => {
    authState.isModerator = false;
    const wrapper = mountPage();
    await flushPromises();

    expect(wrapper.find(".new-btn").exists()).toBeFalsy();
  });

  it("shows placeholder tiles until the first page of games loads", async () => {
    let resolveGames: (value: unknown) => void = () => {};
    mockRequest.mockImplementation((query) =>
      query === GET_GAMES_INDEX
        ? new Promise((resolve) => {
            resolveGames = resolve;
          })
        : Promise.resolve({ basicSiteStatistics: { games: 1 } })
    );
    const wrapper = mountPage();
    await flushPromises();

    expect(wrapper.findAllComponents(GameTileSkeleton)).toHaveLength(18);
    expect(wrapper.find("[role=status]").text()).toBe("Loading games…");

    resolveGames({
      games: {
        nodes: [{ id: "1", name: "Portal" }],
        totalCount: 1,
        pageInfo: { hasNextPage: false, endCursor: null }
      }
    });
    await flushPromises();

    expect(wrapper.findAllComponents(GameTileSkeleton)).toHaveLength(0);
    expect(wrapper.find("[role=status]").text()).toBe("");
    expect(wrapper.findAll(".games-grid li")).toHaveLength(1);
    wrapper.unmount();
  });
});
