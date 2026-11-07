import { describe, it, expect, vi } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import { createMemoryHistory, createRouter } from "vue-router";
import UserComparePage from "./UserComparePage.vue";
import { GET_LIBRARY_COMPARISON } from "@/graphql/queries/compare";

// The page with a real router, since switching tabs is a navigation that a
// mocked `useRoute` can't reproduce.

const { mockRequest } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>()
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/stores/auth", () => ({
  useAuthStore: () => ({ isAuthenticated: true, user: { id: "1", slug: "connorshea" } })
}));

const SUMMARY = {
  libraryComparison: {
    userA: { id: "1", username: "connorshea", slug: "connorshea", avatarUrl: null },
    userB: { id: "2", username: "kestrel", slug: "kestrel", avatarUrl: null },
    inCommonCount: 1,
    onlyACount: 0,
    onlyBCount: 0,
    bothRatedCount: 0,
    averageRatingGap: null,
    onlyA: { nodes: [] },
    onlyB: { nodes: [] }
  }
};

const EMPTY_LIST = { totalCount: 0, pageInfo: { hasNextPage: false, endCursor: null }, nodes: [] };

describe("UserComparePage with a real router", () => {
  it("keeps the search and doesn't refetch the header when switching tabs", async () => {
    mockRequest.mockImplementation((query) =>
      Promise.resolve(
        query === GET_LIBRARY_COMPARISON
          ? SUMMARY
          : { libraryComparison: { inCommon: EMPTY_LIST, onlyA: EMPTY_LIST, onlyB: EMPTY_LIST } }
      )
    );

    const router = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: "/users/:slug/compare/:otherSlug", name: "userCompare", component: UserComparePage },
        { path: "/games/:id", name: "game", component: { template: "<div />" } },
        { path: "/users/:slug", name: "user", component: { template: "<div />" } }
      ]
    });
    await router.push("/users/connorshea/compare/kestrel?tab=common");
    const wrapper = mount({ template: "<router-view />" }, { global: { plugins: [router] } });
    await flushPromises();

    await wrapper.find('input[type="search"]').setValue("zelda");
    await router.push("/users/connorshea/compare/kestrel");
    await router.push("/users/connorshea/compare/kestrel?tab=common");
    await flushPromises();

    expect(mockRequest.mock.calls.filter(([query]) => query === GET_LIBRARY_COMPARISON)).toHaveLength(1);
    expect((wrapper.find('input[type="search"]').element as HTMLInputElement).value).toBe("zelda");
  });
});
