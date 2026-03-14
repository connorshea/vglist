<template>
  <div id="vglist-app">
    <NavBar />
    <main class="section">
      <div class="container">
        <div
          v-if="flashMessage"
          class="notification"
          :class="flashType === 'error' ? 'is-danger' : 'is-success'"
        >
          <button class="delete" @click="flashMessage = ''"></button>
          {{ flashMessage }}
        </div>
        <router-view />
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from "vue";
import { useRoute } from "vue-router";
import NavBar from "@/components/navbar/NavBar.vue";

const route = useRoute();
const flashMessage = ref("");
const flashType = ref<"success" | "error">("success");

// Handle flash messages from route query (e.g., after email confirmation)
watch(
  () => route.query,
  (query) => {
    if (query.confirmed === "true") {
      flashMessage.value = "Your email has been confirmed. You can now sign in.";
      flashType.value = "success";
    } else if (query.confirmation_error === "true") {
      flashMessage.value = "There was an error confirming your email. Please try again.";
      flashType.value = "error";
    }
  },
  { immediate: true }
);
</script>
