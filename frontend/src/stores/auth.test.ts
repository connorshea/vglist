import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { REVIEW_DRAFT_KEY_PREFIX, useAuthStore } from "./auth";

describe("useAuthStore", () => {
  beforeEach(() => {
    localStorage.clear();
    setActivePinia(createPinia());
  });

  describe("clearAuth", () => {
    it("removes the token, user, and any review drafts", () => {
      const store = useAuthStore();
      store.setAuth("token", { id: "1", username: "user", email: "user@example.com", role: "MEMBER", slug: "user" });
      localStorage.setItem(`${REVIEW_DRAFT_KEY_PREFIX}1`, "draft one");
      localStorage.setItem(`${REVIEW_DRAFT_KEY_PREFIX}2`, "draft two");
      localStorage.setItem("unrelated", "keep me");

      store.clearAuth();

      expect(store.isAuthenticated).toBeFalsy();
      expect(localStorage.getItem("auth_token")).toBeNull();
      expect(localStorage.getItem("auth_user")).toBeNull();
      expect(localStorage.getItem(`${REVIEW_DRAFT_KEY_PREFIX}1`)).toBeNull();
      expect(localStorage.getItem(`${REVIEW_DRAFT_KEY_PREFIX}2`)).toBeNull();
      expect(localStorage.getItem("unrelated")).toBe("keep me");
    });
  });
});
