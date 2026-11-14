import { describe, it, expect, afterEach } from "vitest";
import { defineComponent, h } from "vue";
import { mount, enableAutoUnmount, flushPromises } from "@vue/test-utils";
import { useMenuButton } from "./useMenuButton";

const Menu = defineComponent({
  setup() {
    const menu = useMenuButton();
    return () =>
      h("div", [
        h("div", { ref: menu.wrapRef, class: "wrap", onFocusout: menu.onFocusout }, [
          h(
            "button",
            {
              ref: menu.buttonRef,
              class: "trigger",
              "aria-expanded": menu.isOpen.value,
              onClick: menu.toggle,
              onKeydown: menu.onButtonKeydown
            },
            "More"
          ),
          menu.isOpen.value
            ? h("div", { ref: menu.menuRef, role: "menu", onKeydown: menu.onMenuKeydown }, [
                h("button", { role: "menuitem", class: "one" }, "One"),
                h("button", { role: "menuitem", class: "two" }, "Two"),
                h("button", { role: "menuitem", class: "three" }, "Three")
              ])
            : null
        ]),
        h("button", { class: "outside" }, "Outside")
      ]);
  }
});

async function mountMenu() {
  const wrapper = mount(Menu, { attachTo: document.body });
  return wrapper;
}

function focused(): string | null {
  return (document.activeElement as HTMLElement | null)?.className ?? null;
}

describe("useMenuButton", () => {
  enableAutoUnmount(afterEach);

  it("opens on click and focuses the first item", async () => {
    const wrapper = await mountMenu();
    await wrapper.find(".trigger").trigger("click");
    await flushPromises();
    expect(wrapper.find('[role="menu"]').exists()).toBeTruthy();
    expect(focused()).toBe("one");
  });

  it("opens on the last item with ArrowUp on the button", async () => {
    const wrapper = await mountMenu();
    await wrapper.find(".trigger").trigger("keydown", { key: "ArrowUp" });
    await flushPromises();
    expect(focused()).toBe("three");
  });

  it("moves between items with the arrow keys, wrapping, and Home/End", async () => {
    const wrapper = await mountMenu();
    await wrapper.find(".trigger").trigger("click");
    await flushPromises();
    const menu = wrapper.find('[role="menu"]');
    await menu.trigger("keydown", { key: "ArrowDown" });
    expect(focused()).toBe("two");
    await menu.trigger("keydown", { key: "End" });
    expect(focused()).toBe("three");
    await menu.trigger("keydown", { key: "ArrowDown" });
    expect(focused()).toBe("one");
    await menu.trigger("keydown", { key: "ArrowUp" });
    expect(focused()).toBe("three");
    await menu.trigger("keydown", { key: "Home" });
    expect(focused()).toBe("one");
  });

  it("closes on Escape and returns focus to the button", async () => {
    const wrapper = await mountMenu();
    await wrapper.find(".trigger").trigger("click");
    await flushPromises();
    await wrapper.find('[role="menu"]').trigger("keydown", { key: "Escape" });
    expect(wrapper.find('[role="menu"]').exists()).toBeFalsy();
    expect(focused()).toBe("trigger");
  });

  it("closes when focus moves outside the menu", async () => {
    const wrapper = await mountMenu();
    await wrapper.find(".trigger").trigger("click");
    await flushPromises();
    const outside = wrapper.find(".outside").element as HTMLElement;
    await wrapper.find(".three").trigger("focusout", { relatedTarget: outside });
    expect(wrapper.find('[role="menu"]').exists()).toBeFalsy();
  });

  it("stays open when focus moves between its own items", async () => {
    const wrapper = await mountMenu();
    await wrapper.find(".trigger").trigger("click");
    await flushPromises();
    const two = wrapper.find(".two").element as HTMLElement;
    await wrapper.find(".one").trigger("focusout", { relatedTarget: two });
    expect(wrapper.find('[role="menu"]').exists()).toBeTruthy();
  });

  it("closes on a pointer press outside", async () => {
    const wrapper = await mountMenu();
    await wrapper.find(".trigger").trigger("click");
    await flushPromises();
    document.body.dispatchEvent(new Event("pointerdown", { bubbles: true }));
    await flushPromises();
    expect(wrapper.find('[role="menu"]').exists()).toBeFalsy();
  });
});
