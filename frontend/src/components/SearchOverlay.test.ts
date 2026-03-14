import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mount, flushPromises, VueWrapper } from "@vue/test-utils";
import { nextTick } from "vue";
import SearchOverlay from "./SearchOverlay.vue";

// ── Hoisted mocks (available to vi.mock factories) ─────────────────

const { pushMock, mockIsOpen, mockClose, mockRequest } = vi.hoisted(() => {
  const _isOpen = { value: false };
  return {
    pushMock: vi.fn(),
    mockIsOpen: _isOpen,
    // close() is a simple spy; it does NOT toggle isOpen to avoid
    // mid-test Vue re-renders that conflict with DOM teardown.
    mockClose: vi.fn(),
    mockRequest: vi.fn()
  };
});

vi.mock("vue-router", () => ({
  useRouter: () => ({ push: pushMock })
}));

vi.mock("@/composables/useSearchOverlay", async () => {
  const { ref } = await import("vue");
  const realRef = ref(false);
  Object.defineProperty(mockIsOpen, "value", {
    get: () => realRef.value,
    set: (v: boolean) => {
      realRef.value = v;
    },
    configurable: true
  });
  return {
    useSearchOverlay: () => ({
      isOpen: realRef,
      close: mockClose
    })
  };
});

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/graphql/queries/resources", () => ({
  GLOBAL_SEARCH: "GLOBAL_SEARCH_QUERY"
}));

// ── Helpers ────────────────────────────────────────────────────────

// Track all mounted wrappers so we can unmount them before resetting state.
let activeWrappers: VueWrapper[] = [];

function mountOverlay() {
  const wrapper = mount(SearchOverlay, {
    global: {
      stubs: {
        Teleport: true
      }
    }
  });
  activeWrappers.push(wrapper);
  return wrapper;
}

/**
 * Opens the overlay, types a query, waits for debounce, and returns wrapper
 * with search results rendered.
 */
async function mountWithSearchResults(
  results: Record<string, unknown>[],
  query = "test"
): Promise<VueWrapper> {
  mockRequest.mockResolvedValueOnce({
    globalSearch: { nodes: results }
  });

  mockIsOpen.value = true;
  await nextTick();

  const wrapper = mountOverlay();
  await nextTick();

  const input = wrapper.find(".search-input");
  await input.setValue(query);
  await input.trigger("input");

  // Advance past the 250ms debounce
  await vi.advanceTimersByTimeAsync(300);
  await flushPromises();
  await nextTick();

  return wrapper;
}

// ── Tests ──────────────────────────────────────────────────────────

