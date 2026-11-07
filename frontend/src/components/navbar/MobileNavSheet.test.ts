import { describe, it, expect, vi, afterEach } from "vitest";
import { mount, flushPromises, type VueWrapper } from "@vue/test-utils";
import { defineComponent, h, ref } from "vue";
import { createPinia } from "pinia";
import { createMemoryHistory, createRouter } from "vue-router";
import MobileNavSheet from "./MobileNavSheet.vue";

vi.mock("@/composables/useAuth", () => ({
  useAuth: () => ({ signOut: vi.fn<() => void>() })
}));

const isOpen = ref(false);

// The sheet plus a stand-in for the navbar button that opens it.
const Harness = defineComponent({
  setup() {
    return () => [
      h("button", { class: "opener", onClick: () => (isOpen.value = true) }, "Menu"),
      h(MobileNavSheet, { isOpen: isOpen.value, onClose: () => (isOpen.value = false) })
    ];
  }
});

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  isOpen.value = false;
  document.body.innerHTML = "";
});

async function mountSheet(): Promise<HTMLElement> {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{ path: "/:pathMatch(.*)*", component: { render: () => null } }]
  });
  await router.push("/");
  await router.isReady();
  wrapper = mount(Harness, { attachTo: document.body, global: { plugins: [createPinia(), router] } });
  await flushPromises();
  return document.getElementById("mobile-nav-sheet")!;
}

describe("MobileNavSheet", () => {
  it("is a modal dialog that is inert while closed", async () => {
    const sheet = await mountSheet();
    expect(sheet.getAttribute("role")).toBe("dialog");
    expect(sheet.getAttribute("aria-modal")).toBe("true");
    expect(sheet.hasAttribute("inert")).toBeTruthy();

    isOpen.value = true;
    await flushPromises();
    expect(sheet.hasAttribute("inert")).toBeFalsy();
  });

  it("moves focus into the sheet on open and back to the opener on close", async () => {
    const sheet = await mountSheet();
    const opener = document.querySelector<HTMLElement>(".opener")!;
    opener.focus();
    opener.click();
    await flushPromises();
    expect(document.activeElement).toBe(sheet);

    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
    await flushPromises();
    expect(isOpen.value).toBeFalsy();
    expect(document.activeElement).toBe(opener);
  });

  it("wraps Tab from the last item back to the first", async () => {
    const sheet = await mountSheet();
    isOpen.value = true;
    await flushPromises();
    const items = sheet.querySelectorAll<HTMLElement>("a[href], button");
    const first = items[0];
    const last = items[items.length - 1];

    last.focus();
    last.dispatchEvent(new KeyboardEvent("keydown", { key: "Tab", bubbles: true }));
    expect(document.activeElement).toBe(first);

    first.dispatchEvent(new KeyboardEvent("keydown", { key: "Tab", shiftKey: true, bubbles: true }));
    expect(document.activeElement).toBe(last);
  });
});
