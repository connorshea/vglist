import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises, RouterLinkStub } from "@vue/test-utils";
import SteamImportResults from "./SteamImportResults.vue";

const { mockRequest, mockAuth } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>(),
  mockAuth: { isAdmin: false, isModerator: false }
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/stores/auth", () => ({
  useAuthStore: () => mockAuth
}));

function game(id: number) {
  return { id: String(id), name: `Game ${String(id).padStart(2, "0")}`, coverUrl: null };
}

interface ResultProps {
  addedGamesCount: number;
  updatedGamesCount: number;
  unmatchedCount: number;
  addedGames: ReturnType<typeof game>[];
  updatedGames: ReturnType<typeof game>[];
  unmatchedGames: { name: string; steamAppId: number }[];
}

function result(overrides: Partial<ResultProps> = {}): ResultProps {
  return {
    addedGamesCount: 0,
    updatedGamesCount: 0,
    unmatchedCount: 0,
    addedGames: [],
    updatedGames: [],
    unmatchedGames: [],
    ...overrides
  };
}

function mountResults(props: ResultProps) {
  return mount(SteamImportResults, {
    props: { result: props },
    attachTo: document.body,
    global: { stubs: { RouterLink: RouterLinkStub } }
  });
}

const unmatched = [
  { name: "Half-Life 2: Lost Coast", steamAppId: 340 },
  { name: "Portal Soundtrack", steamAppId: 323170 }
];

describe("SteamImportResults", () => {
  beforeEach(() => {
    mockAuth.isAdmin = false;
    mockAuth.isModerator = false;
    mockRequest.mockReset();
    document.body.innerHTML = "";
  });

  it("lists the added games, linking to each", () => {
    const wrapper = mountResults(result({ addedGames: [game(1), game(2)] }));
    const links = wrapper.findAllComponents(RouterLinkStub);

    expect(links.map((link) => link.find(".import-game-name").text())).toEqual(["Game 01", "Game 02"]);
    expect(links[0].props("to")).toEqual({ name: "game", params: { id: "1" } });
  });

  it("collapses long lists behind a Show all button", async () => {
    const games = Array.from({ length: 15 }, (_, i) => game(i + 1));
    const wrapper = mountResults(result({ addedGames: games }));

    expect(wrapper.findAll(".import-game")).toHaveLength(12);
    const toggle = wrapper.get("button.show-all");
    expect(toggle.text()).toBe("Show all 15");
    expect(toggle.attributes("aria-expanded")).toBe("false");

    await toggle.trigger("click");
    expect(wrapper.findAll(".import-game")).toHaveLength(15);
    expect(toggle.attributes("aria-expanded")).toBe("true");
  });

  it("shows unmatched games without actions to regular members", () => {
    const wrapper = mountResults(result({ unmatchedGames: unmatched }));

    expect(wrapper.findAll(".import-unmatched-row")).toHaveLength(2);
    expect(wrapper.get(".import-steam-link").attributes("href")).toBe("https://store.steampowered.com/app/340");
    expect(wrapper.findAllComponents(RouterLinkStub)).toHaveLength(0);
    expect(wrapper.text()).not.toContain("Blocklist");
  });

  it("gives moderators a prefilled Create link but no blocklist action", () => {
    mockAuth.isModerator = true;
    const wrapper = mountResults(result({ unmatchedGames: unmatched }));
    const create = wrapper.findAllComponents(RouterLinkStub)[0];

    expect(create.props("to")).toEqual({
      name: "gameNew",
      query: { name: "Half-Life 2: Lost Coast", steamAppId: "340" }
    });
    expect(wrapper.text()).not.toContain("Blocklist");
  });

  it("lets admins blocklist an unmatched game after confirming, then hides it", async () => {
    mockAuth.isModerator = true;
    mockAuth.isAdmin = true;
    mockRequest.mockResolvedValue({
      addToSteamBlocklist: { steamBlocklistEntry: { id: "1", name: "Portal Soundtrack", steamAppId: 323170 } }
    });
    const wrapper = mountResults(result({ unmatchedGames: unmatched }));

    await wrapper.get('button[aria-label="Add Portal Soundtrack to the Steam blocklist"]').trigger("click");
    const confirm = Array.from(document.body.querySelectorAll<HTMLButtonElement>(".cd-btn")).find(
      (button) => button.textContent?.trim() === "Add to blocklist"
    );
    if (!confirm) throw new Error("no confirm button");
    confirm.click();
    await flushPromises();

    expect(mockRequest).toHaveBeenCalledWith(expect.anything(), { name: "Portal Soundtrack", steamAppId: 323170 });
    expect(wrapper.findAll(".import-unmatched-row").map((row) => row.find(".import-game-name").text())).toEqual([
      "Half-Life 2: Lost Coast"
    ]);
  });

  it("says so when nothing changed", () => {
    const wrapper = mountResults(result());

    expect(wrapper.text()).toContain("already in your library");
  });
});
