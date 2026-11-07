import { describe, expect, it } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import type { LibraryGamePurchaseFieldsFragment } from "@/types/graphql";
import LibraryGameTile from "./LibraryGameTile.vue";

function purchase(overrides: Partial<LibraryGamePurchaseFieldsFragment> = {}): LibraryGamePurchaseFieldsFragment {
  return {
    id: "1",
    game: { id: "10", name: "Half-Life: Alyx", coverUrl: "https://files.vglist.co/alyx.jpg" },
    hoursPlayed: null,
    completionStatus: null,
    rating: null,
    ...overrides
  };
}

function mountTile(p: LibraryGamePurchaseFieldsFragment, hideHours = false) {
  return mount(LibraryGameTile, {
    props: { purchase: p, hideHours },
    global: { stubs: { RouterLink: RouterLinkStub } }
  });
}

describe("LibraryGameTile", () => {
  it("leaves the hover panel's meta row out when there is nothing to put in it", () => {
    const wrapper = mountTile(purchase());

    expect(wrapper.find(".library-tile-hover b").text()).toBe("Half-Life: Alyx");
    expect(wrapper.find(".library-tile-meta").exists()).toBeFalsy();
  });

  it("shows the meta row when the purchase has a status, hours or rating", () => {
    const wrapper = mountTile(purchase({ completionStatus: "COMPLETED", hoursPlayed: 12, rating: 90 }));

    expect(wrapper.find(".library-tile-meta").text()).toContain("90/100");
  });

  it("leaves the meta row out when hours are hidden and are all it would show", () => {
    const wrapper = mountTile(purchase({ hoursPlayed: 12 }), true);

    expect(wrapper.find(".library-tile-meta").exists()).toBeFalsy();
  });

  it("names the game once for screen readers", () => {
    const wrapper = mountTile(purchase({ rating: 90 }));

    expect(wrapper.findComponent(RouterLinkStub).attributes("aria-label")).toBe("Half-Life: Alyx, rated 90");
    expect(wrapper.find("img").attributes("alt")).toBe("");
  });
});
