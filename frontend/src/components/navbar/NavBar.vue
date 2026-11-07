<template>
  <nav class="navbar is-primary" role="navigation" aria-label="main navigation">
    <div class="navbar-brand">
      <router-link class="navbar-item" to="/">
        <img src="@/assets/images/vglist-logo.svg" alt="vglist" style="height: 24px" />
      </router-link>

      <!-- Mobile search button (to the left of hamburger) -->
      <button class="navbar-mobile-search is-hidden-desktop" aria-label="Search" @click="openSearch()">
        <Search :size="18" :stroke-width="1.8" />
      </button>

      <!-- Signed in: the avatar opens the bottom sheet (mobile only) -->
      <button
        v-if="authStore.isAuthenticated"
        type="button"
        class="navbar-mobile-avatar is-hidden-desktop"
        :aria-label="`Menu for ${username}`"
        aria-controls="mobile-nav-sheet"
        :aria-expanded="isSheetOpen"
        @click="isSheetOpen = !isSheetOpen"
      >
        <NavAvatar :username="username" :avatar-url="authStore.user?.avatarUrl" />
      </button>

      <!-- Signed out: hamburger (mobile only, opens bottom sheet) -->
      <button
        v-else
        type="button"
        class="navbar-burger"
        :class="{ 'is-active': isSheetOpen }"
        aria-label="Menu"
        aria-controls="mobile-nav-sheet"
        :aria-expanded="isSheetOpen"
        @click="isSheetOpen = !isSheetOpen"
      >
        <span aria-hidden="true"></span>
        <span aria-hidden="true"></span>
        <span aria-hidden="true"></span>
        <span aria-hidden="true"></span>
      </button>
    </div>

    <!-- Desktop menu (never toggled by burger anymore) -->
    <div class="navbar-menu">
      <div class="navbar-start">
        <router-link class="navbar-item" to="/activity">Activity</router-link>
        <router-link class="navbar-item" to="/games">Games</router-link>
        <router-link class="navbar-item" to="/users">Users</router-link>

        <NavDropdown>
          <template #trigger>More</template>
          <router-link class="nav-menu-item" to="/platforms">Platforms</router-link>
          <router-link class="nav-menu-item" to="/genres">Genres</router-link>
          <router-link class="nav-menu-item" to="/companies">Companies</router-link>
          <router-link class="nav-menu-item" to="/engines">Engines</router-link>
          <router-link class="nav-menu-item" to="/series">Series</router-link>
          <router-link class="nav-menu-item" to="/stores">Stores</router-link>
        </NavDropdown>
      </div>

      <div class="navbar-end">
        <div class="navbar-item">
          <NavSearch />
        </div>
        <template v-if="authStore.isAuthenticated">
          <NavDropdown class="navbar-user" align-right trigger-class="is-arrowless" menu-class="user-menu">
            <template #trigger>
              <span class="navbar-user-pill">
                <NavAvatar :username="username" :avatar-url="authStore.user?.avatarUrl" />
                <span class="navbar-user-name">{{ username }}</span>
                <ChevronDown class="navbar-user-chevron" :size="14" :stroke-width="2" />
              </span>
            </template>
            <router-link class="user-menu-header" :to="profilePath">
              <NavAvatar :username="username" :avatar-url="authStore.user?.avatarUrl" />
              <span class="user-menu-identity">
                <span class="user-menu-name">{{ username }}</span>
                <span class="user-menu-sub">View profile</span>
              </span>
            </router-link>
            <router-link class="nav-menu-item" :to="profilePath">
              <User :size="16" :stroke-width="1.8" />
              Profile
            </router-link>
            <router-link v-if="authStore.isAdmin" class="nav-menu-item" to="/admin">
              <Shield :size="16" :stroke-width="1.8" />
              Admin
            </router-link>
            <router-link class="nav-menu-item" to="/settings">
              <Settings :size="16" :stroke-width="1.8" />
              Settings
            </router-link>
            <hr class="nav-menu-divider" />
            <button type="button" class="nav-menu-item" @click="handleSignOut">
              <LogOut :size="16" :stroke-width="1.8" />
              Sign out
            </button>
            <hr class="nav-menu-divider" />
            <div class="nav-menu-links">
              <router-link to="/about">About</router-link>
              <a
                href="https://github.com/connorshea/vglist/blob/main/CHANGELOG.md"
                target="_blank"
                rel="noopener noreferrer"
                >Changelog</a
              >
              <a href="https://github.com/connorshea/vglist" target="_blank" rel="noopener noreferrer">GitHub</a>
              <a href="https://discord.gg/Ma8Ztcc" target="_blank" rel="noopener noreferrer">Discord</a>
            </div>
          </NavDropdown>
        </template>
        <template v-else>
          <router-link class="navbar-item" to="/signup">Sign up</router-link>
          <router-link class="navbar-item" to="/login">Sign in</router-link>
          <NavDropdown align-right>
            <template #trigger>More</template>
            <router-link class="nav-menu-item" to="/about">About</router-link>
            <a
              class="nav-menu-item"
              href="https://github.com/connorshea/vglist/blob/main/CHANGELOG.md"
              target="_blank"
              rel="noopener noreferrer"
              >Changelog</a
            >
            <a
              class="nav-menu-item"
              href="https://github.com/connorshea/vglist"
              target="_blank"
              rel="noopener noreferrer"
              >GitHub</a
            >
            <a class="nav-menu-item" href="https://discord.gg/Ma8Ztcc" target="_blank" rel="noopener noreferrer"
              >Discord</a
            >
          </NavDropdown>
        </template>
      </div>
    </div>

    <!-- Mobile bottom sheet nav -->
    <MobileNavSheet :is-open="isSheetOpen" @close="isSheetOpen = false" />
  </nav>
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { useRoute } from "vue-router";
import { useAuthStore } from "@/stores/auth";
import { useAuth } from "@/composables/useAuth";
import { useSearchOverlay } from "@/composables/useSearchOverlay";
import { ChevronDown, LogOut, Search, Settings, Shield, User } from "@lucide/vue";
import { refreshCurrentUserAvatar } from "@/utils/current-user-avatar";
import NavAvatar from "./NavAvatar.vue";
import NavDropdown from "./NavDropdown.vue";
import NavSearch from "./NavSearch.vue";
import MobileNavSheet from "./MobileNavSheet.vue";

