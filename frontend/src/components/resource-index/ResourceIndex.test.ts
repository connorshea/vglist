import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import ResourceIndex from "./ResourceIndex.vue";
import type { ResourceIndexItem } from "./ResourceIndex.vue";
import ResourceTile from "./ResourceTile.vue";
import ResourceTileSkeleton from "./ResourceTileSkeleton.vue";
import PaginationNav from "@/components/PaginationNav.vue";

class IntersectionObserverStub {
  observe() {}
  unobserve() {}
  disconnect() {}
}

const ITEM: ResourceIndexItem = {
  id: "1",
  name: "Shooter",
  meta: "12 games",
  coverGames: [],
  to: "/genres/1",
  editTo: "/genres/1/edit"
};

function mountIndex(state: {
  loaded: boolean;
  loading: boolean;
  refreshing?: boolean;
  items?: ResourceIndexItem[];
  page?: number;
  hasNextPage?: boolean;
}) {
  return mount(ResourceIndex, {
    props: {
      search: "",
      title: "Genres",
      kind: "genre",
      kindPlural: "genres",
      items: state.items ?? [],
      totalCount: null,
      sortLinks: [],
      nameFilter: "",
      newTo: "/genres/new",
      canEdit: false,
      deleteConsequence: "removed from every game in it.",
      loaded: state.loaded,
      loading: state.loading,
      loadingMore: false,
      refreshing: state.refreshing ?? false,
      hasNextPage: state.hasNextPage ?? false,
      page: state.page,
      deleting: false,
      error: null
    },
    global: { stubs: { RouterLink: RouterLinkStub, ConfirmDialog: true } }
  });
}

describe("ResourceIndex loading skeleton", () => {
  beforeEach(() => vi.stubGlobal("IntersectionObserver", IntersectionObserverStub));
  afterEach(() => vi.unstubAllGlobals());

  it("shows placeholder tiles during the first load", () => {
    const wrapper = mountIndex({ loaded: false, loading: true });

    expect(wrapper.findAllComponents(ResourceTileSkeleton).length).toBe(12);
    expect(wrapper.find("[role='status']").text()).toBe("Loading genres…");
  });

  it("shows the real tiles once loaded", () => {
    const wrapper = mountIndex({ loaded: true, loading: false, items: [ITEM] });

    expect(wrapper.findComponent(ResourceTileSkeleton).exists()).toBeFalsy();
    expect(wrapper.findAllComponents(ResourceTile).length).toBe(1);
    expect(wrapper.find("[role='status']").text()).toBe("");
  });

  it("keeps the current tiles up while a search or sort reloads", () => {
    const wrapper = mountIndex({ loaded: true, loading: true, refreshing: true, items: [ITEM] });

    expect(wrapper.findComponent(ResourceTileSkeleton).exists()).toBeFalsy();
    expect(wrapper.findAllComponents(ResourceTile).length).toBe(1);
  });
});

describe("ResourceIndex pagination", () => {
  beforeEach(() => vi.stubGlobal("IntersectionObserver", IntersectionObserverStub));
  afterEach(() => vi.unstubAllGlobals());

  it("shows Load more, not page buttons, without a page", () => {
    const wrapper = mountIndex({ loaded: true, loading: false, items: [ITEM], hasNextPage: true });

    expect(wrapper.findComponent(PaginationNav).exists()).toBeFalsy();
    expect(wrapper.find(".load-more-btn").exists()).toBeTruthy();
  });

  it("shows page buttons instead of Load more with a page", async () => {
    const wrapper = mountIndex({ loaded: true, loading: false, items: [ITEM], hasNextPage: true, page: 2 });

    expect(wrapper.find(".load-more-btn").exists()).toBeFalsy();
    const nav = wrapper.findComponent(PaginationNav);
    expect(nav.props("currentPage")).toBe(2);

    nav.vm.$emit("next");
    nav.vm.$emit("prev");
    expect(wrapper.emitted("goToPage")).toEqual([[3], [1]]);
  });

  it("hides the page buttons when everything fits on page 1", () => {
    const wrapper = mountIndex({ loaded: true, loading: false, items: [ITEM], page: 1 });

    expect(wrapper.findComponent(PaginationNav).exists()).toBeFalsy();
  });

  it("offers the first page when a later page is empty", async () => {
    const wrapper = mountIndex({ loaded: true, loading: false, page: 9 });

    expect(wrapper.find(".empty-state").text()).toContain("There’s nothing on page 9.");
    await wrapper.find(".empty-state button").trigger("click");
    expect(wrapper.emitted("goToPage")).toEqual([[1]]);
  });
});
