import { describe, expect, it } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import GameHeroPanel from "./GameHeroPanel.vue";

const users = (n: number) =>
  Array.from({ length: n }, (_, i) => ({ id: String(i + 1), slug: `user-${i + 1}`, username: `user${i + 1}` }));

function mountPanel(props: Partial<InstanceType<typeof GameHeroPanel>["$props"]> = {}) {
  return mount(GameHeroPanel, {
    props: {
      avgRating: 87.4,
      ratingCount: 214,
      entry: null,
      owners: { nodes: users(3), totalCount: 1204 },
      favoriters: { nodes: [], totalCount: 0 },
      externalLinks: [],
      ...props
    },
    global: { stubs: { RouterLink: RouterLinkStub } }
  });
}

describe("GameHeroPanel", () => {
  it("shows the average rating and how many ratings it's from", () => {
    const text = mountPanel().text();

    expect(text).toContain("87.4 / 100 from 214 ratings");
  });

  it("says so when there are no ratings yet", () => {
    expect(mountPanel({ avgRating: null, ratingCount: 0 }).text()).toContain("No ratings yet");
  });

  it("links each owner and shows empty states", () => {
    const wrapper = mountPanel();
    const links = wrapper.findAllComponents(RouterLinkStub);

    expect(links.map((l) => l.props("to"))).toEqual(["/users/user-1", "/users/user-2", "/users/user-3"]);
    expect(links[0].attributes("aria-label")).toBe("user1");
    expect(wrapper.text()).toContain("1,204");
    expect(wrapper.text()).toContain("No favorites yet.");
  });

  it("summarises your entry and asks to edit it when clicked", async () => {
    const wrapper = mountPanel({ entry: { completionStatus: "COMPLETED", rating: 92, hoursPlayed: 41 } });
    const you = wrapper.find(".hero-panel-you");

    expect(you.text()).toContain("Completed · rated 92 · 41h");
    await you.trigger("click");
    expect(wrapper.emitted("edit-entry")).toHaveLength(1);
  });

  it("falls back to 'In library' for an entry with nothing filled in", () => {
    const wrapper = mountPanel({ entry: { completionStatus: null, rating: null, hoursPlayed: null } });

    expect(wrapper.find(".hero-panel-you").text()).toContain("You: In library");
  });

  it("hides the row when the game isn't in your library", () => {
    expect(mountPanel().find(".hero-panel-you").exists()).toBeFalsy();
  });

  it("shows every external link without collapsing any", () => {
    const externalLinks = ["Steam", "GOG", "IGDB", "Wikidata", "MobyGames", "PCGamingWiki"].map((label) => ({
      label,
      url: `https://example.com/${label}`
    }));
    const wrapper = mountPanel({ externalLinks });

    expect(wrapper.findAll("a.hero-tag").map((link) => link.text())).toEqual(externalLinks.map((link) => link.label));
    expect(wrapper.find(".hero-tag-more").exists()).toBeFalsy();
  });
});
