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
        :aria-expanded="isSheetOpen"
        @click="isSheetOpen = !isSheetOpen"
      >
        <NavAvatar :username="username" :avatar-url="authStore.user?.avatarUrl" />
      </button>

      <!-- Signed out: hamburger (mobile only, opens bottom sheet) -->
      <a
        v-else
        role="button"
        class="navbar-burger"
        :class="{ 'is-active': isSheetOpen }"
        aria-label="menu"
        :aria-expanded="isSheetOpen"
        @click="isSheetOpen = !isSheetOpen"
      >
        <span aria-hidden="true"></span>
        <span aria-hidden="true"></span>
        <span aria-hidden="true"></span>
        <span aria-hidden="true"></span>
      </a>
    </div>

    <!-- Desktop menu (never toggled by burger anymore) -->
    <div class="navbar-menu">
      <div class="navbar-start">
        <router-link class="navbar-item" to="/activity">Activity</router-link>
        <router-link class="navbar-item" to="/games">Games</router-link>
        <router-link class="navbar-item" to="/users">Users</router-link>

        <div class="navbar-item has-dropdown is-hoverable" @mouseenter="dropdownsClosed = false">
          <a class="navbar-link" tabindex="0">More</a>
          <div v-show="!dropdownsClosed" class="navbar-dropdown">
            <router-link class="navbar-item" to="/platforms">Platforms</router-link>
            <router-link class="navbar-item" to="/genres">Genres</router-link>
            <router-link class="navbar-item" to="/companies">Companies</router-link>
            <router-link class="navbar-item" to="/engines">Engines</router-link>
            <router-link class="navbar-item" to="/series">Series</router-link>
            <router-link class="navbar-item" to="/stores">Stores</router-link>
          </div>
        </div>
      </div>

      <div class="navbar-end">
        <div class="navbar-item">
          <NavSearch />
        </div>
        <template v-if="authStore.isAuthenticated">
          <div class="navbar-item has-dropdown is-hoverable navbar-user" @mouseenter="dropdownsClosed = false">
            <a class="navbar-link is-arrowless" tabindex="0">
              <span class="navbar-user-pill">
                <NavAvatar :username="username" :avatar-url="authStore.user?.avatarUrl" />
                <span class="navbar-user-name">{{ username }}</span>
                <ChevronDown class="navbar-user-chevron" :size="14" :stroke-width="2" />
              </span>
            </a>
            <div v-show="!dropdownsClosed" class="navbar-dropdown is-right">
              <router-link class="navbar-item" :to="`/users/${authStore.user?.slug}`"> Profile </router-link>
              <router-link v-if="authStore.isAdmin" class="navbar-item" to="/admin"> Admin </router-link>
              <router-link class="navbar-item" to="/settings">Settings</router-link>
              <hr class="navbar-divider" />
              <a class="navbar-item" @click="handleSignOut">Sign out</a>
              <hr class="navbar-divider" />
              <router-link class="navbar-item" to="/about">About</router-link>
              <a
                class="navbar-item"
                href="https://github.com/connorshea/vglist/blob/main/CHANGELOG.md"
                target="_blank"
                rel="noopener noreferrer"
                >Changelog</a
              >
              <a
                class="navbar-item"
                href="https://github.com/connorshea/vglist"
                target="_blank"
                rel="noopener noreferrer"
                >GitHub</a
              >
              <a class="navbar-item" href="https://discord.gg/Ma8Ztcc" target="_blank" rel="noopener noreferrer"
                >Discord</a
              >
            </div>
          </div>
        </template>
        <template v-else>
          <router-link class="navbar-item" to="/signup">Sign up</router-link>
          <router-link class="navbar-item" to="/login">Sign in</router-link>
          <div class="navbar-item has-dropdown is-hoverable" @mouseenter="dropdownsClosed = false">
            <a class="navbar-link" tabindex="0">More</a>
            <div v-show="!dropdownsClosed" class="navbar-dropdown is-right">
              <router-link class="navbar-item" to="/about">About</router-link>
              <a
                class="navbar-item"
                href="https://github.com/connorshea/vglist/blob/main/CHANGELOG.md"
                target="_blank"
                rel="noopener noreferrer"
                >Changelog</a
              >
              <a
                class="navbar-item"
                href="https://github.com/connorshea/vglist"
                target="_blank"
                rel="noopener noreferrer"
                >GitHub</a
              >
              <a class="navbar-item" href="https://discord.gg/Ma8Ztcc" target="_blank" rel="noopener noreferrer"
                >Discord</a
              >
            </div>
          </div>
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
import { ChevronDown, Search } from "@lucide/vue";
import { refreshCurrentUserAvatar } from "@/utils/current-user-avatar";
import NavAvatar from "./NavAvatar.vue";
import NavSearch from "./NavSearch.vue";
import MobileNavSheet from "./MobileNavSheet.vue";

const route = useRoute();
const authStore = useAuthStore();
const { signOut } = useAuth();
const { open: openSearch } = useSearchOverlay();
const isSheetOpen = ref(false);
const dropdownsClosed = ref(false);
const username = computed(() => authStore.user?.username ?? "");

// Load the avatar on page load and after each sign-in.
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
    dropdownsClosed.value = true;
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

.navbar-user:focus-within .navbar-user-pill {
  background-color: rgba(0, 0, 0, 0.3);
  border-color: rgba(255, 255, 255, 0.35);
}

.navbar-user .navbar-link:focus-visible {
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

.navbar-mobile-avatar[aria-expanded="true"] .nav-avatar,
.navbar-mobile-avatar:focus-visible .nav-avatar {
  box-shadow: 0 0 0 2px #fff;
}

.navbar-mobile-avatar:focus-visible {
  outline: none;
}

/* Remove Bulma's margin-left:auto from the burger so it sits
   directly next to the search button (which has margin-left:auto). */
.navbar-burger {
  margin-left: 0;
}
</style>
