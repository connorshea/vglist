import { describe, it, expect } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import ResourceGameList from "./ResourceGameList.vue";
import type { ResourceGameFieldsFragment } from "@/types/graphql";

const games: ResourceGameFieldsFragment[] = [
  { id: "1", name: "Hades", coverUrl: "https://example.com/hades.jpg", releaseDate: "2020-09-17", isInLibrary: true },
  { id: "2", name: "Hollow Knight: Silksong", coverUrl: null, releaseDate: null, isInLibrary: false }
];

function mountList(props: Record<string, unknown> = {}) {
  return mount(ResourceGameList, {
    props: {
      label: "Games",
      games,
      sortBy: "NEWEST_RELEASE",
      emptyText: "No games yet.",
      refreshing: false,
      hasNextPage: false,
      loadingMore: false,
      ...props
    },
    global: { stubs: { RouterLink: RouterLinkStub } }
  });
}

describe("ResourceGameList", () => {
  it("marks the current sort as pressed", () => {
    const wrapper = mountList({ sortBy: "MOST_OWNERS" });
    const pressed = wrapper.findAll(".res-seg-btn").filter((b) => b.attributes("aria-pressed") === "true");

    expect(pressed.map((b) => b.text())).toEqual(["Most owners"]);
  });

  it("updates the sort when another option is clicked", async () => {
    const wrapper = mountList();
    const nameButton = wrapper.findAll(".res-seg-btn").find((b) => b.text() === "A → Z");

    await nameButton!.trigger("click");

    expect(wrapper.emitted("update:sortBy")).toEqual([["NAME"]]);
  });

  it("shows covers, initials, release years and the in-library badge", () => {
    const wrapper = mountList();
    const cards = wrapper.findAll(".res-card");

    expect(cards[0].find("img").attributes("src")).toBe("https://example.com/hades.jpg");
    expect(cards[0].find(".res-card-meta").text()).toBe("2020");
    expect(cards[0].find(".res-owned").exists()).toBeTruthy();

    expect(cards[1].find(".res-cover-ph").text()).toBe("HKS");
    expect(cards[1].find(".res-card-meta").exists()).toBeFalsy();
    expect(cards[1].find(".res-owned").exists()).toBeFalsy();
  });

  it("shows the empty text when there are no games", () => {
    const wrapper = mountList({ games: [] });

    expect(wrapper.find(".res-empty").text()).toBe("No games yet.");
  });

  it("doesn't show the empty text while a new sort is loading", () => {
    const wrapper = mountList({ games: [], refreshing: true });

    expect(wrapper.find(".res-empty").exists()).toBeFalsy();
  });

  it("asks for more games only when there is another page", async () => {
    expect(mountList().find(".res-more-btn").exists()).toBeFalsy();

    const wrapper = mountList({ hasNextPage: true });
    await wrapper.find(".res-more-btn").trigger("click");

    expect(wrapper.emitted("loadMore")).toHaveLength(1);
  });

  it("disables the button while the next page loads", () => {
    const wrapper = mountList({ hasNextPage: true, loadingMore: true });

    expect(wrapper.find(".res-more-btn").attributes("disabled")).toBeDefined();
    expect(wrapper.find(".res-more-btn").text()).toBe("Loading…");
  });
});
