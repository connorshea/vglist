import { describe, it, expect } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import AboutPage from "./AboutPage.vue";

function mountPage() {
  return mount(AboutPage, { global: { stubs: { RouterLink: RouterLinkStub } } });
}

describe("AboutPage", () => {
  it("renders the logo as the page heading", () => {
    const wrapper = mountPage();
    const img = wrapper.find("h1 img");
    expect(img.exists()).toBeTruthy();
    expect(img.attributes("alt")).toBe("About vglist");
  });

  it("renders the GitHub, Discord and Changelog links", () => {
    const wrapper = mountPage();
    const links = wrapper.findAll(".about-links a");
    expect(links.map((link) => link.text())).toEqual(["GitHub", "Discord", "Changelog"]);
    expect(links.map((link) => link.attributes("href"))).toEqual([
      "https://github.com/connorshea/vglist",
      "https://discord.gg/Ma8Ztcc",
      "https://github.com/connorshea/vglist/blob/main/CHANGELOG.md"
    ]);
    for (const link of links) {
      expect(link.attributes("target")).toBe("_blank");
      expect(link.attributes("rel")).toBe("noopener noreferrer");
    }
  });

  it("credits Wikidata and links to the creator's profile", () => {
    const wrapper = mountPage();
    expect(wrapper.find('a[href="https://www.wikidata.org"]').text()).toBe("Wikidata");
    const profile = wrapper.findComponent(RouterLinkStub);
    expect(profile.props("to")).toBe("/users/connor");
    expect(profile.text()).toBe("Connor Shea");
  });

  it("hides the background mosaic from assistive technology", () => {
    const wrapper = mountPage();
    expect(wrapper.find(".about-mosaic").attributes("aria-hidden")).toBe("true");
  });
});
