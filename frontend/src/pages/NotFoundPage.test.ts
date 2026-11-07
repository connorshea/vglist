import { describe, it, expect, beforeEach, vi } from "vitest";
import { mount, flushPromises, RouterLinkStub } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { createMemoryHistory, createRouter } from "vue-router";
import { defineComponent } from "vue";
import NotFoundPage from "./NotFoundPage.vue";
import { useAuthStore } from "@/stores/auth";

const { openSearch } = vi.hoisted(() => ({ openSearch: vi.fn<(query?: string) => void>() }));
vi.mock("@/composables/useSearchOverlay", () => ({
  useSearchOverlay: () => ({ open: openSearch })
}));

const Empty = defineComponent({ render: () => null });

async function mountAt(path: string) {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/", name: "home", component: Empty },
      { path: "/games", name: "games", component: Empty },
      { path: "/activity", name: "activity", component: Empty },
      { path: "/users/:slug/library", name: "userLibrary", component: Empty },
      { path: "/:pathMatch(.*)*", name: "notFound", component: NotFoundPage }
    ]
  });
  await router.push(path);
  await router.isReady();
  const wrapper = mount(NotFoundPage, {
    global: { plugins: [router], stubs: { RouterLink: RouterLinkStub } }
  });
  return { wrapper, router };
}

function linkTexts(wrapper: Awaited<ReturnType<typeof mountAt>>["wrapper"]) {
  return wrapper.findAllComponents(RouterLinkStub).map((link) => link.text());
}

describe("NotFoundPage", () => {
  beforeEach(() => {
    localStorage.clear();
    setActivePinia(createPinia());
    openSearch.mockReset();
  });

  it("renders the heading and the missing path", async () => {
    const { wrapper } = await mountAt("/games/hollow-knight-silksongg");
    expect(wrapper.find("h1").text()).toBe("This one’s not on the shelf");
    expect(wrapper.find(".not-found-path").text()).toBe("/games/hollow-knight-silksongg");
  });

  it("prefills the search box from the path", async () => {
    const { wrapper } = await mountAt("/games/hollow-knight-silksongg");
    const input = wrapper.find<HTMLInputElement>("input[type=search]");
    expect(input.element.value).toBe("hollow knight silksongg");
    expect(wrapper.find('label[for="not-found-query"]').text()).toBe("Search games");
  });

  it("opens the search overlay with the query on submit", async () => {
    const { wrapper } = await mountAt("/games/hollow-knight-silksongg");
    await wrapper.find("input[type=search]").setValue("  silksong ");
    await wrapper.find("form").trigger("submit");
    expect(openSearch).toHaveBeenCalledWith("silksong");
  });

  it("refills the search box when another missing path reuses the page", async () => {
    const { wrapper, router } = await mountAt("/games/first-missing");
    await router.push("/series/second-missing");
    await flushPromises();
    expect(wrapper.find<HTMLInputElement>("input[type=search]").element.value).toBe("second missing");
  });

  it("links to Home, Games and Activity when signed out", async () => {
    const { wrapper } = await mountAt("/nope");
    expect(linkTexts(wrapper)).toEqual(["Home", "Games", "Activity"]);
  });

  it("adds a link to the viewer's library when signed in", async () => {
    useAuthStore().setAuth("token", {
      id: "1",
      username: "Connor",
      email: "c@example.com",
      role: "MEMBER",
      slug: "connor"
    });
    const { wrapper } = await mountAt("/nope");
    expect(linkTexts(wrapper)).toEqual(["Home", "Games", "Your library", "Activity"]);
    const library = wrapper.findAllComponents(RouterLinkStub)[2];
    expect(library.props("to")).toEqual({ name: "userLibrary", params: { slug: "connor" } });
  });

  it("hides the decorative cover slot from assistive technology", async () => {
    const { wrapper } = await mountAt("/nope");
    expect(wrapper.find(".not-found-slot").attributes("aria-hidden")).toBe("true");
  });
});
