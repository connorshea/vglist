import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises, RouterLinkStub } from "@vue/test-utils";
import type * as Vue from "vue";
import GameFormPage from "./GameFormPage.vue";
import { GET_GAME } from "@/graphql/queries/games";
import { GET_COMPANIES, GET_ENGINES, GET_GENRES, GET_PLATFORMS, GET_SERIES_LIST } from "@/graphql/queries/resources";

const { mockRequest, mockRoute } = vi.hoisted(() => {
  const params: { id?: string } = { id: "1" };
  return {
    mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>(),
    mockRoute: { params, query: {} }
  };
});

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/stores/auth", () => ({
  useAuthStore: () => ({ isAuthenticated: true, isModerator: true, isAdmin: false })
}));

vi.mock("vue-router", async () => {
  const { reactive: makeReactive } = await vi.importActual<typeof Vue>("vue");
  const route = makeReactive(mockRoute);
  return {
    useRoute: () => route,
    useRouter: () => ({ push: vi.fn<() => Promise<void>>(), replace: vi.fn<() => Promise<void>>() })
  };
});

// Each resource list holds only the first page, which (like the API's
// 100-record cap) doesn't include anything the game uses.
const firstPage = (prefix: string) => ({ nodes: [{ id: `${prefix}-1`, name: `${prefix} on page one` }] });

function gameFixture() {
  return {
    game: {
      id: "1",
      name: "Half-Life",
      releaseDate: null,
      wikidataId: null,
      steamAppIds: [],
      pcgamingwikiId: null,
      mobygamesId: null,
      giantbombId: null,
      epicGamesStoreId: null,
      gogId: null,
      igdbId: null,
      series: { id: "501", name: "Half-Life series" },
      developers: { nodes: [{ id: "601", name: "Valve" }] },
      publishers: { nodes: [{ id: "602", name: "Sierra" }] },
      platforms: { nodes: [{ id: "701", name: "Windows" }] },
      genres: { nodes: [{ id: "801", name: "First-person shooter" }] },
      engines: { nodes: [{ id: "901", name: "GoldSrc" }] }
    }
  };
}

function mountPage() {
  return mount(GameFormPage, {
    global: { stubs: { RouterLink: RouterLinkStub, WikidataIdInput: true } }
  });
}

function tagsFor(wrapper: ReturnType<typeof mountPage>, label: string): string[] {
  const field = wrapper.findAll(".searchable-select").find((f) => f.find("label").text() === label);
  if (!field) throw new Error(`No ${label} field`);
  return field.findAll(".ss-tag").map((tag) => tag.text());
}

describe("GameFormPage", () => {
  beforeEach(() => {
    mockRoute.params.id = "1";
    mockRequest.mockReset();
    mockRequest.mockImplementation((query) => {
      if (query === GET_GAME) return Promise.resolve(gameFixture());
      if (query === GET_PLATFORMS) return Promise.resolve({ platforms: firstPage("platform") });
      if (query === GET_COMPANIES) return Promise.resolve({ companies: firstPage("company") });
      if (query === GET_GENRES) return Promise.resolve({ genres: firstPage("genre") });
      if (query === GET_ENGINES) return Promise.resolve({ engines: firstPage("engine") });
      if (query === GET_SERIES_LIST) return Promise.resolve({ seriesList: firstPage("series") });
      return Promise.reject(new Error("Unexpected query"));
    });
  });

  it("shows the game's selections even when they aren't in the loaded options", async () => {
    const wrapper = mountPage();
    await flushPromises();

    expect(tagsFor(wrapper, "Engines")).toEqual(["GoldSrc"]);
    expect(tagsFor(wrapper, "Platforms")).toEqual(["Windows"]);
    expect(tagsFor(wrapper, "Developers")).toEqual(["Valve"]);
    expect(tagsFor(wrapper, "Publishers")).toEqual(["Sierra"]);
    expect(tagsFor(wrapper, "Genres")).toEqual(["First-person shooter"]);
    expect(wrapper.find(".ss-selected-text").text()).toBe("Half-Life series");
  });

  it("keeps a removed selection available to pick again", async () => {
    const wrapper = mountPage();
    await flushPromises();

    const engines = wrapper.findAll(".searchable-select").find((f) => f.find("label").text() === "Engines");
    if (!engines) throw new Error("No Engines field");
    await engines.find(".ss-tag-remove").trigger("click");
    expect(tagsFor(wrapper, "Engines")).toEqual([]);

    await engines.find("input").trigger("focus");
    const options = engines.findAll("[role='option']").map((o) => o.text());
    expect(options).toContain("GoldSrc");
  });

  it("doesn't add anything extra when creating a game", async () => {
    mockRoute.params.id = undefined;
    const wrapper = mountPage();
    await flushPromises();

    const engines = wrapper.findAll(".searchable-select").find((f) => f.find("label").text() === "Engines");
    if (!engines) throw new Error("No Engines field");
    await engines.find("input").trigger("focus");
    expect(engines.findAll("[role='option']").map((o) => o.text())).toEqual(["engine on page one"]);
  });
});
