import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mount, flushPromises, RouterLinkStub } from "@vue/test-utils";
import { nextTick, reactive } from "vue";
import type * as Vue from "vue";
import GameShowPage from "./GameShowPage.vue";
import { GET_GAME } from "@/graphql/queries/games";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockRequest, mockRoute } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>(),
  mockRoute: { params: { id: "1" } }
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

vi.mock("@/composables/useImageColors", async () => {
  const { ref } = await vi.importActual<typeof Vue>("vue");
  return { useImageColors: () => ({ gradient: ref(null) }) };
});

function gameFixture(id: string, name: string) {
  return {
    game: {
      id,
      name,
      releaseDate: null,
      avgRating: null,
      coverUrl: null,
      developers: { nodes: [] },
      publishers: { nodes: [] },
      platforms: { nodes: [] },
      genres: { nodes: [] },
      engines: { nodes: [] },
      series: null,
      ratingCount: 0,
      isFavorited: false,
      isInLibrary: false,
      gamePurchaseId: null,
      owners: { nodes: [], totalCount: 0 },
      favoriters: { nodes: [], totalCount: 0 },
      moreFromSeries: { nodes: [] }
    }
  };
}

// GET_GAME answers are held until the test resolves them, so the loading
// state can be inspected. Every other query answers straight away.
let pendingGames: Array<() => void> = [];

function mountPage() {
  return mount(GameShowPage, {
    global: {
      stubs: {
        RouterLink: RouterLinkStub,
        GameHeroPanel: true,
        GameReviewsCard: true,
        GameActivityCard: true,
        GameDetailsCard: true,
        GameSeriesShelf: true,
        GameLibraryForm: true,
        GameLibrarySheet: true,
        ConfirmDialog: true,
        MergeGameDialog: true
      }
    }
  });
}

// ── Tests ─────────────────────────────────────────────────────────

describe("GameShowPage loading skeleton", () => {
  beforeEach(() => {
    pendingGames = [];
    mockRoute.params.id = "1";
    mockRequest.mockReset();
    mockRequest.mockImplementation((query, variables) => {
      if (query === GET_GAME) {
        const id = String(variables?.id);
        return new Promise((resolve) => {
          pendingGames.push(() => resolve(gameFixture(id, `Game ${id}`)));
        });
      }
      return Promise.resolve({ stores: { nodes: [] }, game: null });
    });
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

  async function resolveGames() {
    pendingGames.splice(0).forEach((resolve) => resolve());
    await flushPromises();
  }

  it("shows the skeleton until the game loads", async () => {
    const wrapper = mountPage();
    await flushPromises();

    const skeleton = wrapper.find(".game-skeleton");
    expect(skeleton.exists()).toBeTruthy();
    expect(skeleton.attributes("aria-busy")).toBe("true");
    expect(wrapper.find("[role='status']").text()).toBe("Loading game…");
    expect(wrapper.find(".game-title").exists()).toBeFalsy();

    await resolveGames();

    expect(wrapper.find(".game-skeleton").exists()).toBeFalsy();
    expect(wrapper.find(".game-title").text()).toBe("Game 1");
  });

  it("shows the skeleton again instead of the previous game when moving to another game", async () => {
    const wrapper = mountPage();
    await resolveGames();
    expect(wrapper.find(".game-title").text()).toBe("Game 1");

    reactive(mockRoute).params.id = "2";
    await nextTick();
    await flushPromises();

    expect(wrapper.find(".game-skeleton").exists()).toBeTruthy();
    expect(wrapper.find(".game-title").exists()).toBeFalsy();

    await resolveGames();

    expect(wrapper.find(".game-skeleton").exists()).toBeFalsy();
    expect(wrapper.find(".game-title").text()).toBe("Game 2");
  });
});
