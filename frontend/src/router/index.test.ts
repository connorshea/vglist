import { describe, it, expect, vi, beforeEach } from "vitest";
import { createPinia, setActivePinia } from "pinia";

const { openSearch } = vi.hoisted(() => ({ openSearch: vi.fn<(query?: string) => void>() }));

vi.mock("@/composables/useSearchOverlay", () => ({
  useSearchOverlay: () => ({ open: openSearch })
}));

import router from "./index";

describe("router", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    // jsdom doesn't implement scrolling; the router's scrollBehavior calls it.
    vi.spyOn(window, "scrollTo").mockImplementation(() => {});
    openSearch.mockClear();
  });

  describe("/search (OpenSearch target)", () => {
    it("opens the search overlay with the query and lands on the home page", async () => {
      await router.push("/search?query=hollow%20knight");

      expect(openSearch).toHaveBeenCalledWith("hollow knight");
      expect(router.currentRoute.value.name).toBe("home");
      expect(router.currentRoute.value.query).toEqual({});
    });

    it("opens an empty overlay when there's no query", async () => {
      await router.push("/search");

      expect(openSearch).toHaveBeenCalledWith("");
      expect(router.currentRoute.value.name).toBe("home");
    });
  });
});