describe("SearchOverlay", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    mockIsOpen.value = false;
    mockClose.mockClear();
    pushMock.mockClear();
    mockRequest.mockReset();
    activeWrappers = [];
  });

  afterEach(async () => {
    // Unmount all wrappers FIRST, so their watchers stop reacting.
    for (const w of activeWrappers) {
      w.unmount();
    }
    activeWrappers = [];
    // Now safe to reset shared state.
    mockIsOpen.value = false;
    vi.useRealTimers();
  });

  // ── 1. Rendering based on isOpen ──

  describe("rendering", () => {
    it("does not render the overlay when isOpen is false", () => {
      const wrapper = mountOverlay();
      expect(wrapper.find(".search-overlay").exists()).toBe(false);
    });

    it("renders the overlay when isOpen is true", async () => {
      mockIsOpen.value = true;
      await nextTick();

      const wrapper = mountOverlay();
      expect(wrapper.find(".search-overlay").exists()).toBe(true);
      expect(wrapper.find('[role="dialog"]').exists()).toBe(true);
      expect(wrapper.find(".search-input").exists()).toBe(true);
    });

    it("renders the search input with correct placeholder", async () => {
      mockIsOpen.value = true;
      await nextTick();

      const wrapper = mountOverlay();
      const input = wrapper.find(".search-input");
      expect(input.attributes("placeholder")).toContain("Search games");
    });
  });

  // ── 2. Focus behavior ──

  describe("focus behavior", () => {
    it("focuses the search input when the overlay opens", async () => {
      const wrapper = mountOverlay();

      // Attach the wrapper's root element to document so jsdom focus works.
      const container = document.createElement("div");
      document.body.appendChild(container);
      container.appendChild(wrapper.element);

      mockIsOpen.value = true;
      await nextTick();
      // The watch handler itself does `await nextTick()` then `.focus()`.
      await nextTick();

      const input = wrapper.find(".search-input").element as HTMLInputElement;
      expect(document.activeElement).toBe(input);

      document.body.removeChild(container);
    });
  });

  // ── 3. Escape key closes the overlay ──

  describe("escape key", () => {
    it("calls close when Escape is pressed", async () => {
      const wrapper = mountOverlay();

      mockIsOpen.value = true;
      await nextTick();
      await nextTick();

      // Reset mock call count from any setup-phase invocations.
      mockClose.mockClear();

      document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));

      expect(mockClose).toHaveBeenCalledTimes(1);
    });
  });

  // ── 4. Search results are categorized correctly ──

  describe("result categorization", () => {
    const mixedResults = [
      {
        searchableId: "1",
        searchableType: "GAME",
        content: "Half-Life 2",
        coverUrl: null,
        developerName: "Valve",
        releaseDate: "2004-11-16"
      },
      {
        searchableId: "2",
        searchableType: "USER",
        content: "testuser",
        slug: "testuser",
        avatarUrl: null
      },
      {
        searchableId: "3",
        searchableType: "COMPANY",
        content: "Valve Corporation"
      },
      {
        searchableId: "4",
        searchableType: "PLATFORM",
        content: "PC"
      },
      {
        searchableId: "5",
        searchableType: "ENGINE",
        content: "Source Engine"
      }
    ];

    it("groups results into games, users, companies, platforms, and other categories", async () => {
      const wrapper = await mountWithSearchResults(mixedResults, "half");

      const categoryTitles = wrapper.findAll(".category-title").map((el) => el.text());
      expect(categoryTitles).toContain("Games");
      expect(categoryTitles).toContain("Users");
      expect(categoryTitles).toContain("Companies");
      expect(categoryTitles).toContain("Platforms");
      expect(categoryTitles).toContain("Other");

      const categories = wrapper.findAll(".category");

      const gamesCategory = categories.find((c) => c.find(".category-title").text() === "Games");
      expect(gamesCategory).toBeDefined();
      expect(gamesCategory!.find(".result-title").text()).toBe("Half-Life 2");

      const usersCategory = categories.find((c) => c.find(".category-title").text() === "Users");
      expect(usersCategory).toBeDefined();
      expect(usersCategory!.find(".result-title").text()).toBe("testuser");

      const otherCategory = categories.find((c) => c.find(".category-title").text() === "Other");
      expect(otherCategory).toBeDefined();
      expect(otherCategory!.find(".result-title").text()).toBe("Source Engine");
    });
  });

  // ── 5. goToResult navigates correctly ──

  describe("goToResult navigation", () => {
    it("navigates to /games/:id for a game result", async () => {
      const wrapper = await mountWithSearchResults(
        [
          {
            searchableId: "42",
            searchableType: "GAME",
            content: "Portal",
            coverUrl: null,
            developerName: "Valve",
            releaseDate: "2007-10-10"
          }
        ],
        "portal"
      );

      const resultItem = wrapper.find(".result-item");
      expect(resultItem.exists()).toBe(true);
      await resultItem.trigger("click");

      expect(pushMock).toHaveBeenCalledWith("/games/42");
      expect(mockClose).toHaveBeenCalled();
    });

    it("uses slug instead of searchableId for user results", async () => {
      const wrapper = await mountWithSearchResults(
        [
          {
            searchableId: "99",
            searchableType: "USER",
            content: "janedoe",
            slug: "janedoe-slug",
            avatarUrl: null
          }
        ],
        "jane"
      );

      const resultItem = wrapper.find(".result-item");
      expect(resultItem.exists()).toBe(true);
      await resultItem.trigger("click");

      expect(pushMock).toHaveBeenCalledWith("/users/janedoe-slug");
      expect(pushMock).not.toHaveBeenCalledWith("/users/99");
    });

    it("navigates to /companies/:id for company results", async () => {
      const wrapper = await mountWithSearchResults(
        [{ searchableId: "10", searchableType: "COMPANY", content: "Nintendo" }],
        "nintendo"
      );

      await wrapper.find(".result-item").trigger("click");
      expect(pushMock).toHaveBeenCalledWith("/companies/10");
    });

    it("sets correct href on platform result links", async () => {
      const wrapper = await mountWithSearchResults(
        [{ searchableId: "5", searchableType: "PLATFORM", content: "Nintendo Switch" }],
        "switch"
      );

      const resultLink = wrapper.find(".result-item");
      expect(resultLink.exists()).toBe(true);
      expect(resultLink.attributes("href")).toBe("/platforms/5");
    });
  });

  // ── 6. Debounce behavior ──

  describe("debounce behavior", () => {
    it("does not call the API immediately on input", async () => {
      mockIsOpen.value = true;
      await nextTick();

      const wrapper = mountOverlay();
      await nextTick();

      await wrapper.find(".search-input").setValue("test");
      await wrapper.find(".search-input").trigger("input");

      // debounce is 250ms, so no call should have been made yet
      expect(mockRequest).not.toHaveBeenCalled();
    });

    it("calls the API after the 250ms debounce period", async () => {
      mockRequest.mockResolvedValueOnce({ globalSearch: { nodes: [] } });

      mockIsOpen.value = true;
      await nextTick();

      const wrapper = mountOverlay();
      await nextTick();

      await wrapper.find(".search-input").setValue("test");
      await wrapper.find(".search-input").trigger("input");

      await vi.advanceTimersByTimeAsync(300);
      await flushPromises();

      expect(mockRequest).toHaveBeenCalledTimes(1);
    });

    it("only fires one API call when typing rapidly within the debounce window", async () => {
      mockRequest.mockResolvedValue({ globalSearch: { nodes: [] } });

      mockIsOpen.value = true;
      await nextTick();

      const wrapper = mountOverlay();
      await nextTick();

      const input = wrapper.find(".search-input");

      await input.setValue("te");
      await input.trigger("input");
      await vi.advanceTimersByTimeAsync(100);

      await input.setValue("tes");
      await input.trigger("input");
      await vi.advanceTimersByTimeAsync(100);

      await input.setValue("test");
      await input.trigger("input");
      await vi.advanceTimersByTimeAsync(300);

      await flushPromises();

      expect(mockRequest).toHaveBeenCalledTimes(1);
    });

    it("does not call the API when query is shorter than 2 characters", async () => {
      mockIsOpen.value = true;
      await nextTick();

      const wrapper = mountOverlay();
      await nextTick();

      await wrapper.find(".search-input").setValue("a");
      await wrapper.find(".search-input").trigger("input");

      await vi.advanceTimersByTimeAsync(300);
      await flushPromises();

      expect(mockRequest).not.toHaveBeenCalled();
    });
  });

  // ── Additional edge cases ──

  describe("empty and loading states", () => {
    it("shows the empty state prompt when no query is entered", async () => {
      mockIsOpen.value = true;
      await nextTick();

      const wrapper = mountOverlay();
      expect(wrapper.text()).toContain("Start typing to search");
    });

    it("shows no results message after a search with zero results", async () => {
      const wrapper = await mountWithSearchResults([], "xyznonexistent");
      expect(wrapper.text()).toContain("No results found");
    });
  });

  describe("closing behavior", () => {
    it("calls close when the overlay backdrop is clicked", async () => {
      mockIsOpen.value = true;
      await nextTick();

      const wrapper = mountOverlay();
      await nextTick();
      mockClose.mockClear();

      await wrapper.find(".search-overlay").trigger("click");
      expect(mockClose).toHaveBeenCalled();
    });

    it("calls close when the close button is clicked", async () => {
      mockIsOpen.value = true;
      await nextTick();

      const wrapper = mountOverlay();
      await nextTick();
      mockClose.mockClear();

      await wrapper.find(".search-close").trigger("click");
      expect(mockClose).toHaveBeenCalled();
    });
  });
});
