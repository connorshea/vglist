import { describe, it, expect, beforeEach } from "vitest";
import { computed, defineComponent, h, nextTick, ref } from "vue";
import { mount, flushPromises } from "@vue/test-utils";
import { createMemoryHistory, createRouter, RouterView, useRoute, type Router } from "vue-router";
import { formatPageTitle, installPageTitles, usePageTitle } from "./usePageTitle";

describe("formatPageTitle", () => {
  it("appends the site name", () => {
    expect(formatPageTitle("Hollow Knight")).toBe("Hollow Knight | vglist");
  });

  it("falls back to the site name when there is no title", () => {
    expect(formatPageTitle(undefined)).toBe("vglist");
    expect(formatPageTitle(null)).toBe("vglist");
    expect(formatPageTitle("  ")).toBe("vglist");
  });
});

// Stand-in for loaded records: the page "loads" its name when told to.
const names = ref<Record<string, string>>({});

const StaticPage = defineComponent({ render: () => h("div", "static") });

const GamePage = defineComponent({
  setup() {
    const route = useRoute();
    const name = computed(() => names.value["id" in route.params ? route.params.id : ""]);
    usePageTitle(name);
    return () => h("div", name.value ?? "Loading…");
  }
});

function buildRouter(): Router {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/", component: StaticPage },
      { path: "/games", component: StaticPage, meta: { title: "Games" } },
      { path: "/games/:id", component: GamePage }
    ]
  });
  installPageTitles(router);
  return router;
}

async function mountAt(path: string): Promise<Router> {
  const router = buildRouter();
  await router.push(path);
  await router.isReady();
  mount(RouterView, { global: { plugins: [router] } });
  await flushPromises();
  return router;
}

describe("page titles", () => {
  beforeEach(() => {
    names.value = {};
    document.title = "stale";
  });

  it("uses the site name alone on the home page", async () => {
    await mountAt("/");
    expect(document.title).toBe("vglist");
  });

  it("uses the route's meta title", async () => {
    await mountAt("/games");
    expect(document.title).toBe("Games | vglist");
  });

  it("shows the site name while loading, then the record's name", async () => {
    await mountAt("/games/1");
    expect(document.title).toBe("vglist");

    names.value = { "1": "Hollow Knight" };
    await nextTick();
    expect(document.title).toBe("Hollow Knight | vglist");
  });

  it("updates when the params change on the same component", async () => {
    names.value = { "1": "Hollow Knight" };
    const router = await mountAt("/games/1");
    expect(document.title).toBe("Hollow Knight | vglist");

    await router.push("/games/2");
    await flushPromises();
    expect(document.title).toBe("vglist");

    names.value = { ...names.value, "2": "Celeste" };
    await nextTick();
    expect(document.title).toBe("Celeste | vglist");
  });

  it("keeps a data-driven title when only the query changes", async () => {
    names.value = { "1": "Hollow Knight" };
    const router = await mountAt("/games/1");

    await router.push("/games/1?sort=name");
    await flushPromises();
    expect(document.title).toBe("Hollow Knight | vglist");
  });

  it("replaces a data-driven title when leaving for a static page", async () => {
    names.value = { "1": "Hollow Knight" };
    const router = await mountAt("/games/1");

    await router.push("/games");
    await flushPromises();
    expect(document.title).toBe("Games | vglist");
  });
});

describe("page titles that depend on the route", () => {
  // Like the user profile layout: one parent whose title depends on which
  // child (tab) route is showing.
  const ProfileLayout = defineComponent({
    setup() {
      const route = useRoute();
      usePageTitle(() => `connor's ${String(route.meta.tab)}`);
      return () => h(RouterView);
    }
  });

  function buildProfileRouter(): Router {
    const router = createRouter({
      history: createMemoryHistory(),
      routes: [
        {
          path: "/users/connor",
          component: ProfileLayout,
          children: [
            { path: "library", component: StaticPage, meta: { tab: "Library" } },
            { path: "favorites", component: StaticPage, meta: { tab: "Favorites" } }
          ]
        },
        { path: "/games", component: StaticPage, meta: { title: "Games" } }
      ]
    });
    installPageTitles(router);
    return router;
  }

  it("updates on tab changes and doesn't overwrite the next page's title on leaving", async () => {
    const router = buildProfileRouter();
    await router.push("/users/connor/library");
    await router.isReady();
    mount(RouterView, { global: { plugins: [router] } });
    await flushPromises();
    expect(document.title).toBe("connor's Library | vglist");

    await router.push("/users/connor/favorites");
    await flushPromises();
    expect(document.title).toBe("connor's Favorites | vglist");

    await router.push("/games");
    await flushPromises();
    expect(document.title).toBe("Games | vglist");
  });
});