const route = useRoute();
const authStore = useAuthStore();
const { signOut } = useAuth();
const { open: openSearch } = useSearchOverlay();
const isSheetOpen = ref(false);
const username = computed(() => authStore.user?.username ?? "");
const profilePath = computed(() => `/users/${authStore.user?.slug}`);

// signIn stores the avatar, so it shows straight away; this refresh keeps it
// current if it changed on another device. The sign-in page has no navbar,
// so this also runs once when the navbar mounts after signing in.
watch(
  () => authStore.token,
  (token) => {
    if (token) void refreshCurrentUserAvatar();
  },
  { immediate: true }
);

watch(
  () => route.path,
  () => {
    isSheetOpen.value = false;
  }
);

function handleSignOut() {
  signOut();
  isSheetOpen.value = false;
}
</script>

<style scoped>
.navbar-mobile-search {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: none;
  background: transparent;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  -webkit-tap-highlight-color: transparent;
  transition: background 0.2s;
  margin-left: auto;
  margin-right: 8px;
  align-self: center;
}

.navbar-mobile-search:active {
  background: rgba(255, 255, 255, 0.15);
}

/* The user menu trigger: avatar + username in a box that matches the
   search field beside it (same height, radius and translucent fill). */
.navbar-user-pill {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 36px;
  box-sizing: border-box;
  padding: 0 10px 0 5px;
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 6px;
  background-color: rgba(0, 0, 0, 0.2);
  color: #fff;
  font-weight: 500;
  transition:
    background-color 200ms,
    border-color 200ms;
}

.navbar-user:hover .navbar-user-pill {
  background-color: rgba(0, 0, 0, 0.25);
  border-color: rgba(255, 255, 255, 0.25);
}

.navbar-user:focus-within .navbar-user-pill,
.navbar-user.is-active .navbar-user-pill {
  background-color: rgba(0, 0, 0, 0.3);
  border-color: rgba(255, 255, 255, 0.35);
}

