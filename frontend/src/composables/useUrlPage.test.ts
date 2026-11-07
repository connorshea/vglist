import { describe, it, expect, vi, beforeEach } from "vitest";
import { defineComponent, reactive } from "vue";
import { mount } from "@vue/test-utils";
import { useUrlPage } from "./useUrlPage";

const { route, push } = vi.hoisted(() => {
  const route: { query: Record<string, string | string[]> } = { query: {} };
  return { route, push: vi.fn<(location: unknown) => Promise<void>>() };
});

vi.mock("vue-router", () => ({
  useRoute: () => route,
  useRouter: () => ({ push })
}));

function mountPage() {
  let result: ReturnType<typeof useUrlPage> | null = null;
  mount(
    defineComponent({
      setup() {
        result = useUrlPage();
        return () => null;
      }
    })
  );
  return result!;
}

describe("useUrlPage", () => {
  beforeEach(() => {
    route.query = reactive({});
    push.mockReset();
  });

  it("is page 1 when the URL has no page", () => {
    expect(mountPage().page.value).toBe(1);
  });

  it("reads the page from the URL", () => {
    route.query = reactive({ page: "3" });
    expect(mountPage().page.value).toBe(3);
  });

  it("pushes the next page onto the history, keeping other query parameters", () => {
    route.query = reactive({ page: "2", sort: "name" });
    mountPage().goToPage(3);
    expect(push).toHaveBeenCalledWith({ query: { page: "3", sort: "name" } });
  });

  it("leaves page 1 out of the URL", () => {
    route.query = reactive({ page: "2", sort: "name" });
    mountPage().goToPage(1);
    expect(push).toHaveBeenCalledWith({ query: { sort: "name" } });
  });
});
