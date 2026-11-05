import { describe, it, expect, afterEach } from "vitest";
import { mount, type VueWrapper } from "@vue/test-utils";
import { nextTick } from "vue";
import GameLibrarySheet from "./GameLibrarySheet.vue";

describe("GameLibrarySheet", () => {
  let wrapper: VueWrapper | null = null;

  function mountSheet() {
    wrapper = mount(GameLibrarySheet, {
      props: { title: "Add to library", gameName: "Outer Wilds", coverUrl: null },
      slots: { default: '<input id="first" /><button id="last" type="button">Save</button>' },
      attachTo: document.body
    });
    return wrapper;
  }

  function sheet(): HTMLElement {
    const el = document.body.querySelector<HTMLElement>(".lsheet");
    if (!el) throw new Error("sheet not rendered");
    return el;
  }

  afterEach(() => {
    wrapper?.unmount();
    wrapper = null;
  });

  it("is a labelled modal dialog naming the game", () => {
    mountSheet();
    const el = sheet();
    expect(el.getAttribute("role")).toBe("dialog");
    expect(el.getAttribute("aria-modal")).toBe("true");
    expect(document.getElementById(el.getAttribute("aria-labelledby") ?? "")?.textContent).toBe("Add to library");
    expect(el.textContent).toContain("Outer Wilds");
  });

  it("focuses the sheet and locks page scroll while open", async () => {
    mountSheet();
    await nextTick();
    expect(document.activeElement).toBe(sheet());
    expect(document.body.style.overflow).toBe("hidden");
    wrapper?.unmount();
    wrapper = null;
    expect(document.body.style.overflow).toBe("");
  });

  it("closes on Escape, the close button and the scrim", async () => {
    const w = mountSheet();
    sheet().dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }));
    document.body.querySelector<HTMLButtonElement>(".lsheet-close")?.click();
    document.body.querySelector<HTMLElement>(".lsheet-scrim")?.click();
    await nextTick();
    expect(w.emitted("close")).toHaveLength(3);
  });

  it("keeps Tab inside the sheet", async () => {
    mountSheet();
    const last = document.getElementById("last");
    last?.focus();
    const tab = new KeyboardEvent("keydown", { key: "Tab", bubbles: true, cancelable: true });
    last?.dispatchEvent(tab);
    expect(tab.defaultPrevented).toBeTruthy();
    expect(document.activeElement?.classList.contains("lsheet-close")).toBeTruthy();
  });
});
