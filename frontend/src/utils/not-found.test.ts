import { describe, expect, it } from "vitest";
import { createMemoryHistory, createRouter } from "vue-router";
import { defineComponent } from "vue";
import { notFoundLocation } from "./not-found";

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
