import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import ResourceIndex from "./ResourceIndex.vue";
import type { ResourceIndexItem } from "./ResourceIndex.vue";
import ResourceTile from "./ResourceTile.vue";
import ResourceTileSkeleton from "./ResourceTileSkeleton.vue";

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

function mountIndex(state: { loaded: boolean; loading: boolean; refreshing?: boolean; items?: ResourceIndexItem[] }) {
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
      hasNextPage: false,
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
