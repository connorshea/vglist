<template>
  <div class="navbar-search" :style="{ viewTransitionName: isOpen ? 'none' : 'search-bar' }" @click="open">
    <div class="control">
      <input class="input is-small" type="search" placeholder="Search..." readonly @keydown="handleKeydown" />
      <kbd class="search-shortcut">{{ isMac ? "⌘" : "Ctrl+" }}K</kbd>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useSearchOverlay } from "@/composables/useSearchOverlay";

const { open, isOpen } = useSearchOverlay();

const isMac = navigator.platform.toUpperCase().includes("MAC");

function handleKeydown(e: KeyboardEvent) {
  if (e.key === "Enter" || (e.key.length === 1 && !e.metaKey && !e.ctrlKey && !e.altKey)) {
    e.preventDefault();
    open();
  }
}
</script>

<style scoped>
.navbar-search {
  min-width: 260px;
}

.navbar-search .control {
  position: relative;
}

.search-shortcut {
  position: absolute;
  right: 8px;
  top: 50%;
  transform: translateY(-50%);
  font-size: 0.7rem;
  font-family: inherit;
  color: rgba(255, 255, 255, 0.5);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 4px;
  padding: 1px 5px;
  pointer-events: none;
  line-height: 1.4;
}
</style>
