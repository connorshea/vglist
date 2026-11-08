import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mount, flushPromises, RouterLinkStub } from "@vue/test-utils";
import type * as Vue from "vue";
import GameFormPage from "./GameFormPage.vue";
import { GET_GAME } from "@/graphql/queries/games";
import { SEARCH_COMPANIES_FOR_GAME_FORM, SEARCH_ENGINES_FOR_GAME_FORM } from "@/graphql/queries/game-form";
import { CREATE_GAME, UPDATE_GAME } from "@/graphql/mutations/games";
import { SEARCH_DEBOUNCE_MS } from "@/composables/useDebouncedSearch";

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
    attachTo: document.body,
    global: { stubs: { RouterLink: RouterLinkStub, WikidataIdInput: true } }
  });
}

type Wrapper = ReturnType<typeof mountPage>;

function field(wrapper: Wrapper, label: string) {
  const found = wrapper.findAll(".searchable-select").find((f) => f.find("label").text() === label);
  if (!found) throw new Error(`No ${label} field`);
  return found;
}

const tagsFor = (wrapper: Wrapper, label: string) =>
  field(wrapper, label)
    .findAll(".ss-tag")
    .map((tag) => tag.text());

const optionsFor = (wrapper: Wrapper, label: string) =>
  field(wrapper, label)
    .findAll("[role='option']")
    .map((option) => option.text());

async function typeInto(wrapper: Wrapper, label: string, text: string) {
  const input = field(wrapper, label).find("input");
  await input.trigger("focus");
  await input.setValue(text);
  await vi.advanceTimersByTimeAsync(SEARCH_DEBOUNCE_MS);
  await flushPromises();
}

function requestsFor(query: unknown) {
  return mockRequest.mock.calls.filter(([q]) => q === query);
}

describe("GameFormPage", () => {
  let wrapper: Wrapper | undefined;

  beforeEach(() => {
    vi.useFakeTimers();
    mockRoute.params.id = "1";
    mockRequest.mockReset();
    mockRequest.mockImplementation((query, variables) => {
      if (query === GET_GAME) return Promise.resolve(gameFixture());
      // Like the real search, only records matching the query come back,
      // however far down an alphabetical list they'd be.
      if (query === SEARCH_ENGINES_FOR_GAME_FORM) {
        const engines = [
          { id: "901", name: "GoldSrc" },
          { id: "902", name: "Source" },
          { id: "903", name: "Source 2" }
        ];
        const q = String(variables?.query).toLowerCase();
        return Promise.resolve({ engineSearch: { nodes: engines.filter((e) => e.name.toLowerCase().includes(q)) } });
      }
      if (query === SEARCH_COMPANIES_FOR_GAME_FORM) {
        return Promise.resolve({ companySearch: { nodes: [{ id: "603", name: "Gearbox Software" }] } });
      }
      if (query === UPDATE_GAME) return Promise.resolve({ updateGame: { game: { id: "1", name: "Half-Life" } } });
      if (query === CREATE_GAME) return Promise.resolve({ createGame: { game: { id: "2", name: "New" } } });
      return Promise.reject(new Error("Unexpected query"));
    });
  });

  afterEach(() => {
    wrapper?.unmount();
    wrapper = undefined;
    vi.useRealTimers();
  });

  it("pre-fills the game's selections without loading any option lists", async () => {
    wrapper = mountPage();
    await flushPromises();

    expect(tagsFor(wrapper, "Engines")).toEqual(["GoldSrc"]);
    expect(tagsFor(wrapper, "Platforms")).toEqual(["Windows"]);
    expect(tagsFor(wrapper, "Developers")).toEqual(["Valve"]);
    expect(tagsFor(wrapper, "Publishers")).toEqual(["Sierra"]);
    expect(tagsFor(wrapper, "Genres")).toEqual(["First-person shooter"]);
    expect(wrapper.find(".ss-selected-text").text()).toBe("Half-Life series");
    expect(mockRequest).toHaveBeenCalledTimes(1);
  });

  it("asks you to type before searching", async () => {
    wrapper = mountPage();
    await flushPromises();

    await field(wrapper, "Engines").find("input").trigger("focus");
    expect(field(wrapper, "Engines").find(".ss-no-results").text()).toBe("Type to search");
  });

  it("searches the server once typing pauses and adds the picked result", async () => {
    wrapper = mountPage();
    await flushPromises();

    const input = field(wrapper, "Engines").find("input");
    await input.trigger("focus");
    await input.setValue("So");
    await vi.advanceTimersByTimeAsync(SEARCH_DEBOUNCE_MS / 2);
    await input.setValue("Sou");
    expect(field(wrapper, "Engines").find(".ss-no-results").text()).toBe("Searching…");
    await vi.advanceTimersByTimeAsync(SEARCH_DEBOUNCE_MS);
    await flushPromises();

    expect(requestsFor(SEARCH_ENGINES_FOR_GAME_FORM)).toEqual([[SEARCH_ENGINES_FOR_GAME_FORM, { query: "Sou" }]]);
    expect(optionsFor(wrapper, "Engines")).toEqual(["Source", "Source 2"]);

    await field(wrapper, "Engines").findAll("[role='option']")[1].trigger("mousedown");
    expect(tagsFor(wrapper, "Engines")).toEqual(["GoldSrc", "Source 2"]);

    await wrapper.find("form").trigger("submit");
    await flushPromises();
    const [update] = requestsFor(UPDATE_GAME);
    expect(update[1]).toMatchObject({ gameId: "1", engineIds: ["901", "903"], seriesId: "501" });
  });

  it("picks the highlighted result with the keyboard", async () => {
    wrapper = mountPage();
    await flushPromises();

    await typeInto(wrapper, "Publishers", "gear");
    const input = field(wrapper, "Publishers").find("input");
    expect(input.attributes("aria-activedescendant")).toBeTruthy();
    await input.trigger("keydown", { key: "Enter" });

    expect(tagsFor(wrapper, "Publishers")).toEqual(["Sierra", "Gearbox Software"]);
  });

  it("sends cleared selections as empty", async () => {
    wrapper = mountPage();
    await flushPromises();

    await field(wrapper, "Engines").find(".ss-tag-remove").trigger("click");
    await wrapper.find("[aria-label='Clear Half-Life series']").trigger("click");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    const [update] = requestsFor(UPDATE_GAME);
    expect(update[1]).toMatchObject({ engineIds: [], seriesId: null, platformIds: ["701"] });
  });

  it("starts empty when creating a game", async () => {
    mockRoute.params.id = undefined;
    wrapper = mountPage();
    await flushPromises();

    expect(tagsFor(wrapper, "Engines")).toEqual([]);
    expect(mockRequest).not.toHaveBeenCalled();
  });
});
