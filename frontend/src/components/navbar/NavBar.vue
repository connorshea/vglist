<template>
  <nav class="navbar is-primary" role="navigation" aria-label="main navigation">
    <div class="navbar-brand">
      <router-link class="navbar-item" to="/">
        <img src="@/assets/images/vglist-logo.svg" alt="vglist" style="height: 24px" />
      </router-link>

      <div class="navbar-item is-hidden-touch">
        <NavSearch />
      </div>

      <a
        role="button"
        class="navbar-burger"
        :class="{ 'is-active': isBurgerActive }"
        aria-label="menu"
        aria-expanded="false"
        @click="isBurgerActive = !isBurgerActive"
      >
        <span aria-hidden="true"></span>
        <span aria-hidden="true"></span>
        <span aria-hidden="true"></span>
        <span aria-hidden="true"></span>
      </a>
    </div>

    <div class="navbar-menu" :class="{ 'is-active': isBurgerActive }">
      <div class="navbar-start">
        <div class="navbar-item is-hidden-desktop">
          <NavSearch />
        </div>

        <router-link class="navbar-item" to="/activity">Activity</router-link>
        <router-link class="navbar-item" to="/games">Games</router-link>
        <router-link class="navbar-item" to="/users">Users</router-link>

        <div class="navbar-item has-dropdown is-hoverable">
          <a class="navbar-link">More</a>
          <div class="navbar-dropdown">
            <router-link class="navbar-item" to="/platforms">Platforms</router-link>
            <router-link class="navbar-item" to="/genres">Genres</router-link>
            <router-link class="navbar-item" to="/companies">Companies</router-link>
            <router-link class="navbar-item" to="/engines">Engines</router-link>
            <router-link class="navbar-item" to="/series">Series</router-link>
            <router-link class="navbar-item" to="/stores">Stores</router-link>
            <hr class="navbar-divider" />
            <router-link class="navbar-item" to="/about">About</router-link>
          </div>
        </div>
      </div>

      <div class="navbar-end">
        <template v-if="authStore.isAuthenticated">
          <div class="navbar-item has-dropdown is-hoverable">
            <a class="navbar-link">
              {{ authStore.user?.username }}
            </a>
            <div class="navbar-dropdown is-right">
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
          <div class="navbar-item">
            <div class="buttons">
              <router-link class="button is-light" to="/signup">Sign Up</router-link>
              <router-link class="button is-white" to="/login">Sign In</router-link>
            </div>
          </div>
        </template>
      </div>
    </div>
  </nav>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { useAuthStore } from "@/stores/auth";
import { useAuth } from "@/composables/useAuth";
import NavSearch from "./NavSearch.vue";

const authStore = useAuthStore();
const { signOut } = useAuth();
const isBurgerActive = ref(false);

function handleSignOut() {
  signOut();
  isBurgerActive.value = false;
}
</script>
