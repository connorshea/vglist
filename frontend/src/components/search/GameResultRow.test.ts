import { describe, it, expect } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import GameResultRow from "./GameResultRow.vue";
import type { SearchGameFieldsFragment } from "@/types/graphql";

function game(overrides: Partial<SearchGameFieldsFragment> = {}): SearchGameFieldsFragment {
  return {
    id: "42",
    name: "Ratatouille",
    releaseDate: "2007-06-26",
    coverUrl: "https://example.com/cover.jpg",
    isInLibrary: false,
    platforms: { totalCount: 0, nodes: [] },
    developers: { nodes: [{ id: "1", name: "Heavy Iron Studios" }] },
    publishers: { nodes: [{ id: "2", name: "THQ" }] },
    series: { id: "3", name: "Ratatouille" },
    ...overrides
  };
}

function platforms(totalCount: number, ...names: string[]) {
  return { totalCount, nodes: names.map((name, i) => ({ id: String(i), name })) };
}

function mountRow(g: SearchGameFieldsFragment) {
  return mount(GameResultRow, { props: { game: g }, global: { stubs: { RouterLink: RouterLinkStub } } });
}

describe("GameResultRow", () => {
  it("links to the game and shows its year, developers, publishers, and series", () => {
    const wrapper = mountRow(game());

    expect(wrapper.findComponent(RouterLinkStub).props("to")).toBe("/games/42");
    expect(wrapper.text()).toContain("Ratatouille");
    expect(wrapper.text()).toContain("2007");
    expect(wrapper.text()).toContain("Heavy Iron Studios / THQ");
    expect(wrapper.text()).toContain("Series: Ratatouille");
  });

  it("shows up to four platform chips and collapses the rest into +N", () => {
    const wrapper = mountRow(game({ platforms: platforms(6, "PS2", "Xbox", "GameCube", "Wii", "PC", "Mac") }));

    // The +N chip's visible text is the aria-hidden part; the rest is for screen readers.
    const chips = wrapper.findAll(".platform-chip").map((c) => {
      const visible = c.find("[aria-hidden]");
      return visible.exists() ? visible.text() : c.text();
    });
    expect(chips).toEqual(["PS2", "Xbox", "GameCube", "Wii", "+2"]);
    expect(wrapper.find(".platform-more").attributes("title")).toBe("PC, Mac");
  });

  it("counts platforms beyond the ones fetched", () => {
    const wrapper = mountRow(game({ platforms: platforms(11, "A", "B", "C", "D", "E", "F", "G", "H") }));

    expect(wrapper.find(".platform-more [aria-hidden]").text()).toBe("+7");
    expect(wrapper.find(".platform-more").attributes("title")).toBe("E, F, G, H, and 3 more");
  });

  // The whole row is one link, so screen readers announce it from its text.
  // An `aria-label` on the list would replace the platform names in that
  // announcement, and they're what tell same-named games apart.
  it("keeps every platform name in the link's accessible text", () => {
    const wrapper = mountRow(game({ platforms: platforms(6, "PS2", "Xbox", "GameCube", "Wii", "PC", "Mac") }));

    expect(wrapper.find(".platform-list").attributes("aria-label")).toBeUndefined();
    expect(wrapper.find(".platform-more .is-sr-only").text()).toBe("Also on PC, Mac");
  });

  it("leaves out everything that is empty", () => {
    const wrapper = mountRow(
      game({
        releaseDate: null,
        coverUrl: null,
        developers: { nodes: [] },
        publishers: { nodes: [] },
        series: null
      })
    );

    expect(wrapper.find(".result-meta").exists()).toBeFalsy();
    expect(wrapper.find(".platform-list").exists()).toBeFalsy();
    expect(wrapper.text()).not.toContain("Series");
    expect(wrapper.find("img").exists()).toBeFalsy();
    expect(wrapper.find(".cover-placeholder").text()).toBe("R");
  });

  it("only shows the library badge when the game is in the viewer's library", () => {
    expect(mountRow(game({ isInLibrary: true })).text()).toContain("In your library");
    expect(mountRow(game({ isInLibrary: false })).text()).not.toContain("In your library");
    expect(mountRow(game({ isInLibrary: null })).text()).not.toContain("In your library");
  });
});
