import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { REVIEW_DRAFT_KEY_PREFIX, isTokenExpired, useAuthStore } from "./auth";

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

  describe("stored tokens", () => {
    function tokenExpiringAt(exp: number) {
      const payload = btoa(JSON.stringify({ user_id: 1, exp })).replace(/=+$/, "");
      return `header.${payload}.signature`;
    }

    it("starts signed out when the stored token has expired", () => {
      localStorage.setItem("auth_token", tokenExpiringAt(Math.floor(Date.now() / 1000) - 60));
      localStorage.setItem("auth_user", JSON.stringify({ id: "1" }));

      const store = useAuthStore();

      expect(store.isAuthenticated).toBeFalsy();
      expect(store.user).toBeNull();
      expect(localStorage.getItem("auth_token")).toBeNull();
    });

    it("keeps a stored token that hasn't expired", () => {
      localStorage.setItem("auth_token", tokenExpiringAt(Math.floor(Date.now() / 1000) + 3600));

      expect(useAuthStore().isAuthenticated).toBeTruthy();
    });

    it("leaves tokens it can't read for the API to judge", () => {
      expect(isTokenExpired("not-a-jwt")).toBeFalsy();
      expect(isTokenExpired("a.!!!.c")).toBeFalsy();
    });
  });

  describe("other tabs", () => {
    it("follows a sign-out made in another tab", () => {
      const store = useAuthStore();
      store.setAuth("token", { id: "1", username: "user", email: "user@example.com", role: "MEMBER", slug: "user" });

      // What the other tab's clearAuth leaves behind, then the event it fires here.
      localStorage.removeItem("auth_token");
      localStorage.removeItem("auth_user");
      window.dispatchEvent(new StorageEvent("storage", { key: "auth_token", newValue: null }));

      expect(store.isAuthenticated).toBeFalsy();
      expect(store.user).toBeNull();
    });
  });
});
