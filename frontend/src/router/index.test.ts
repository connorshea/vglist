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

  describe("/stores/:id", () => {
    it("sends old store links to the stores list without a discarded-param warning", async () => {
      const warn = vi.spyOn(console, "warn").mockImplementation(() => {});

      await router.push("/stores/1");

      expect(router.currentRoute.value.name).toBe("stores");
      expect(router.currentRoute.value.fullPath).toBe("/stores");
      expect(warn).not.toHaveBeenCalledWith(expect.stringContaining("Discarded invalid param"));
      warn.mockRestore();
    });
  });
});
