import { describe, expect, it } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import GameDetailsCard, { type GameDetails } from "./GameDetailsCard.vue";

const empty: GameDetails = {
  releaseDate: null,
  developers: { nodes: [] },
  publishers: { nodes: [] },
  engines: { nodes: [] },
  platforms: { nodes: [] },
  genres: { nodes: [] },
  series: null
};

function mountCard(game: Partial<GameDetails>) {
  return mount(GameDetailsCard, {
    props: { game: { ...empty, ...game } },
    global: { stubs: { RouterLink: RouterLinkStub } }
  });
}

describe("GameDetailsCard", () => {
  it("lists only the details the game has", () => {
    const wrapper = mountCard({
      releaseDate: "2025-09-04",
      developers: { nodes: [{ id: "1", name: "Team Cherry" }] },
      platforms: {
        nodes: [
          { id: "2", name: "Windows" },
          { id: "3", name: "macOS" }
        ]
      }
    });

    expect(wrapper.findAll("dt").map((dt) => dt.text())).toEqual(["Released", "Developer", "Platforms"]);
    expect(wrapper.text()).toContain("September 4, 2025");
    expect(wrapper.findAllComponents(RouterLinkStub).map((l) => l.props("to"))).toEqual([
      "/companies/1",
      "/platforms/2",
      "/platforms/3"
    ]);
    expect(wrapper.find("dd:last-of-type").text()).toBe("Windows, macOS");
  });

  it("shows an empty state for a game with no details", () => {
    expect(mountCard({}).text()).toContain("No details yet.");
  });
});
