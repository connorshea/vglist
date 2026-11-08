<template>
  <div class="s-grid" aria-hidden="true">
    <SkeletonBlock v-for="tile in TILES" :key="tile" class="s-tile" />
  </div>
</template>

<script setup lang="ts">
import SkeletonBlock from "@/components/SkeletonBlock.vue";

// Stands in for a profile's Favorites grid while it first loads, with the same
// columns and tile shape as UserFavoritesPage's LibraryGameTile grid; keep them
// in step. Hidden from screen readers: the page announces the loading state.
const TILES = 18;
</script>

<style scoped>
.s-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
  gap: 10px;
}

.s-tile {
  aspect-ratio: 3 / 4;
  border-radius: 10px;
}

@media (max-width: 768px) {
  .s-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 8px;
  }
}
</style>
