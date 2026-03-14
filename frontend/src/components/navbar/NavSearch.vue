<template>
  <div class="navbar-search" :style="{ viewTransitionName: isOpen ? 'none' : 'search-bar' }" @click="open">
    <div class="control">
      <input class="input is-small" type="search" placeholder="Search..." readonly @keydown="handleKeydown" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { useSearchOverlay } from "@/composables/useSearchOverlay";

const { open, isOpen } = useSearchOverlay();

function handleKeydown(e: KeyboardEvent) {
  if (e.key === "Enter" || (e.key.length === 1 && !e.metaKey && !e.ctrlKey && !e.altKey)) {
    e.preventDefault();
    open();
  }
}
</script>
