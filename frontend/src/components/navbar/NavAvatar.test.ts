import { describe, it, expect } from "vitest";
import { mount } from "@vue/test-utils";
import NavAvatar from "./NavAvatar.vue";

describe("NavAvatar", () => {
  it("shows the image when there is an avatar URL", () => {
    const wrapper = mount(NavAvatar, { props: { username: "connor", avatarUrl: "https://files.example/a.jpg" } });
    expect(wrapper.find("img").attributes("src")).toBe("https://files.example/a.jpg");
  });

  it("shows the initial when there is no avatar URL", () => {
    const wrapper = mount(NavAvatar, { props: { username: "connor", avatarUrl: null } });
    expect(wrapper.find("img").exists()).toBeFalsy();
    expect(wrapper.text()).toBe("C");
  });

  it("falls back to the initial when the image fails to load", async () => {
    const wrapper = mount(NavAvatar, { props: { username: "connor", avatarUrl: "https://files.example/gone.jpg" } });
    await wrapper.find("img").trigger("error");
    expect(wrapper.find("img").exists()).toBeFalsy();
    expect(wrapper.text()).toBe("C");
  });

  it("tries again when the avatar URL changes", async () => {
    const wrapper = mount(NavAvatar, { props: { username: "connor", avatarUrl: "https://files.example/gone.jpg" } });
    await wrapper.find("img").trigger("error");
    await wrapper.setProps({ avatarUrl: "https://files.example/new.jpg" });
    expect(wrapper.find("img").attributes("src")).toBe("https://files.example/new.jpg");
  });
});
