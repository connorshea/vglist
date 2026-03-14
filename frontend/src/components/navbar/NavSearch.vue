<template>
  <div
    class="navbar-search"
    :style="{ viewTransitionName: isOpen ? 'none' : 'search-bar' }"
    @click="open"
  >
    <div class="control">
      <input class="input is-small" type="search" placeholder="Search..." readonly @focus="open" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { useSearchOverlay } from "@/composables/useSearchOverlay";

const { open, isOpen } = useSearchOverlay();
</script>
