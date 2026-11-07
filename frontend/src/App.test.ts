import { describe, it, expect, vi, afterEach } from "vitest";
import { mount, flushPromises, type VueWrapper } from "@vue/test-utils";
import { defineComponent } from "vue";
import { createRouter, createMemoryHistory, type Router } from "vue-router";
import App from "./App.vue";

const toggleSearch = vi.fn<() => void>();

vi.mock("@/composables/useSearchOverlay", () => ({
  useSearchOverlay: () => ({ toggle: toggleSearch })
}));

vi.mock("@/composables/useSnackbar", () => ({
  useSnackbar: () => ({ show: vi.fn<() => void>() })
}));

const Page = defineComponent({ template: "<p class='page'>page</p>" });

function makeRouter(): Router {
  return createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/", component: Page },
      { path: "/login", component: Page, meta: { layout: "bare" } }
    ]
  });
}

async function mountAt(path: string): Promise<VueWrapper> {
  const router = makeRouter();
  await router.push(path);
  await router.isReady();
  const wrapper = mount(App, {
    attachTo: document.body,
    global: {
      plugins: [router],
      stubs: {
        NavBar: { template: "<nav class='navbar-stub' />" },
        SearchOverlay: { template: "<div class='search-overlay-stub' />" },
        SnackbarContainer: { template: "<div class='snackbar-stub' />" }
      }
    }
  });
  await flushPromises();
  return wrapper;
}

describe("App layout", () => {
  let wrapper: VueWrapper | undefined;

  afterEach(() => {
    wrapper?.unmount();
    wrapper = undefined;
    toggleSearch.mockClear();
  });

  it("renders the navbar and section/container wrapper by default", async () => {
    wrapper = await mountAt("/");
    expect(wrapper.find(".navbar-stub").exists()).toBeTruthy();
    expect(wrapper.find("main.section > .container > .page").exists()).toBeTruthy();
  });

  it("skips the navbar and wrapper on bare routes", async () => {
    wrapper = await mountAt("/login");
    expect(wrapper.find(".navbar-stub").exists()).toBeFalsy();
    expect(wrapper.find("main.section").exists()).toBeFalsy();
    expect(wrapper.find(".container").exists()).toBeFalsy();
    // Still a <main> landmark for the page content.
    expect(wrapper.find("main#main-content > .page").exists()).toBeTruthy();
  });

  it("renders a skip link as the first focusable element that focuses <main>", async () => {
    wrapper = await mountAt("/");
    const first = wrapper.element.querySelector("a, button, input, [tabindex]:not([tabindex='-1'])");
    expect(first?.textContent).toBe("Skip to main content");
    await wrapper.get("a.skip-link").trigger("click");
    expect(document.activeElement?.id).toBe("main-content");
  });

  it("keeps the global search overlay, snackbars and Cmd/Ctrl+K on bare routes", async () => {
    wrapper = await mountAt("/login");
    expect(wrapper.find(".search-overlay-stub").exists()).toBeTruthy();
    expect(wrapper.find(".snackbar-stub").exists()).toBeTruthy();

    document.dispatchEvent(new KeyboardEvent("keydown", { key: "k", ctrlKey: true }));
    expect(toggleSearch).toHaveBeenCalledTimes(1);
  });
});
