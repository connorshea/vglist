import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { defineComponent, reactive } from "vue";
import { enableAutoUnmount, mount } from "@vue/test-utils";
import { useCursorPages, withoutPage } from "./useCursorPages";

const { route, push } = vi.hoisted(() => {
  const route: { query: Record<string, string | string[]> } = { query: {} };
  return { route, push: vi.fn<(location: unknown) => Promise<void>>() };
});

vi.mock("vue-router", () => ({
  useRoute: () => route,
  useRouter: () => ({ push })
}));

enableAutoUnmount(afterEach);

function mountPages(pageSize = 10) {
  let result: ReturnType<typeof useCursorPages> | null = null;
  mount(
    defineComponent({
      setup() {
        result = useCursorPages(pageSize);
        return () => null;
      }
    })
  );
  return result!;
}

describe("withoutPage", () => {
  it("drops the page and both cursors, keeping everything else", () => {
    expect(withoutPage({ page: "3", after: "a", before: "b", feed: "global" })).toEqual({ feed: "global" });
  });

  it("doesn't change the query it was given", () => {
    const query = { page: "2", after: "a" };
    withoutPage(query);
    expect(query).toEqual({ page: "2", after: "a" });
  });
});

describe("useCursorPages", () => {
  beforeEach(() => {
    route.query = reactive({});
    push.mockReset();
  });

  describe("reading the URL", () => {
    it("is the first page, fetched from the start, when there's no cursor", () => {
      const pages = mountPages(10);
      expect(pages.currentPage.value).toBe(1);
      expect(pages.variables.value).toEqual({ first: 10, after: null, last: null, before: null });
    });

    it("ignores a page number without a cursor", () => {
      route.query = reactive({ page: "4" });
      const pages = mountPages();
      expect(pages.currentPage.value).toBe(1);
      expect(pages.variables.value.after).toBeNull();
    });

    it("fetches forward from an `after` cursor", () => {
      route.query = reactive({ page: "3", after: "c2" });
      const pages = mountPages(10);
      expect(pages.currentPage.value).toBe(3);
      expect(pages.variables.value).toEqual({ first: 10, after: "c2", last: null, before: null });
    });

    it("fetches backward from a `before` cursor", () => {
      route.query = reactive({ page: "2", before: "c3" });
      const pages = mountPages(10);
      expect(pages.currentPage.value).toBe(2);
      expect(pages.variables.value).toEqual({ first: null, after: null, last: 10, before: "c3" });
    });

    it("prefers `after` when both cursors are in the URL", () => {
      route.query = reactive({ page: "3", after: "a", before: "b" });
      expect(mountPages(10).variables.value).toEqual({ first: 10, after: "a", last: null, before: null });
    });

    it.each(["", "abc", "1", "0", "-2", "2.5"])("treats page=%j with a cursor as page 2", (page) => {
      route.query = reactive({ page, after: "a" });
      expect(mountPages().currentPage.value).toBe(2);
    });

    it("ignores repeated cursor parameters", () => {
      route.query = reactive({ page: "3", after: ["a", "b"] });
      const pages = mountPages();
      expect(pages.currentPage.value).toBe(1);
      expect(pages.variables.value.after).toBeNull();
    });
  });

  describe("nextPage", () => {
    it("pushes the next page after the end cursor, keeping other parameters", () => {
      route.query = reactive({ feed: "global" });
      mountPages().nextPage("end1");
      expect(push).toHaveBeenCalledWith({ query: { feed: "global", page: "2", after: "end1" } });
    });

    it("replaces a `before` cursor with the new `after` one", () => {
      route.query = reactive({ page: "3", before: "b" });
      mountPages().nextPage("end3");
      expect(push).toHaveBeenCalledWith({ query: { page: "4", after: "end3" } });
    });

    it.each([null, undefined, ""])("does nothing without an end cursor (%j)", (cursor) => {
      mountPages().nextPage(cursor);
      expect(push).not.toHaveBeenCalled();
    });
  });

  describe("prevPage", () => {
    it("does nothing on the first page", () => {
      mountPages().prevPage("start");
      expect(push).not.toHaveBeenCalled();
    });

    it("goes back to the bare list from page 2", () => {
      route.query = reactive({ page: "2", after: "a", feed: "global" });
      mountPages().prevPage("start2");
      expect(push).toHaveBeenCalledWith({ query: { feed: "global" } });
    });

    it("pushes the previous page before the start cursor", () => {
      route.query = reactive({ page: "4", after: "a" });
      mountPages().prevPage("start4");
      expect(push).toHaveBeenCalledWith({ query: { page: "3", before: "start4" } });
    });

    it("falls back to the first page without a start cursor", () => {
      route.query = reactive({ page: "4", after: "a" });
      mountPages().prevPage(null);
      expect(push).toHaveBeenCalledWith({ query: {} });
    });
  });
});
