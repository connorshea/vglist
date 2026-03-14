<template>
  <div id="vglist-app">
    <NavBar />
    <main class="section">
      <div class="container">
        <router-view />
      </div>
    </main>
    <SearchOverlay />
    <SnackbarContainer />
  </div>
</template>

<script setup lang="ts">
import { watch, onMounted, onUnmounted } from "vue";
import { useRoute } from "vue-router";
import NavBar from "@/components/navbar/NavBar.vue";
import SearchOverlay from "@/components/SearchOverlay.vue";
import SnackbarContainer from "@/components/SnackbarContainer.vue";
import { useSearchOverlay } from "@/composables/useSearchOverlay";
import { useSnackbar } from "@/composables/useSnackbar";

const route = useRoute();
const { toggle: toggleSearch } = useSearchOverlay();
const { show: showSnackbar } = useSnackbar();

// Global keyboard shortcut: Cmd+K / Ctrl+K to toggle search overlay
function handleGlobalKeydown(e: KeyboardEvent) {
  if ((e.metaKey || e.ctrlKey) && e.key === "k") {
    e.preventDefault();
    toggleSearch();
  }
}

onMounted(() => {
  document.addEventListener("keydown", handleGlobalKeydown);
});

onUnmounted(() => {
  document.removeEventListener("keydown", handleGlobalKeydown);
});

// Handle flash messages from route query (e.g., after email confirmation)
watch(
  () => route.query,
  (query) => {
    if (query.confirmed === "true") {
      showSnackbar("Your email has been confirmed. You can now sign in.", "success");
    } else if (query.confirmation_error === "true") {
      showSnackbar("There was an error confirming your email. Please try again.", "error");
    }
  },
  { immediate: true }
);
</script>
