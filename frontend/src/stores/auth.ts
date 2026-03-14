import { defineStore } from "pinia";
import { ref, computed } from "vue";
import type { UserRole } from "@/types";

interface AuthUser {
  id: string;
  username: string;
  email: string;
  role: UserRole;
  slug: string;
}

function loadStoredUser(): AuthUser | null {
  try {
    return JSON.parse(localStorage.getItem("auth_user") || "null");
  } catch {
    localStorage.removeItem("auth_user");
    return null;
  }
}

export const useAuthStore = defineStore("auth", () => {
  const token = ref<string | null>(localStorage.getItem("auth_token"));
  const user = ref<AuthUser | null>(loadStoredUser());

  const isAuthenticated = computed(() => token.value !== null);
  const isAdmin = computed(() => user.value?.role === "admin");
  const isModerator = computed(
    () => user.value?.role === "moderator" || user.value?.role === "admin"
  );

  function setAuth(newToken: string, newUser: AuthUser) {
    token.value = newToken;
    user.value = newUser;
    localStorage.setItem("auth_token", newToken);
    localStorage.setItem("auth_user", JSON.stringify(newUser));
  }

  function clearAuth() {
    token.value = null;
    user.value = null;
    localStorage.removeItem("auth_token");
    localStorage.removeItem("auth_user");
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
