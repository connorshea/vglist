import { describe, it, expect, vi, afterEach } from "vitest";
import { mount, type VueWrapper } from "@vue/test-utils";
import { nextTick, reactive } from "vue";
import NavDropdown from "./NavDropdown.vue";

const { route } = vi.hoisted(() => ({ route: { path: "/" } }));
const reactiveRoute = reactive(route);

vi.mock("vue-router", () => ({
  useRoute: () => reactiveRoute
}));

let wrapper: VueWrapper | null = null;

function mountDropdown() {
  wrapper = mount(NavDropdown, {
    attachTo: document.body,
    slots: {
      trigger: "More",
      default: '<a href="/a">A</a><a href="/b">B</a><button type="button">C</button>'
    }
  });
  return wrapper;
}

function trigger(w: VueWrapper) {
  return w.find("button.nav-dropdown-trigger");
}

function isOpen(w: VueWrapper) {
  return w.classes().includes("is-active");
}

afterEach(() => {
  wrapper?.unmount();
  wrapper = null;
  reactiveRoute.path = "/";
});

describe("NavDropdown", () => {
  it("starts closed, with the trigger pointing at the menu", () => {
    const w = mountDropdown();
    expect(isOpen(w)).toBeFalsy();
    expect(trigger(w).attributes("aria-expanded")).toBe("false");
    const menuId = trigger(w).attributes("aria-controls");
    expect(menuId).toBeTruthy();
    expect(w.find(".navbar-dropdown").attributes("id")).toBe(menuId);
  });

  it("toggles when the trigger is clicked (Enter and Space click a button)", async () => {
    const w = mountDropdown();
    await trigger(w).trigger("click");
    expect(isOpen(w)).toBeTruthy();
    expect(trigger(w).attributes("aria-expanded")).toBe("true");
    await trigger(w).trigger("click");
    expect(isOpen(w)).toBeFalsy();
  });

  it("opens on ArrowDown and moves focus through the items, wrapping around", async () => {
    const w = mountDropdown();
    await trigger(w).trigger("keydown", { key: "ArrowDown" });
    await nextTick();
    expect(isOpen(w)).toBeTruthy();
    expect(document.activeElement?.textContent).toBe("A");

    await w.find('a[href="/a"]').trigger("keydown", { key: "ArrowDown" });
    expect(document.activeElement?.textContent).toBe("B");
    await w.find('a[href="/b"]').trigger("keydown", { key: "ArrowDown" });
    expect(document.activeElement?.textContent).toBe("C");
    await w.find(".navbar-dropdown button").trigger("keydown", { key: "ArrowDown" });
    expect(document.activeElement?.textContent).toBe("A");
    await w.find('a[href="/a"]').trigger("keydown", { key: "ArrowUp" });
    expect(document.activeElement?.textContent).toBe("C");
  });

  it("opens on ArrowUp with focus on the last item, and Home/End jump", async () => {
    const w = mountDropdown();
    await trigger(w).trigger("keydown", { key: "ArrowUp" });
    await nextTick();
    expect(document.activeElement?.textContent).toBe("C");
    await w.find(".navbar-dropdown button").trigger("keydown", { key: "Home" });
    await nextTick();
    expect(document.activeElement?.textContent).toBe("A");
    await w.find('a[href="/a"]').trigger("keydown", { key: "End" });
    await nextTick();
    expect(document.activeElement?.textContent).toBe("C");
  });

  it("closes on Escape and returns focus to the trigger", async () => {
    const w = mountDropdown();
    await trigger(w).trigger("keydown", { key: "ArrowDown" });
    await nextTick();
    await w.find('a[href="/a"]').trigger("keydown", { key: "Escape" });
    expect(isOpen(w)).toBeFalsy();
    expect(document.activeElement).toBe(trigger(w).element);
  });

  it("closes when focus leaves the dropdown, but not when it moves inside", async () => {
    const w = mountDropdown();
    await trigger(w).trigger("click");
    await w.find('a[href="/a"]').trigger("focusout", { relatedTarget: w.find('a[href="/b"]').element });
    expect(isOpen(w)).toBeTruthy();
    await w.find('a[href="/b"]').trigger("focusout", { relatedTarget: document.body });
    expect(isOpen(w)).toBeFalsy();
  });

  it("opens on hover, and a click while hovered keeps it open", async () => {
    const w = mountDropdown();
    await w.trigger("mouseenter");
    expect(isOpen(w)).toBeTruthy();
    await trigger(w).trigger("click");
    expect(isOpen(w)).toBeTruthy();
    await w.trigger("mouseleave");
    expect(isOpen(w)).toBeFalsy();
  });

  it("closes when an item is picked or the route changes", async () => {
    const w = mountDropdown();
    await trigger(w).trigger("click");
    await w.find('a[href="/a"]').trigger("click");
    expect(isOpen(w)).toBeFalsy();

    await trigger(w).trigger("click");
    reactiveRoute.path = "/games";
    await nextTick();
    expect(isOpen(w)).toBeFalsy();
  });
});
