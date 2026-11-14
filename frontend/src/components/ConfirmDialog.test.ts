import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, ref } from "vue";
import { enableAutoUnmount, mount } from "@vue/test-utils";
import ConfirmDialog from "./ConfirmDialog.vue";

enableAutoUnmount(afterEach);

afterEach(() => {
  document.body.innerHTML = "";
});

interface Options {
  open?: boolean;
  loading?: boolean;
  initialFocus?: string;
  variant?: "danger" | "primary";
  withInput?: boolean;
}

// The dialog behind an "Open" button, the way pages use it, so focus has
// somewhere to come back to.
function mountDialog({ open = false, loading = false, initialFocus, variant, withInput = false }: Options = {}) {
  const isOpen = ref(open);
  const confirmed = ref(0);
  const wrapper = mount(
    defineComponent({
      setup() {
        return () => [
          h("button", { id: "opener", onClick: () => (isOpen.value = true) }, "Open"),
          h(
            ConfirmDialog,
            {
              modelValue: isOpen.value,
              "onUpdate:modelValue": (value: boolean) => (isOpen.value = value),
              onConfirm: () => confirmed.value++,
              title: "Remove Portal 2?",
              loading,
              initialFocus,
              variant
            },
            { default: () => (withInput ? h("input", { id: "reason" }) : "It'll be gone for good.") }
          )
        ];
      }
    }),
    { attachTo: document.body }
  );
  return { wrapper, isOpen, confirmed };
}

function dialog(): HTMLElement | null {
  return document.body.querySelector('[role="dialog"]');
}

function buttons(): HTMLButtonElement[] {
  return Array.from(document.body.querySelectorAll<HTMLButtonElement>(".cd-btn"));
}

function press(key: string, options: KeyboardEventInit = {}): KeyboardEvent {
  const event = new KeyboardEvent("keydown", { key, bubbles: true, cancelable: true, ...options });
  (document.activeElement ?? document.body).dispatchEvent(event);
  return event;
}

async function openWithOpener(options: Options = {}) {
  const result = mountDialog(options);
  const opener = document.getElementById("opener") as HTMLButtonElement;
  opener.focus();
  await result.wrapper.find("#opener").trigger("click");
  // The dialog renders, then focuses on the tick after.
  await result.wrapper.vm.$nextTick();
  await result.wrapper.vm.$nextTick();
  return { ...result, opener };
}

describe("ConfirmDialog", () => {
  it("renders nothing while closed", () => {
    mountDialog();
    expect(dialog()).toBeNull();
  });

  it("is a labelled modal dialog", async () => {
    await openWithOpener();
    expect(dialog()?.getAttribute("aria-modal")).toBe("true");
    expect(dialog()?.getAttribute("aria-label")).toBe("Remove Portal 2?");
  });

  it("moves focus into the dialog when it opens", async () => {
    await openWithOpener();
    expect(document.activeElement).toBe(document.body.querySelector(".cd-modal"));
  });

  it("focuses the `initialFocus` element when given", async () => {
    await openWithOpener({ withInput: true, initialFocus: "#reason" });
    expect(document.activeElement).toBe(document.getElementById("reason"));
  });

  it("closes on Escape and puts focus back where it was", async () => {
    const { isOpen, opener, wrapper } = await openWithOpener();
    press("Escape");
    await wrapper.vm.$nextTick();
    expect(isOpen.value).toBeFalsy();
    expect(dialog()).toBeNull();
    expect(document.activeElement).toBe(opener);
  });

  it("closes when the backdrop is clicked", async () => {
    const { isOpen } = await openWithOpener();
    (document.body.querySelector(".cd-backdrop") as HTMLElement).click();
    expect(isOpen.value).toBeFalsy();
  });

  it("closes from the cancel button without confirming", async () => {
    const { isOpen, confirmed } = await openWithOpener();
    buttons()[1].click();
    expect(isOpen.value).toBeFalsy();
    expect(confirmed.value).toBe(0);
  });

  it("emits confirm from the confirm button and stays open for the caller to close", async () => {
    const { isOpen, confirmed } = await openWithOpener();
    buttons()[0].click();
    expect(confirmed.value).toBe(1);
    expect(isOpen.value).toBeTruthy();
  });

  describe("focus trap", () => {
    it("wraps Tab from the last button to the first", async () => {
      await openWithOpener();
      const [confirm, cancel] = buttons();
      cancel.focus();
      const event = press("Tab");
      expect(event.defaultPrevented).toBeTruthy();
      expect(document.activeElement).toBe(confirm);
    });

    it("wraps Shift+Tab from the first button to the last", async () => {
      await openWithOpener();
      const [confirm, cancel] = buttons();
      confirm.focus();
      const event = press("Tab", { shiftKey: true });
      expect(event.defaultPrevented).toBeTruthy();
      expect(document.activeElement).toBe(cancel);
    });

    it("leaves Tab alone between the first and last elements", async () => {
      await openWithOpener({ withInput: true });
      (document.getElementById("reason") as HTMLInputElement).focus();
      expect(press("Tab").defaultPrevented).toBeFalsy();
    });

    it("includes focusable elements from the slot", async () => {
      await openWithOpener({ withInput: true });
      const input = document.getElementById("reason") as HTMLInputElement;
      buttons()[1].focus();
      press("Tab");
      expect(document.activeElement).toBe(input);
    });

    it("skips the confirm button while it's disabled", async () => {
      await openWithOpener({ loading: true });
      const [confirm, cancel] = buttons();
      expect(confirm.disabled).toBeTruthy();
      cancel.focus();
      // Cancel is the only focusable element, so Tab stays on it.
      expect(press("Tab").defaultPrevented).toBeTruthy();
      expect(document.activeElement).toBe(cancel);
    });
  });

  it("shows the loading label while loading", async () => {
    await openWithOpener({ loading: true });
    expect(buttons()[0].textContent?.trim()).toBe("Removing…");
  });

  it("uses the primary style without the trash icon for the primary variant", async () => {
    await openWithOpener({ variant: "primary" });
    const [confirm] = buttons();
    expect(confirm.classList.contains("cd-btn-primary")).toBeTruthy();
    expect(confirm.querySelector("svg")).toBeNull();
  });

  it("asks to close when it unmounts while open", async () => {
    const { wrapper, isOpen } = await openWithOpener();
    wrapper.unmount();
    expect(isOpen.value).toBeFalsy();
  });
});
