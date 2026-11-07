import { describe, expect, it } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import ResourceTile from "./ResourceTile.vue";

function mountTile(coverGames: { id: string; name: string; coverUrl?: string | null }[]) {
  return mount(ResourceTile, {
    props: {
      id: "1",
      name: "Nintendo Switch",
      meta: "1,231 games",
      coverGames,
      to: "/platforms/1",
      editTo: "/platforms/1/edit",
      kind: "platform"
    },
    global: { stubs: { RouterLink: RouterLinkStub } }
  });
}

describe("ResourceTile", () => {
  it("shows the resource's initials instead of an empty mosaic when there are no covers", () => {
    const wrapper = mountTile([]);
    expect(wrapper.find(".tile-placeholder").text()).toBe("NS");
    expect(wrapper.findAll(".tile-slot")).toHaveLength(0);
  });

  it("shows a four-slot mosaic when there are covers", () => {
    const wrapper = mountTile([{ id: "10", name: "Splatoon 3", coverUrl: "https://example.com/c.jpg" }]);
    expect(wrapper.find(".tile-placeholder").exists()).toBeFalsy();
    expect(wrapper.findAll(".tile-slot")).toHaveLength(4);
    expect(wrapper.find(".tile-slot img").attributes("src")).toBe("https://example.com/c.jpg");
  });
});
