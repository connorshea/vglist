import { describe, it, expect } from "vitest";
import { mount } from "@vue/test-utils";
import AboutPage from "./AboutPage.vue";

describe("AboutPage", () => {
  it("renders the page title", () => {
    const wrapper = mount(AboutPage);
    expect(wrapper.find("h1").text()).toBe("About vglist");
  });

  it("renders a description of the site", () => {
    const wrapper = mount(AboutPage);
    expect(wrapper.text()).toContain("open-source video game library tracking website");
  });

  it("renders a link to the GitHub repository", () => {
    const wrapper = mount(AboutPage);
    const link = wrapper.find('a[href="https://github.com/connorshea/vglist"]');
    expect(link.exists()).toBeTruthy();
    expect(link.text()).toBe("GitHub");
    expect(link.attributes("target")).toBe("_blank");
    expect(link.attributes("rel")).toBe("noopener");
  });
});
