import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mount, flushPromises, RouterLinkStub, enableAutoUnmount } from "@vue/test-utils";
import SteamImportBanner from "./SteamImportBanner.vue";

interface MockAuth {
  isAuthenticated: boolean;
  user: { id: string } | null;
}

const { mockRequest, auth } = vi.hoisted(() => {
  const auth: MockAuth = { isAuthenticated: true, user: { id: "7" } };
  return {
    mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>(),
    auth
  };
});

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/stores/auth", () => ({
  useAuthStore: () => auth
}));

const DISMISSED_KEY = "vglist-steam-import-banner-dismissed-7";

function currentUser(overrides: { steamProfileUrl?: string | null; gamesCount?: number } = {}) {
  return {
    currentUser: {
      id: "7",
      steamProfileUrl: overrides.steamProfileUrl ?? null,
      gamePurchases: { totalCount: overrides.gamesCount ?? 0 }
    }
  };
}

async function mountBanner() {
  const wrapper = mount(SteamImportBanner, { global: { stubs: { RouterLink: RouterLinkStub } } });
  await flushPromises();
  return wrapper;
}

enableAutoUnmount(afterEach);

describe("SteamImportBanner", () => {
  beforeEach(() => {
    mockRequest.mockReset();
    localStorage.clear();
    auth.isAuthenticated = true;
    auth.user = { id: "7" };
  });

  it("points a new user with an empty library to the Steam import", async () => {
    mockRequest.mockResolvedValue(currentUser());
    const wrapper = await mountBanner();

    expect(wrapper.find("aside").exists()).toBeTruthy();
    expect(wrapper.findComponent(RouterLinkStub).props("to")).toEqual({ name: "settingsImport" });
  });

  it("stays hidden once the library has games", async () => {
    mockRequest.mockResolvedValue(currentUser({ gamesCount: 3 }));
    const wrapper = await mountBanner();
    expect(wrapper.find("aside").exists()).toBeFalsy();
  });

  it("stays hidden once Steam is connected", async () => {
    mockRequest.mockResolvedValue(currentUser({ steamProfileUrl: "https://steamcommunity.com/id/someone" }));
    const wrapper = await mountBanner();
    expect(wrapper.find("aside").exists()).toBeFalsy();
  });

  it("goes away when dismissed, and stays dismissed for that user", async () => {
    mockRequest.mockResolvedValue(currentUser());
    const wrapper = await mountBanner();

    await wrapper.find("button[aria-label='Dismiss']").trigger("click");
    expect(wrapper.find("aside").exists()).toBeFalsy();
    expect(localStorage.getItem(DISMISSED_KEY)).not.toBeNull();

    mockRequest.mockClear();
    const remounted = await mountBanner();
    expect(remounted.find("aside").exists()).toBeFalsy();
    expect(mockRequest).not.toHaveBeenCalled();
  });

  it("still shows for another user on the same browser", async () => {
    localStorage.setItem(DISMISSED_KEY, "2026-11-15T00:00:00Z");
    auth.user = { id: "8" };
    mockRequest.mockResolvedValue(currentUser());
    const wrapper = await mountBanner();
    expect(wrapper.find("aside").exists()).toBeTruthy();
  });

  it("asks nothing of a signed-out visitor", async () => {
    auth.isAuthenticated = false;
    auth.user = null;
    const wrapper = await mountBanner();
    expect(wrapper.find("aside").exists()).toBeFalsy();
    expect(mockRequest).not.toHaveBeenCalled();
  });
});