/* The pill draws its own focus ring, so drop the trigger's. */
.navbar-user :deep(.navbar-link:focus-visible) {
  outline: none;
}

.navbar-user .navbar-link:focus-visible .navbar-user-pill {
  outline: 2px solid #fff;
  outline-offset: 2px;
}

.navbar-user-pill .nav-avatar {
  width: 24px;
  height: 24px;
  border-radius: 4px;
  font-size: 12px;
}

/* No avatar: white tile with the initial, so it stands out on the purple bar. */
.navbar-user-pill .nav-avatar.is-initial,
.navbar-mobile-avatar .nav-avatar.is-initial {
  background: #fff;
  color: var(--p-600);
}

.navbar-user-name {
  max-width: 160px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.navbar-user-chevron {
  opacity: 0.8;
}

/* Signed in on mobile, the avatar replaces the hamburger and opens the same sheet. */
.navbar-mobile-avatar {
  width: 44px;
  height: 44px;
  padding: 0;
  border: none;
  border-radius: 50%;
  background: transparent;
  display: flex;
  align-items: center;
  justify-content: center;
  align-self: center;
  cursor: pointer;
  -webkit-tap-highlight-color: transparent;
}

.navbar-mobile-avatar .nav-avatar {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  font-size: 13px;
  box-shadow: 0 0 0 2px rgba(255, 255, 255, 0.6);
  transition: box-shadow 200ms;
}

.navbar-mobile-avatar[aria-expanded="true"] .nav-avatar {
  box-shadow: 0 0 0 2px #fff;
}

/* A separate ring around the whole 44px button, so keyboard focus is
   distinct from the open state's brighter avatar ring. */
.navbar-mobile-avatar:focus-visible {
  outline: 2px solid #fff;
  outline-offset: 0;
}

/* The signed-in user's menu adds an avatar header and a footer row of links. */
.navbar-user :deep(.user-menu) {
  width: 264px;
}

.user-menu-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 10px 12px;
  margin-bottom: 6px;
  border-bottom: 1px solid var(--color-border);
  color: inherit;
}

.user-menu-header .nav-avatar {
  width: 40px;
  height: 40px;
  max-height: none; /* Bulma caps navbar images at 1.75rem. */
  border-radius: 50%;
  font-size: 16px;
}

.user-menu-header .nav-avatar.is-initial {
  background: linear-gradient(135deg, var(--p-400), var(--p-300));
  color: #fff;
}

.user-menu-identity {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.user-menu-name {
  font-size: 15px;
  font-weight: 600;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.user-menu-sub {
  font-size: 12.5px;
  color: var(--nav-menu-muted);
}

.user-menu-header:hover .user-menu-sub,
.user-menu-header:focus-visible .user-menu-sub {
  text-decoration: underline;
}

.nav-menu-item {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  height: 36px;
  box-sizing: border-box;
  padding: 0 10px;
  border: 0;
  border-radius: 8px;
  background: none;
  color: var(--color-text-primary);
  font: inherit;
  text-align: left;
  cursor: pointer;
  transition: background-color 150ms;
}

.nav-menu-item svg {
  color: var(--nav-menu-muted);
  flex-shrink: 0;
}

.nav-menu-item:hover,
.nav-menu-item:focus-visible {
  background-color: var(--color-bg-subtle);
  color: var(--color-text-primary);
}

.user-menu-header:focus-visible,
.nav-menu-item:focus-visible,
.nav-menu-links a:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: -2px;
  border-radius: 8px;
}

.nav-menu-divider {
  height: 1px;
  margin: 6px 4px;
  border: 0;
  background-color: var(--color-border);
}

.nav-menu-links {
  display: flex;
  flex-wrap: wrap;
  gap: 2px 14px;
  padding: 4px 10px 6px;
  font-size: 12.5px;
}

.nav-menu-links a {
  color: var(--nav-menu-muted);
}

.nav-menu-links a:hover {
  color: var(--color-text-primary);
  text-decoration: underline;
}

/* Remove Bulma's margin-left:auto from the burger so it sits
   directly next to the search button (which has margin-left:auto). */
.navbar-burger {
  margin-left: 0;
}

.navbar-burger:focus-visible {
  outline: 2px solid #fff;
  outline-offset: -4px;
}
</style>
