import { defineStore } from "pinia";
import { ref, computed } from "vue";
import type { UserRole } from "@/types/graphql";
import { clearQueryCache } from "@/graphql/query-cache";
import { safeLocalStorage } from "@/utils/safe-storage";

export const REVIEW_DRAFT_KEY_PREFIX = "vglist-review-draft-";

interface AuthUser {
  id: string;
  username: string;
  email: string;
  role: UserRole;
  slug: string;
  // The small (80px) avatar for the navbar, or null when the user has none.
  // Loaded after sign-in by refreshCurrentUserAvatar(), so it can be missing.
  avatarUrl?: string | null;
  // When avatarUrl was last fetched (ms since the epoch), so the navbar can
  // skip re-fetching it on every page load. See refreshCurrentUserAvatar().
  avatarCheckedAt?: number;
}

function loadStoredUser(): AuthUser | null {
  try {
    return JSON.parse(safeLocalStorage.getItem("auth_user") || "null");
  } catch {
    safeLocalStorage.removeItem("auth_user");
    return null;
  }
}

// Whether a JWT's `exp` claim has passed. Only the payload is read; the
// signature is the API's business. A token that can't be read is left for the
// API to reject (see REJECTED_TOKEN_HEADER in graphql/client.ts).
export function isTokenExpired(token: string, now = Date.now()): boolean {
  const payload = token.split(".")[1];
  if (!payload) {
    return false;
  }
  try {
    const base64 = payload.replace(/-/g, "+").replace(/_/g, "/");
    const { exp } = JSON.parse(atob(base64)) as { exp?: unknown };
    return typeof exp === "number" && exp * 1000 <= now;
  } catch {
    return false;
  }
}

// Unsaved review text from GameLibraryForm shouldn't survive sign-out on a
// shared machine.
function clearReviewDrafts() {
  const draftKeys = safeLocalStorage.keys().filter((key) => key.startsWith(REVIEW_DRAFT_KEY_PREFIX));
  for (const key of draftKeys) {
    safeLocalStorage.removeItem(key);
  }
}

export const useAuthStore = defineStore("auth", () => {
  const token = ref(safeLocalStorage.getItem("auth_token"));
  const user = ref(loadStoredUser());

  const isAuthenticated = computed(() => token.value !== null);
  const isAdmin = computed(() => user.value?.role === "ADMIN");
  const isModerator = computed(() => user.value?.role === "MODERATOR" || user.value?.role === "ADMIN");

  // Cached query results can depend on who was signed in (library status,
  // private profiles, moderator-only fields), so neither sign-in nor sign-out
  // may show the previous viewer's.
  function setAuth(newToken: string, newUser: AuthUser) {
    clearQueryCache();
    token.value = newToken;
    user.value = newUser;
    safeLocalStorage.setItem("auth_token", newToken);
    safeLocalStorage.setItem("auth_user", JSON.stringify(newUser));
  }

  function clearAuth() {
    clearQueryCache();
    token.value = null;
    user.value = null;
    safeLocalStorage.removeItem("auth_token");
    safeLocalStorage.removeItem("auth_user");
    clearReviewDrafts();
  }

  function updateUser(updates: Partial<AuthUser>) {
    if (user.value) {
      user.value = { ...user.value, ...updates };
      safeLocalStorage.setItem("auth_user", JSON.stringify(user.value));
    }
  }

  // The API rejected `sentToken` (expired, or revoked by signing out or
  // changing the password elsewhere) and treated the request as signed out.
  // Only sign out if it's still the current token: the user may have signed
  // in again while that request was in flight.
  function handleRejectedToken(sentToken: string) {
    if (token.value === sentToken) {
      clearAuth();
    }
  }

  // A stored token that has already expired would only be rejected, so start
  // signed out instead of showing the user as signed in.
  if (token.value && isTokenExpired(token.value)) {
    clearAuth();
  }

  // Keep tabs in step: signing in or out in one tab updates the others.
  // `storage` events only fire in the tabs that didn't make the change.
  if (typeof window !== "undefined") {
    window.addEventListener("storage", (event) => {
      if (event.key !== null && event.key !== "auth_token" && event.key !== "auth_user") {
        return;
      }
      const storedToken = safeLocalStorage.getItem("auth_token");
      if (storedToken !== token.value) {
        clearQueryCache();
        token.value = storedToken;
      }
      user.value = storedToken ? loadStoredUser() : null;
    });
  }

  return {
    token,
    user,
    isAuthenticated,
    isAdmin,
    isModerator,
    setAuth,
    clearAuth,
    handleRejectedToken,
    updateUser
  };
});
