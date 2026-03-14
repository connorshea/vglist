<template>
  <nav class="navbar is-primary" role="navigation" aria-label="main navigation">
    <div class="navbar-brand">
      <router-link class="navbar-item" to="/">
        <img src="@/assets/images/vglist-logo.svg" alt="vglist" style="height: 24px" />
      </router-link>

      <!-- Mobile search button -->
      <button
        class="navbar-mobile-search is-hidden-desktop"
        aria-label="Search"
        @click="openSearch"
      >
        <svg
          width="18"
          height="18"
          viewBox="0 0 18 18"
          fill="none"
          stroke="currentColor"
          stroke-width="1.8"
          stroke-linecap="round"
        >
          <circle cx="7.5" cy="7.5" r="5.5" />
          <path d="M12 12l4 4" />
        </svg>
      </button>

      <!-- Hamburger (mobile only, opens bottom sheet) -->
      <a
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
          <div class="navbar-item has-dropdown is-hoverable" @mouseenter="dropdownsClosed = false">
            <a class="navbar-link" tabindex="0">
              {{ authStore.user?.username }}
            </a>
            <div v-show="!dropdownsClosed" class="navbar-dropdown is-right">
              <router-link class="navbar-item" :to="`/users/${authStore.user?.slug}`">
                Profile
              </router-link>
              <router-link v-if="authStore.isAdmin" class="navbar-item" to="/admin">
                Admin
              </router-link>
              <router-link class="navbar-item" to="/settings">Settings</router-link>
              <hr class="navbar-divider" />
              <a class="navbar-item" @click="handleSignOut">Sign out</a>
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
                href="https://github.com/connorshea/vglist"
                target="_blank"
                rel="noopener noreferrer"
                >GitHub</a
              >
              <a
                class="navbar-item"
                href="https://discord.gg/EWGm3YY"
                target="_blank"
                rel="noopener noreferrer"
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
import { ref, watch } from "vue";
import { useRoute } from "vue-router";
import { useAuthStore } from "@/stores/auth";
import { useAuth } from "@/composables/useAuth";
import { useSearchOverlay } from "@/composables/useSearchOverlay";
import NavSearch from "./NavSearch.vue";
import MobileNavSheet from "./MobileNavSheet.vue";

const route = useRoute();
const authStore = useAuthStore();
const { signOut } = useAuth();
const { open: openSearch } = useSearchOverlay();
const isSheetOpen = ref(false);
const dropdownsClosed = ref(false);

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
  background: rgba(255, 255, 255, 0.12);
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
  background: rgba(255, 255, 255, 0.22);
}
</style>
