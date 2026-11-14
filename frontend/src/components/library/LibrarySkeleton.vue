<template>
  <div class="library-skeleton" aria-hidden="true">
    <!-- A shelf per status, each a row of tiles -->
    <template v-if="variant === 'shelves'">
      <section v-for="(shelf, index) in SHELVES" :key="index" class="library-shelf">
        <div class="library-shelf-header">
          <SkeletonBlock class="library-skeleton-dot" />
          <SkeletonBlock class="library-skeleton-heading" :style="{ width: shelf.headingWidth }" />
          <SkeletonBlock class="library-skeleton-count" />
        </div>
        <div class="library-grid library-skeleton-one-row">
          <SkeletonBlock v-for="tile in SHELF_TILES" :key="tile" class="library-skeleton-tile" />
        </div>
      </section>
    </template>

    <!-- One status, or everything in one grid -->
    <template v-else-if="variant === 'grid'">
      <div class="library-skeleton-result-count">
        <SkeletonBlock class="library-skeleton-line is-result-count" />
      </div>
      <div class="library-grid">
        <SkeletonBlock v-for="tile in GRID_TILES" :key="tile" class="library-skeleton-tile" />
      </div>
    </template>

    <!-- Phone list rows -->
    <template v-else>
      <div v-for="row in ROWS" :key="row" class="library-skeleton-row">
        <SkeletonBlock class="library-skeleton-row-cover" />
        <div class="library-skeleton-row-body">
          <SkeletonBlock class="library-skeleton-line is-name" :style="{ width: `${50 + ((row * 37) % 35)}%` }" />
          <SkeletonBlock class="library-skeleton-line is-meta" />
        </div>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import SkeletonBlock from "@/components/SkeletonBlock.vue";

// Stands in for the library's games while they load, in the shape of whichever
// layout is about to appear: shelves, a single grid, or the phone's list. The
// sizes follow LibraryGameTile and LibraryPhoneRow, and it reuses the page's
// own .library-shelf/.library-grid classes,
// so the columns line up with the real content; keep them in step. It's hidden
// from screen readers: the page announces the loading state itself.
defineProps<{
  variant: "shelves" | "grid" | "rows";
}>();

const SHELVES = [{ headingWidth: "64px" }, { headingWidth: "88px" }, { headingWidth: "72px" }] as const;
// More than fit in one row on a wide screen; the extra ones are clipped.
const SHELF_TILES = 10;
const GRID_TILES = 24;
const ROWS = 10;
</script>

<style scoped>
.library-skeleton-line {
  border-radius: 4px;
}

/* ── Shelf header ── */
.library-skeleton-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

/* The heading and count bars sit in line boxes the height of the real text,
   so the header doesn't change height when it arrives. */
.library-skeleton-heading {
  height: 12px;
  margin: calc((0.95rem * 1.5 - 12px) / 2) 0;
}

.library-skeleton-count {
  width: 18px;
  height: 9px;
}

/* ── Tiles ── */
.library-skeleton-tile {
  aspect-ratio: 3 / 4;
  border-radius: 10px;
}

/* A shelf skeleton is a single row of tiles however wide the grid is: any
   tiles that wrap go into zero-height rows and are clipped. */
.library-skeleton-one-row {
  grid-template-rows: auto;
  grid-auto-rows: 0;
  row-gap: 0;
  overflow: hidden;
}

.library-skeleton-result-count {
  display: flex;
  align-items: center;
  height: calc(0.8rem * 1.5);
  margin-bottom: 12px;
}

.library-skeleton-line.is-result-count {
  width: 72px;
  height: 9px;
}

/* ── Phone rows ── */
.library-skeleton-row {
  display: flex;
  gap: 12px;
  align-items: center;
  padding: 10px var(--library-inset, 16px);
  border-bottom: 1px solid var(--color-border);
}

.library-skeleton-row-cover {
  flex-shrink: 0;
  width: 40px;
  aspect-ratio: 3 / 4;
  border-radius: 5px;
}

.library-skeleton-row-body {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 8px;
  min-width: 0;
}

.library-skeleton-row-body .is-name {
  height: 11px;
}

.library-skeleton-row-body .is-meta {
  width: 30%;
  height: 8px;
}
</style>
