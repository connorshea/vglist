import { describe, it, expect, vi, beforeEach } from "vitest";
import { createPinia, setActivePinia } from "pinia";

import router from "./index";

describe("router", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    // jsdom doesn't implement scrolling; the router's scrollBehavior calls it.
    vi.spyOn(window, "scrollTo").mockImplementation(() => {});
  });

  describe("/search (OpenSearch target)", () => {
    it("shows the results page with the query, rather than redirecting", async () => {
      await router.push("/search?query=hollow%20knight");

      expect(router.currentRoute.value.name).toBe("search");
      expect(router.currentRoute.value.query).toEqual({ query: "hollow knight" });
    });

    it("shows the results page when there's no query", async () => {
      await router.push("/search");

      expect(router.currentRoute.value.name).toBe("search");
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
