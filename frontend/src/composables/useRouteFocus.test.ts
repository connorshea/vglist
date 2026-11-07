import { describe, it, expect, afterEach } from "vitest";
import { defineComponent, h } from "vue";
import { mount, flushPromises, type VueWrapper } from "@vue/test-utils";
import { createMemoryHistory, createRouter, RouterView, type Router } from "vue-router";
import { installRouteFocus } from "./useRouteFocus";

const Page = defineComponent({ render: () => h("p", "page") });

const Shell = defineComponent({
  render: () => [
    h("button", { class: "trigger" }, "link"),
    h("main", { id: "main-content", tabindex: "-1" }, [h(RouterView)])
  ]
});

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

async function mountAt(path: string): Promise<Router> {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/", component: Page },
      { path: "/games", component: Page },
      { path: "/users", component: Page }
    ]
  });
  installRouteFocus(router);
  await router.push(path);
  await router.isReady();
  wrapper = mount(Shell, { attachTo: document.body, global: { plugins: [router] } });
  await flushPromises();
  return router;
}

function focusTrigger(): HTMLElement {
  const trigger = document.querySelector<HTMLElement>(".trigger")!;
  trigger.focus();
  return trigger;
}

describe("installRouteFocus", () => {
  it("leaves focus alone on the initial load", async () => {
    await mountAt("/");
    expect(document.activeElement).toBe(document.body);
  });

  it("moves focus to <main> after navigating to another page", async () => {
    const router = await mountAt("/");
    focusTrigger();
    await router.push("/games");
    await flushPromises();
    expect(document.activeElement?.id).toBe("main-content");
  });

  it("keeps focus where it is when only the query or hash changes", async () => {
    const router = await mountAt("/games");
    const trigger = focusTrigger();
    await router.push("/games?sort=name");
    await flushPromises();
    expect(document.activeElement).toBe(trigger);
    await router.push("/games?sort=name#top");
    await flushPromises();
    expect(document.activeElement).toBe(trigger);
  });
});
