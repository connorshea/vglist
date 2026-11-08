<template>
  <div class="user-overview-skeleton" aria-hidden="true">
    <section class="s-section">
      <div class="s-section-header">
        <SkeletonBlock class="s-bar s-icon" />
        <SkeletonBlock class="s-bar s-heading" style="width: 72px" />
        <SkeletonBlock class="s-bar s-count" />
      </div>
      <div class="s-grid">
        <SkeletonBlock v-for="tile in FAVORITE_TILES" :key="tile" class="s-tile" />
      </div>
    </section>

    <section class="s-section">
      <div class="s-section-header">
        <SkeletonBlock class="s-bar s-icon is-dot" />
        <SkeletonBlock class="s-bar s-heading" style="width: 60px" />
        <SkeletonBlock class="s-bar s-count" />
      </div>
      <div class="s-playing">
        <div v-for="card in PLAYING_CARDS" :key="card" class="s-card">
          <SkeletonBlock class="s-card-cover" />
          <div class="s-card-body">
            <SkeletonBlock class="s-bar s-card-name" />
            <SkeletonBlock class="s-bar s-card-meta" />
            <SkeletonBlock class="s-bar s-card-progress" />
          </div>
        </div>
      </div>
    </section>

    <section class="s-section">
      <div class="s-section-header">
        <SkeletonBlock class="s-bar s-heading" style="width: 104px" />
      </div>
      <div class="s-grid">
        <SkeletonBlock v-for="tile in LIBRARY_TILES" :key="tile" class="s-tile" />
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import SkeletonBlock from "@/components/SkeletonBlock.vue";

// Stands in for a profile's Overview tab while it first loads: Favorites,
// Playing and Highest rated, with as many tiles and cards as the real tab
// asks for. The headers, grids, LibraryGameTile tiles and LibraryPlayingCard
// cards use the same sizes as UserOverviewPage so nothing moves when it
// arrives; keep them in step. Hidden from screen readers: the page announces
// the loading state itself.
const FAVORITE_TILES = 6;
const PLAYING_CARDS = 3;
const LIBRARY_TILES = 12;
</script>

<style scoped>
.s-bar {
  border-radius: 4px;
}

.s-section {
  margin-bottom: 36px;
}

/* As tall as the real header's 0.95rem heading line. */
.s-section-header {
  display: flex;
  gap: 8px;
  align-items: center;
  height: calc(0.95rem * 1.5);
  margin-bottom: 12px;
}

.s-icon {
  width: 14px;
  height: 14px;
  border-radius: 50%;
}

.s-icon.is-dot {
  width: 8px;
  height: 8px;
}

.s-heading {
  height: 12px;
}

.s-count {
  width: 18px;
  height: 9px;
}

.s-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
  gap: 10px;
}

.s-tile {
  aspect-ratio: 3 / 4;
  border-radius: 10px;
}

.s-playing {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 12px;
}

/* LibraryPlayingCard: its height comes from the 64px cover. */
.s-card {
  display: flex;
  gap: 12px;
  padding: 12px;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  background: var(--color-surface);
}

.s-card-cover {
  flex-shrink: 0;
  width: 64px;
  aspect-ratio: 3 / 4;
}

.s-card-body {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 8px;
  min-width: 0;
  padding-top: 3px;
}

.s-card-name {
  width: 70%;
  height: 11px;
}

.s-card-meta {
  width: 45%;
  height: 8px;
}

.s-card-progress {
  width: 55%;
  height: 8px;
  margin-top: auto;
  margin-bottom: 3px;
}

@media (max-width: 768px) {
  .s-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 8px;
  }
}
</style>
