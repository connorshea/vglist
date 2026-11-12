import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { AVATAR_REFRESH_INTERVAL_MS, refreshCurrentUserAvatar } from "./current-user-avatar";

const { mockRequest, mockAuth } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown) => Promise<unknown>>(),
  mockAuth: {
    isAuthenticated: true,
    user: null as { avatarCheckedAt?: number } | null,
    updateUser: vi.fn<(updates: Record<string, unknown>) => void>()
  }
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/stores/auth", () => ({
  useAuthStore: () => mockAuth
}));

const NOW = new Date("2026-11-12T00:00:00Z").getTime();

describe("refreshCurrentUserAvatar", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(NOW);
    mockRequest.mockReset();
    mockAuth.updateUser.mockReset();
    mockAuth.isAuthenticated = true;
    mockAuth.user = {};
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("stores the avatar URL and when it was checked", async () => {
    mockRequest.mockResolvedValue({ currentUser: { id: "1", avatarUrl: "https://files.example/a.jpg" } });
    await refreshCurrentUserAvatar();
    expect(mockAuth.updateUser).toHaveBeenCalledWith({
      avatarUrl: "https://files.example/a.jpg",
      avatarCheckedAt: NOW
    });
  });

  it("stores null when the user has no avatar", async () => {
    mockRequest.mockResolvedValue({ currentUser: { id: "1", avatarUrl: null } });
    await refreshCurrentUserAvatar();
    expect(mockAuth.updateUser).toHaveBeenCalledWith({ avatarUrl: null, avatarCheckedAt: NOW });
  });

  it("does nothing when signed out", async () => {
    mockAuth.isAuthenticated = false;
    await refreshCurrentUserAvatar();
    expect(mockRequest).not.toHaveBeenCalled();
    expect(mockAuth.updateUser).not.toHaveBeenCalled();
  });

  it("keeps the current avatar when the request fails", async () => {
    mockRequest.mockRejectedValue(new Error("network"));
    await refreshCurrentUserAvatar();
    expect(mockAuth.updateUser).not.toHaveBeenCalled();
  });

  it("skips the request when the avatar was checked recently", async () => {
    mockAuth.user = { avatarCheckedAt: NOW - AVATAR_REFRESH_INTERVAL_MS + 1000 };
    await refreshCurrentUserAvatar();
    expect(mockRequest).not.toHaveBeenCalled();
  });

  it("checks again once the avatar is old enough", async () => {
    mockAuth.user = { avatarCheckedAt: NOW - AVATAR_REFRESH_INTERVAL_MS };
    mockRequest.mockResolvedValue({ currentUser: { id: "1", avatarUrl: null } });
    await refreshCurrentUserAvatar();
    expect(mockRequest).toHaveBeenCalledTimes(1);
  });

  it("always checks when forced", async () => {
    mockAuth.user = { avatarCheckedAt: NOW };
    mockRequest.mockResolvedValue({ currentUser: { id: "1", avatarUrl: "https://files.example/b.jpg" } });
    await refreshCurrentUserAvatar({ force: true });
    expect(mockAuth.updateUser).toHaveBeenCalledWith({
      avatarUrl: "https://files.example/b.jpg",
      avatarCheckedAt: NOW
    });
  });
});
