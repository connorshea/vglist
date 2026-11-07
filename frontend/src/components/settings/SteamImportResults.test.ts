import { describe, it, expect, beforeEach } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import SteamImportResults from "./SteamImportResults.vue";

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

  it("lists unmatched games with a link to their Steam store page", () => {
    const wrapper = mountResults(result({ unmatchedGames: unmatched }));

    expect(wrapper.findAll(".import-unmatched-row")).toHaveLength(2);
    expect(wrapper.get(".import-steam-link").attributes("href")).toBe("https://store.steampowered.com/app/340");
    expect(wrapper.find("button").exists()).toBeFalsy();
  });

  it("says so when nothing changed", () => {
    const wrapper = mountResults(result());

    expect(wrapper.text()).toContain("already in your library");
  });
});
