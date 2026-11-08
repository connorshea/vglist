import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mount, flushPromises, type VueWrapper } from "@vue/test-utils";
import { nextTick } from "vue";
import SearchOverlay from "./SearchOverlay.vue";

// ── Hoisted mocks (available to vi.mock factories) ─────────────────

const { pushMock, mockIsOpen, mockClose, mockRequest, mockInitialQuery } = vi.hoisted(() => {
  const _isOpen = { value: false };
  return {
    // What takeInitialQuery() hands the overlay the next time it opens.
    mockInitialQuery: { value: "" },
    pushMock: vi.fn<() => void>(),
    mockIsOpen: _isOpen,
    // close() is a simple spy; it does NOT toggle isOpen to avoid
    // mid-test Vue re-renders that conflict with DOM teardown.
    mockClose: vi.fn<() => void>(),
    mockRequest: vi.fn<() => Promise<unknown>>()
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
      close: mockClose,
      takeInitialQuery: () => {
        const query = mockInitialQuery.value;
        mockInitialQuery.value = "";
        return query;
      }
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
async function mountWithSearchResults(results: Record<string, unknown>[], query = "test"): Promise<VueWrapper> {
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
    mockInitialQuery.value = "";
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
      expect(wrapper.find(".search-overlay").exists()).toBeFalsy();
    });

    it("renders the overlay when isOpen is true", async () => {
      mockIsOpen.value = true;
      await nextTick();

      const wrapper = mountOverlay();
      expect(wrapper.find(".search-overlay").exists()).toBeTruthy();
      expect(wrapper.find('[role="dialog"]').exists()).toBeTruthy();
      expect(wrapper.find(".search-input").exists()).toBeTruthy();
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

    it("starts searching for the query it was opened with", async () => {
      mockRequest.mockResolvedValueOnce({ globalSearch: { nodes: [] } });
      const wrapper = mountOverlay();

      mockInitialQuery.value = "hollow";
      mockIsOpen.value = true;
      await nextTick();
      await nextTick();

      expect((wrapper.find(".search-input").element as HTMLInputElement).value).toBe("hollow");
      await vi.advanceTimersByTimeAsync(300);
      expect(mockRequest).toHaveBeenCalledWith("GLOBAL_SEARCH_QUERY", { query: "hollow" });
    });

    it("starts searching when it mounts already open (e.g. from /search)", async () => {
      mockRequest.mockResolvedValueOnce({ globalSearch: { nodes: [] } });
      mockInitialQuery.value = "celeste";
      mockIsOpen.value = true;

      const wrapper = mountOverlay();
      await nextTick();

      expect((wrapper.find(".search-input").element as HTMLInputElement).value).toBe("celeste");
      await vi.advanceTimersByTimeAsync(300);
      expect(mockRequest).toHaveBeenCalledWith("GLOBAL_SEARCH_QUERY", { query: "celeste" });
    });
  });

  // ── 3. Escape key closes the overlay ──

  describe("escape key", () => {
    it("calls close when Escape is pressed", async () => {
      mountOverlay();

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
      expect(resultItem.exists()).toBeTruthy();
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
      expect(resultItem.exists()).toBeTruthy();
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
      expect(resultLink.exists()).toBeTruthy();
      expect(resultLink.attributes("href")).toBe("/platforms/5");
    });
  });

  // ── 5b. Keyboard navigation through results ──

  describe("keyboard navigation", () => {
    // Shown as Games, then Companies, then Users, regardless of API order.
    const results = [
      { searchableId: "7", searchableType: "USER", content: "valvefan", slug: "valvefan", avatarUrl: null },
      {
        searchableId: "1",
        searchableType: "GAME",
        content: "Half-Life",
        coverUrl: null,
        developerName: null,
        releaseDate: null
      },
      { searchableId: "3", searchableType: "COMPANY", content: "Valve" }
    ];

    function activeTitle(wrapper: VueWrapper): string {
      return wrapper.find(".result-item.is-active .result-title").text();
    }

    it("highlights the first result when results arrive", async () => {
      const wrapper = await mountWithSearchResults(results, "valve");
      expect(wrapper.findAll(".result-item.is-active")).toHaveLength(1);
      expect(activeTitle(wrapper)).toBe("Half-Life");
    });

    it("moves the highlight with Down and Up in display order, wrapping at the ends", async () => {
      const wrapper = await mountWithSearchResults(results, "valve");
      const input = wrapper.find(".search-input");

      await input.trigger("keydown", { key: "ArrowDown" });
      expect(activeTitle(wrapper)).toBe("Valve");
      await input.trigger("keydown", { key: "ArrowDown" });
      expect(activeTitle(wrapper)).toBe("valvefan");
      await input.trigger("keydown", { key: "ArrowDown" });
      expect(activeTitle(wrapper)).toBe("Half-Life");
      await input.trigger("keydown", { key: "ArrowUp" });
      expect(activeTitle(wrapper)).toBe("valvefan");
    });

    it("opens the highlighted result on Enter", async () => {
      const wrapper = await mountWithSearchResults(results, "valve");
      const input = wrapper.find(".search-input");

      await input.trigger("keydown", { key: "ArrowDown" });
      await input.trigger("keydown", { key: "Enter" });

      expect(pushMock).toHaveBeenCalledWith("/companies/3");
      expect(mockClose).toHaveBeenCalled();
    });

    it("opens the first result on Enter without moving", async () => {
      const wrapper = await mountWithSearchResults(results, "valve");
      await wrapper.find(".search-input").trigger("keydown", { key: "Enter" });
      expect(pushMock).toHaveBeenCalledWith("/games/1");
    });

    it("follows the mouse", async () => {
      const wrapper = await mountWithSearchResults(results, "valve");
      await wrapper.findAll(".result-item")[2].trigger("mousemove");
      expect(activeTitle(wrapper)).toBe("valvefan");
    });

    it("does nothing on Enter when there are no results", async () => {
      const wrapper = await mountWithSearchResults([], "nothing");
      await wrapper.find(".search-input").trigger("keydown", { key: "Enter" });
      expect(pushMock).not.toHaveBeenCalled();
    });

    it("exposes the results as a listbox the input points into", async () => {
      const wrapper = await mountWithSearchResults(results, "valve");
      const input = wrapper.find(".search-input");

      expect(input.attributes("role")).toBe("combobox");
      expect(input.attributes("aria-expanded")).toBe("true");
      const listbox = wrapper.find('[role="listbox"]');
      expect(input.attributes("aria-controls")).toBe(listbox.attributes("id"));
      expect(wrapper.findAll('[role="group"]').map((group) => group.attributes("aria-label"))).toEqual([
        "Games",
        "Companies",
        "Users"
      ]);

      const options = wrapper.findAll('[role="option"]');
      expect(options).toHaveLength(3);
      expect(input.attributes("aria-activedescendant")).toBe(options[0].attributes("id"));
      expect(options.map((option) => option.attributes("aria-selected"))).toEqual(["true", "false", "false"]);

      await input.trigger("keydown", { key: "ArrowDown" });
      expect(input.attributes("aria-activedescendant")).toBe(options[1].attributes("id"));
      expect(options[1].attributes("aria-selected")).toBe("true");
      expect(options[0].attributes("aria-selected")).toBe("false");
    });

    it("has no active descendant and isn't expanded without results", async () => {
      const wrapper = await mountWithSearchResults([], "nothing");
      const input = wrapper.find(".search-input");
      expect(input.attributes("aria-expanded")).toBe("false");
      expect(input.attributes("aria-activedescendant")).toBeUndefined();
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

  // ── Out-of-order and late responses ──

  describe("stale responses", () => {
    function game(id: string, content: string) {
      return {
        searchableId: id,
        searchableType: "GAME",
        content,
        coverUrl: null,
        developerName: null,
        releaseDate: null
      };
    }

    function deferred() {
      let resolve: (value: unknown) => void = () => {};
      const promise = new Promise<unknown>((r) => {
        resolve = r;
      });
      return { promise, resolve };
    }

    async function openAndMount(): Promise<VueWrapper> {
      mockIsOpen.value = true;
      await nextTick();
      const wrapper = mountOverlay();
      await nextTick();
      return wrapper;
    }

    async function type(wrapper: VueWrapper, value: string) {
      const input = wrapper.find(".search-input");
      await input.setValue(value);
      await input.trigger("input");
    }

    function titles(wrapper: VueWrapper): string[] {
      return wrapper.findAll(".result-title").map((title) => title.text());
    }

    it("ignores a response for an older query that arrives after a newer one", async () => {
      const older = deferred();
      const newer = deferred();
      mockRequest.mockReturnValueOnce(older.promise).mockReturnValueOnce(newer.promise);
      const wrapper = await openAndMount();

      await type(wrapper, "hal");
      await vi.advanceTimersByTimeAsync(300);
      await type(wrapper, "halo");
      await vi.advanceTimersByTimeAsync(300);
      expect(mockRequest).toHaveBeenCalledTimes(2);

      newer.resolve({ globalSearch: { nodes: [game("2", "Halo 3")] } });
      await flushPromises();
      older.resolve({ globalSearch: { nodes: [game("1", "Half-Life")] } });
      await flushPromises();

      expect(titles(wrapper)).toEqual(["Halo 3"]);
    });

    it("doesn't keep a response that lands after it closes for the next search", async () => {
      const pending = deferred();
      mockRequest.mockReturnValueOnce(pending.promise);
      const wrapper = await openAndMount();

      await type(wrapper, "halo");
      await vi.advanceTimersByTimeAsync(300);

      mockIsOpen.value = false;
      await nextTick();
      pending.resolve({ globalSearch: { nodes: [game("2", "Halo 3")] } });
      await flushPromises();

      // Reopen and start a new search: until its debounce fires, nothing from
      // the closed search should show (or be opened by Enter).
      mockIsOpen.value = true;
      await flushPromises();
      await type(wrapper, "zelda");
      expect(titles(wrapper)).toEqual([]);
    });

    it("opens the new query's top hit on Enter pressed before the debounce fires", async () => {
      const wrapper = await mountWithSearchResults([game("1", "Half-Life")], "hal");
      mockRequest.mockResolvedValueOnce({ globalSearch: { nodes: [game("2", "Halo 3")] } });

      await type(wrapper, "halo");
      await wrapper.find(".search-input").trigger("keydown", { key: "Enter" });
      await flushPromises();

      expect(mockRequest).toHaveBeenLastCalledWith("GLOBAL_SEARCH_QUERY", { query: "halo" });
      expect(pushMock).toHaveBeenCalledTimes(1);
      expect(pushMock).toHaveBeenCalledWith("/games/2");
    });

    it("opens the new query's top hit on Enter pressed while its search is in flight", async () => {
      const wrapper = await mountWithSearchResults([game("1", "Half-Life")], "hal");
      const pending = deferred();
      mockRequest.mockReturnValueOnce(pending.promise);

      await type(wrapper, "halo");
      await vi.advanceTimersByTimeAsync(300);
      await wrapper.find(".search-input").trigger("keydown", { key: "Enter" });
      await flushPromises();
      expect(pushMock).not.toHaveBeenCalled();

      pending.resolve({ globalSearch: { nodes: [game("2", "Halo 3")] } });
      await flushPromises();
      expect(pushMock).toHaveBeenCalledTimes(1);
      expect(pushMock).toHaveBeenCalledWith("/games/2");
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

  // ── Results page entry points ──

  describe("results page", () => {
    const game = (id: string, content: string) => ({
      searchableId: id,
      searchableType: "GAME",
      content,
      coverUrl: null,
      developerName: null,
      releaseDate: null
    });

    it("goes straight to the result when Enter is pressed with exactly one result", async () => {
      const wrapper = await mountWithSearchResults([game("7", "Portal")], "portal");

      await wrapper.find(".search-input").trigger("keydown", { key: "Enter" });

      expect(pushMock).toHaveBeenCalledWith("/games/7");
      expect(mockClose).toHaveBeenCalled();
    });

    it("does nothing on Enter when the query is too short", async () => {
      mockIsOpen.value = true;
      await nextTick();
      const wrapper = mountOverlay();
      await nextTick();

      const input = wrapper.find(".search-input");
      await input.setValue("a");
      await input.trigger("keydown", { key: "Enter" });

      expect(pushMock).not.toHaveBeenCalled();
      expect(wrapper.find(".see-all-results").exists()).toBeFalsy();
    });

    it("offers a See all results button that opens the results page", async () => {
      const wrapper = await mountWithSearchResults([game("7", "Portal")], "portal");

      const button = wrapper.find(".see-all-results");
      expect(button.text()).toContain('See all results for "portal"');

      await button.trigger("click");

      expect(pushMock).toHaveBeenCalledWith({ name: "search", query: { query: "portal" } });
      expect(mockClose).toHaveBeenCalled();
    });

    it("ignores Enter while an input method is composing", async () => {
      const wrapper = await mountWithSearchResults([game("1", "ファイナル"), game("2", "ファイナル2")], "ファイ");

      await wrapper.find(".search-input").trigger("keydown", { key: "Enter", isComposing: true });

      expect(pushMock).not.toHaveBeenCalled();
    });

    it("searches, gates, and navigates with the same trimmed query", async () => {
      const wrapper = await mountWithSearchResults([game("7", "Portal")], " portal  ");

      expect(mockRequest).toHaveBeenCalledWith("GLOBAL_SEARCH_QUERY", { query: "portal" });

      // Results for "portal" are current for " portal  ", so Enter opens the one result.
      await wrapper.find(".search-input").trigger("keydown", { key: "Enter" });
      expect(pushMock).toHaveBeenCalledWith("/games/7");
    });

    it("doesn't search for a query that's only long enough with spaces", async () => {
      mockIsOpen.value = true;
      await nextTick();
      const wrapper = mountOverlay();
      await nextTick();

      const input = wrapper.find(".search-input");
      await input.setValue("a ");
      await input.trigger("input");
      await vi.advanceTimersByTimeAsync(300);

      expect(mockRequest).not.toHaveBeenCalled();
    });

    it("shows the API's error message rather than the raw response", async () => {
      mockRequest.mockRejectedValueOnce(
        Object.assign(new Error('{"response":{"errors":[{"message":"query is too long"}]}}'), {
          response: { errors: [{ message: "query is too long" }] }
        })
      );
      mockIsOpen.value = true;
      await nextTick();
      const wrapper = mountOverlay();
      await nextTick();

      const input = wrapper.find(".search-input");
      await input.setValue("portal");
      await input.trigger("input");
      await vi.advanceTimersByTimeAsync(300);
      await flushPromises();

      expect(wrapper.find(".search-error-text").text()).toBe("Search failed: query is too long");
    });
  });
});
