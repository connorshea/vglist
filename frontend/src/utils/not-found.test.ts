import { describe, expect, it } from "vitest";
import { createMemoryHistory, createRouter } from "vue-router";
import { defineComponent } from "vue";
import { notFoundLocation, searchQueryFromPath } from "./not-found";

const Empty = defineComponent({ render: () => null });

function makeRouter() {
  return createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/", name: "home", component: Empty },
      { path: "/games/:id", name: "game", component: Empty },
      { path: "/:pathMatch(.*)*", name: "notFound", component: Empty }
    ]
  });
}

describe("notFoundLocation", () => {
  it("keeps the current URL when showing the 404 page", async () => {
    const router = makeRouter();
    await router.push("/games/99999999?sort=name#reviews");

    await router.replace(notFoundLocation(router.currentRoute.value));

    const current = router.currentRoute.value;
    expect(current.name).toBe("notFound");
    expect(current.fullPath).toBe("/games/99999999?sort=name#reviews");
  });
});

describe("searchQueryFromPath", () => {
  it("turns the last path segment into words", () => {
    expect(searchQueryFromPath("/games/hollow-knight-silksongg")).toBe("hollow knight silksongg");
  });

  it("ignores a trailing slash", () => {
    expect(searchQueryFromPath("/series/final_fantasy/")).toBe("final fantasy");
  });

  it("decodes percent-encoding", () => {
    expect(searchQueryFromPath("/games/pok%C3%A9mon-red")).toBe("pokémon red");
  });

  it("keeps a malformed segment as typed", () => {
    expect(searchQueryFromPath("/games/100%-orange")).toBe("100% orange");
  });

  it("is empty for the root path or a numeric id", () => {
    expect(searchQueryFromPath("/")).toBe("");
    expect(searchQueryFromPath("/games/12345")).toBe("");
  });
});
