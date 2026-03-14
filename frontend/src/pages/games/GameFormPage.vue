<template>
  <section class="section">
    <div class="columns is-centered">
      <div class="column is-6">
        <div v-if="!authStore.isAuthenticated" class="notification is-warning">
          <p>
            You must be <router-link to="/login">signed in</router-link> to create or edit games.
          </p>
        </div>

        <div v-else class="box has-text-centered">
          <h1 class="title">{{ isEditing ? "Edit Game" : "New Game" }}</h1>
          <p class="subtitle has-text-grey">Game form coming soon</p>
          <p>The full game creation and editing form is under development.</p>
          <router-link to="/games" class="button is-link mt-4"> Back to Games </router-link>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useRoute } from "vue-router";
import { useAuthStore } from "@/stores/auth";

const route = useRoute();
const authStore = useAuthStore();

const isEditing = computed(() => !!route.params.id);
</script>
