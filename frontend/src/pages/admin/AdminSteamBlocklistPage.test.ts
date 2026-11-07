import { describe, it, expect, vi, beforeEach } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { createMemoryHistory, createRouter } from "vue-router";
import AdminSteamBlocklistPage from "./AdminSteamBlocklistPage.vue";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockRequest } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>()
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/composables/useSnackbar", () => ({
  useSnackbar: () => ({ show: vi.fn<(text: string, type?: "success" | "error") => void>() })
}));

// ── Helpers ───────────────────────────────────────────────────────

async function mountAt(path: string) {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{ path: "/admin/steam-blocklist", component: AdminSteamBlocklistPage }]
  });
  await router.push(path);
  await router.isReady();
  const wrapper = mount(AdminSteamBlocklistPage, { global: { plugins: [router] } });
  await flushPromises();
  return { wrapper, router };
}

function inputs(wrapper: Awaited<ReturnType<typeof mountAt>>["wrapper"]) {
  return {
    name: wrapper.find<HTMLInputElement>('input[placeholder="Game name"]').element,
    appId: wrapper.find<HTMLInputElement>('input[placeholder="Steam App ID"]').element
  };
}

beforeEach(() => {
  mockRequest.mockReset();
  mockRequest.mockResolvedValue({ steamBlocklist: { nodes: [], pageInfo: { hasNextPage: false, endCursor: null } } });
});

// ── Tests ─────────────────────────────────────────────────────────

describe("AdminSteamBlocklistPage prefill", () => {
  it("starts empty without query params", async () => {
    const { wrapper } = await mountAt("/admin/steam-blocklist");
    expect(inputs(wrapper).name.value).toBe("");
    expect(inputs(wrapper).appId.value).toBe("");
  });

  it("prefills the form from ?name= and ?steamAppId=", async () => {
    const { wrapper } = await mountAt("/admin/steam-blocklist?name=Half-Life%20OST&steamAppId=12345");
    expect(inputs(wrapper).name.value).toBe("Half-Life OST");
    expect(inputs(wrapper).appId.value).toBe("12345");
  });

  it("ignores a steamAppId that isn't a positive integer", async () => {
    const { wrapper } = await mountAt("/admin/steam-blocklist?steamAppId=12abc");
    expect(inputs(wrapper).appId.value).toBe("");
  });

  it("clears the prefill params after adding the entry", async () => {
    mockRequest.mockResolvedValue({});
    const { wrapper, router } = await mountAt("/admin/steam-blocklist?name=Foo&steamAppId=12345");
    await wrapper.find("form").trigger("submit");
    await flushPromises();
    expect(mockRequest).toHaveBeenCalledWith(expect.anything(), { name: "Foo", steamAppId: 12345 });
    expect(router.currentRoute.value.query).toEqual({});
  });
});
