<template>
  <span class="game-tile-skeleton" aria-hidden="true">
    <SkeletonBlock class="game-tile-skeleton-cover" />
    <span class="game-tile-skeleton-name">
      <SkeletonBlock class="game-tile-skeleton-line is-name" />
      <SkeletonBlock class="game-tile-skeleton-line is-name-2" />
    </span>
    <span class="game-tile-skeleton-meta"><SkeletonBlock class="game-tile-skeleton-line is-meta" /></span>
  </span>
</template>

<script setup lang="ts">
import SkeletonBlock from "@/components/SkeletonBlock.vue";

// Stands in for a GameTile while it loads. The cover, name and meta rows use
// the same sizes as GameTile so the grid doesn't move when the games arrive;
// keep the two in step.
</script>

<style scoped>
.game-tile-skeleton {
  display: block;
  min-width: 0;
}

.game-tile-skeleton-cover {
  aspect-ratio: 3 / 4;
  width: 100%;
  border-radius: 10px;
}

/* Each row is one line box of GameTile's text, with a shorter bar centred in
   it, so the rows take exactly the height the text will. */
.game-tile-skeleton-name,
.game-tile-skeleton-meta {
  display: flex;
  align-items: center;
}

.game-tile-skeleton-name {
  margin-top: 8px;
  height: calc(13px * 1.3);
}

.game-tile-skeleton-meta {
  margin-top: 2px;
  height: calc(11.5px * 1.5);
}

.game-tile-skeleton-line {
  border-radius: 4px;
}

.game-tile-skeleton-line.is-name {
  width: 80%;
  height: 10px;
}

.game-tile-skeleton-line.is-meta {
  width: 50%;
  height: 8px;
}

/* The second title line only exists on phones, where GameTile always reserves
   two lines for the title. */
.game-tile-skeleton-line.is-name-2 {
  display: none;
}

@media (max-width: 768px) {
  .game-tile-skeleton-name {
    flex-direction: column;
    align-items: flex-start;
    justify-content: space-around;
    height: calc(2 * 12px * 1.3);
  }

  .game-tile-skeleton-line.is-name {
    width: 90%;
    height: 9px;
  }

  .game-tile-skeleton-line.is-name-2 {
    display: block;
    width: 55%;
    height: 9px;
  }

  .game-tile-skeleton-meta {
    height: calc(11px * 1.5);
  }
}
</style>
