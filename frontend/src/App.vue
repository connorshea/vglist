<template>
  <div id="vglist-app">
    <NavBar v-if="layout === 'default'" />
    <!-- Bare routes (e.g. the auth pages) render full-bleed with no navbar. -->
    <main v-if="layout === 'bare'" id="main-content">
      <router-view />
    </main>
    <main v-else id="main-content" class="section">
      <div class="container">
        <router-view />
      </div>
    </main>
    <SearchOverlay />
    <SnackbarContainer />
  </div>
</template>

<script setup lang="ts">
import { computed, watch, onMounted, onUnmounted } from "vue";
import { useRoute } from "vue-router";
import NavBar from "@/components/navbar/NavBar.vue";
import SearchOverlay from "@/components/SearchOverlay.vue";
import SnackbarContainer from "@/components/SnackbarContainer.vue";
import { useSearchOverlay } from "@/composables/useSearchOverlay";
import { useSnackbar } from "@/composables/useSnackbar";

const route = useRoute();

// Which app shell to render, from the matched route's `meta.layout`.
// "pending" covers the initial load before the first navigation resolves
// (no route is matched yet): we hold the navbar back so it doesn't flash
// above a bare page like /login before disappearing.
const layout = computed<"pending" | "default" | "bare">(() => {
  if (route.matched.length === 0) {
    return "pending";
  }
  return route.meta.layout === "bare" ? "bare" : "default";
});

const { toggle: toggleSearch } = useSearchOverlay();
const { show: showSnackbar } = useSnackbar();

// Global keyboard shortcut: Cmd+K / Ctrl+K to toggle search overlay.
// Ignore events that originate from editable elements so we don't hijack
// normal typing or interfere with assistive-tech workflows, and bail out
// when Alt is held so we don't swallow alternate OS-level shortcuts.
function isEditableTarget(target: EventTarget | null): boolean {
  if (!(target instanceof HTMLElement)) {
    return false;
  }
  if (target.isContentEditable) {
    return true;
  }
  const tag = target.tagName;
  return tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT";
}

function handleGlobalKeydown(e: KeyboardEvent) {
  if (e.key !== "k" || !(e.metaKey || e.ctrlKey) || e.altKey || isEditableTarget(e.target)) {
    return;
  }

  e.preventDefault();
  toggleSearch();
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
