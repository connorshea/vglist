import { describe, it, expect, vi, beforeEach } from "vitest";
import { defineComponent, reactive, nextTick } from "vue";
import { mount, flushPromises } from "@vue/test-utils";
import { GET_USER_FOLLOWERS } from "@/graphql/queries/users";
import type { GetUserFollowersQuery } from "@/types/graphql";
import { FOLLOW_LIST_PAGE_SIZE, useFollowList } from "./useFollowList";

const { mockRequest, route, push } = vi.hoisted(() => {
  const route: { query: Record<string, string> } = { query: {} };
  return {
    mockRequest: vi.fn<(...args: unknown[]) => Promise<unknown>>(),
    route,
    push: vi.fn<(location: unknown) => Promise<void>>()
  };
});

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("vue-router", () => ({
  useRoute: () => route,
  useRouter: () => ({ push })
}));

function followersResult(ids: string[], hasNextPage: boolean): GetUserFollowersQuery {
  return {
    user: {
      id: "1",
      username: "connor",
      followers: {
        totalCount: 100,
        nodes: ids.map((id) => ({ id, username: `user${id}`, slug: `user${id}`, avatarUrl: null })),
        pageInfo: { hasNextPage, endCursor: null }
      }
    }
  };
}

function mountFollowers() {
  let result: ReturnType<typeof useFollowList<GetUserFollowersQuery>> | null = null;
  mount(
    defineComponent({
      setup() {
        result = useFollowList<GetUserFollowersQuery>(GET_USER_FOLLOWERS, {
          slug: () => "connor",
          select: (data) => data.user?.followers
        });
        return () => null;
      }
    })
  );
  return result!;
}

describe("useFollowList", () => {
  beforeEach(() => {
    route.query = reactive({});
    mockRequest.mockReset();
    push.mockReset();
  });

  it("loads the first page when the URL has no page", async () => {
    mockRequest.mockResolvedValue(followersResult(["2", "3"], true));
    const list = mountFollowers();
    await flushPromises();

    expect(mockRequest).toHaveBeenCalledWith(GET_USER_FOLLOWERS, {
      slug: "connor",
      first: FOLLOW_LIST_PAGE_SIZE,
      after: null
    });
    expect(list.users.value.map((u) => u.id)).toEqual(["2", "3"]);
    expect(list.page.value).toBe(1);
    expect(list.hasNextPage.value).toBeTruthy();
  });

  it("starts at the right offset for the page in the URL", async () => {
    route.query = reactive({ page: "3" });
    mockRequest.mockResolvedValue(followersResult(["9"], false));
    const list = mountFollowers();
    await flushPromises();

    // Page 3 starts after 2 pages, i.e. offset 96 → Base64 "96".
    expect(mockRequest).toHaveBeenCalledWith(GET_USER_FOLLOWERS, {
      slug: "connor",
      first: FOLLOW_LIST_PAGE_SIZE,
      after: btoa(String(FOLLOW_LIST_PAGE_SIZE * 2)).replace(/=+$/, "")
    });
    expect(list.page.value).toBe(3);
    expect(list.hasNextPage.value).toBeFalsy();
  });

  it("refetches when the page in the URL changes, e.g. on Back", async () => {
    route.query = reactive({ page: "2" });
    mockRequest.mockResolvedValue(followersResult(["5"], true));
    mountFollowers();
    await flushPromises();
    mockRequest.mockClear();

    delete route.query.page;
    await nextTick();
    await flushPromises();

    expect(mockRequest).toHaveBeenCalledWith(GET_USER_FOLLOWERS, {
      slug: "connor",
      first: FOLLOW_LIST_PAGE_SIZE,
      after: null
    });
  });
});
