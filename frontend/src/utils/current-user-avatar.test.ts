import { describe, it, expect, vi, beforeEach } from "vitest";
import { refreshCurrentUserAvatar } from "./current-user-avatar";

const { mockRequest, mockAuth } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown) => Promise<unknown>>(),
  mockAuth: {
    isAuthenticated: true,
    updateUser: vi.fn<(updates: Record<string, unknown>) => void>()
  }
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/stores/auth", () => ({
  useAuthStore: () => mockAuth
}));

describe("refreshCurrentUserAvatar", () => {
  beforeEach(() => {
    mockRequest.mockReset();
    mockAuth.updateUser.mockReset();
    mockAuth.isAuthenticated = true;
  });

  it("stores the avatar URL", async () => {
    mockRequest.mockResolvedValue({ currentUser: { id: "1", avatarUrl: "https://files.example/a.jpg" } });
    await refreshCurrentUserAvatar();
    expect(mockAuth.updateUser).toHaveBeenCalledWith({ avatarUrl: "https://files.example/a.jpg" });
  });

  it("stores null when the user has no avatar", async () => {
    mockRequest.mockResolvedValue({ currentUser: { id: "1", avatarUrl: null } });
    await refreshCurrentUserAvatar();
    expect(mockAuth.updateUser).toHaveBeenCalledWith({ avatarUrl: null });
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
});
