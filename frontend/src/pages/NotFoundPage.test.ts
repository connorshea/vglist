import { describe, it, expect } from "vitest";
import { mount } from "@vue/test-utils";
import NotFoundPage from "./NotFoundPage.vue";

const mountOptions = {
  global: {
    stubs: {
      RouterLink: true
    }
  }
};

describe("NotFoundPage", () => {
  it("renders the 404 heading", () => {
    const wrapper = mount(NotFoundPage, mountOptions);
    expect(wrapper.find("h1").text()).toBe("404");
  });

  it("renders the 'Page not found' subtitle", () => {
    const wrapper = mount(NotFoundPage, mountOptions);
    expect(wrapper.find(".subtitle").text()).toBe("Page not found");
  });

  it("renders a Go Home link pointing to /", () => {
    const wrapper = mount(NotFoundPage, {
      global: {
        stubs: {
          RouterLink: {
            template: '<a :href="to"><slot /></a>',
            props: ["to"]
          }
        }
      }
    });
    const link = wrapper.find("a");
    expect(link.exists()).toBeTruthy();
    expect(link.attributes("href")).toBe("/");
    expect(link.text()).toBe("Go Home");
  });
});
