import { defineStore } from "pinia";
import { ref, computed } from "vue";
import type { UserRole } from "@/types/graphql";
import { clearQueryCache } from "@/graphql/query-cache";

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
    return JSON.parse(localStorage.getItem("auth_user") || "null");
  } catch {
    localStorage.removeItem("auth_user");
    return null;
  }
}

// Unsaved review text from GameLibraryForm shouldn't survive sign-out on a
// shared machine.
function clearReviewDrafts() {
  const draftKeys = Object.keys(localStorage).filter((key) => key.startsWith(REVIEW_DRAFT_KEY_PREFIX));
  for (const key of draftKeys) {
    localStorage.removeItem(key);
  }
}

export const useAuthStore = defineStore("auth", () => {
  const token = ref(localStorage.getItem("auth_token"));
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
    localStorage.setItem("auth_token", newToken);
    localStorage.setItem("auth_user", JSON.stringify(newUser));
  }

  function clearAuth() {
    clearQueryCache();
    token.value = null;
    user.value = null;
    localStorage.removeItem("auth_token");
    localStorage.removeItem("auth_user");
    clearReviewDrafts();
  }

  function updateUser(updates: Partial<AuthUser>) {
    if (user.value) {
      user.value = { ...user.value, ...updates };
      localStorage.setItem("auth_user", JSON.stringify(user.value));
    }
  }

  return {
    token,
    user,
    isAuthenticated,
    isAdmin,
    isModerator,
    setAuth,
    clearAuth,
    updateUser
  };
});
