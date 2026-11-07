import { describe, expect, it } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import GameSeriesShelf from "./GameSeriesShelf.vue";

const series = { id: "7", name: "Half-Life" };

const games = [
  { id: "1", name: "Half-Life", releaseDate: "1998-11-19", coverUrl: "https://files.vglist.co/hl.jpg" },
  { id: "3", name: "Half-Life: Alyx", releaseDate: "2020-03-23", coverUrl: null },
  { id: "4", name: "Half-Life 3", releaseDate: null, coverUrl: null }
];

function mountShelf(props: { games: typeof games; totalCount: number }) {
  return mount(GameSeriesShelf, {
    props: { series, ...props },
    global: { stubs: { RouterLink: RouterLinkStub } }
  });
}

function linkTargets(wrapper: ReturnType<typeof mountShelf>) {
  return wrapper.findAllComponents(RouterLinkStub).map((link) => link.props("to"));
}

describe("GameSeriesShelf", () => {
  it("renders nothing when there are no other games in the series", () => {
    const wrapper = mountShelf({ games: [], totalCount: 0 });

    expect(wrapper.find("section").exists()).toBeFalsy();
  });

  it("shows the other games with their release years, linking the series", () => {
    const wrapper = mountShelf({ games, totalCount: 3 });

    expect(wrapper.find("h2").text()).toBe("More from this series");
    expect(wrapper.findAll("li")).toHaveLength(3);
    expect(wrapper.findAll(".game-tile-name").map((n) => n.text())).toEqual([
      "Half-Life",
      "Half-Life: Alyx",
      "Half-Life 3"
    ]);
    expect(wrapper.findAll(".game-tile-meta").map((m) => m.text())).toEqual(["1998", "2020"]);
    expect(linkTargets(wrapper)).toEqual(["/series/7", "/games/1", "/games/3", "/games/4"]);
  });

  it("falls back to the initials placeholder for games without a cover", () => {
    const wrapper = mountShelf({ games, totalCount: 3 });

    expect(wrapper.findAll("img")).toHaveLength(1);
    expect(wrapper.findAll(".game-tile-placeholder").map((p) => p.text())).toEqual(["HA", "H3"]);
  });

  it("links to the whole series when it has more games than the shelf shows", () => {
    const wrapper = mountShelf({ games, totalCount: 5 });

    const seeAll = wrapper.find(".series-shelf-more");
    // The five other games plus this one.
    expect(seeAll.text()).toBe("See all 6 Half-Life games");
    expect(linkTargets(wrapper)[0]).toBe("/series/7");
  });

  it("leaves out the see-all link when every other game is shown", () => {
    expect(mountShelf({ games, totalCount: 3 }).find(".series-shelf-more").exists()).toBeFalsy();
  });
});
