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

  describe("with page numbers", () => {
    it("shows Previous/Next instead of Show more, and asks for the next page", async () => {
      const wrapper = mountList({ page: 1, hasNextPage: true });

      expect(wrapper.find(".res-more-btn").exists()).toBeFalsy();
      expect(wrapper.find("[aria-current='page']").text()).toBe("1");
      expect(wrapper.find("[aria-label='Previous page']").attributes("disabled")).toBeDefined();

      await wrapper.find("[aria-label='Next page']").trigger("click");

      expect(wrapper.emitted("goToPage")).toEqual([[2]]);
    });

    it("asks for the previous page", async () => {
      const wrapper = mountList({ page: 3, hasNextPage: false });

      expect(wrapper.find("[aria-label='Next page']").attributes("disabled")).toBeDefined();
      await wrapper.find("[aria-label='Previous page']").trigger("click");

      expect(wrapper.emitted("goToPage")).toEqual([[2]]);
    });

    it("hides the page buttons when everything fits on one page", () => {
      expect(mountList({ page: 1, hasNextPage: false }).find("nav").exists()).toBeFalsy();
    });

    it("disables the page buttons while a page loads", () => {
      const wrapper = mountList({ page: 2, hasNextPage: true, refreshing: true });

      expect(wrapper.find("[aria-label='Previous page']").attributes("disabled")).toBeDefined();
      expect(wrapper.find("[aria-label='Next page']").attributes("disabled")).toBeDefined();
    });

    it("offers the first page when a later page is empty", async () => {
      const wrapper = mountList({ games: [], page: 9, hasNextPage: false });

      expect(wrapper.find(".res-empty").text()).toContain("There's nothing on page 9.");
      expect(wrapper.find("nav").exists()).toBeFalsy();
      await wrapper.find(".res-link-btn").trigger("click");

      expect(wrapper.emitted("goToPage")).toEqual([[1]]);
    });
  });
});
