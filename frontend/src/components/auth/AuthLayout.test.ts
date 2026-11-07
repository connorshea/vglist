import { describe, it, expect } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import AuthLayout from "./AuthLayout.vue";

const mountOptions = {
  global: {
    stubs: {
      RouterLink: RouterLinkStub
    }
  }
};

describe("AuthLayout", () => {
  it("renders a Back to home link that goes to the home page", () => {
    const wrapper = mount(AuthLayout, mountOptions);

    const back = wrapper.findAllComponents(RouterLinkStub).find((link) => link.classes("auth-back"));
    expect(back).toBeDefined();
    expect(back?.text()).toBe("Back to home");
    expect(back?.props("to")).toBe("/");
  });

  it("renders the slot content", () => {
    const wrapper = mount(AuthLayout, { ...mountOptions, slots: { default: "<h1>Sign in</h1>" } });

    expect(wrapper.find("h1").text()).toBe("Sign in");
  });
});
