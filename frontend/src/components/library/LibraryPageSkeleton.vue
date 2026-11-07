<template>
  <div class="library-page-skeleton" aria-hidden="true">
    <!-- Phone: status pills, search and sort, then the list -->
    <template v-if="phone">
      <div class="library-pills">
        <SkeletonBlock v-for="width in PILL_WIDTHS" :key="width" class="library-skeleton-pill" :style="{ width }" />
      </div>
      <div class="library-phone-controls">
        <SkeletonBlock class="library-skeleton-phone-search" />
        <SkeletonBlock class="library-skeleton-phone-sort" />
      </div>
      <LibrarySkeleton variant="rows" class="library-skeleton-rows" />
    </template>

    <!-- Desktop: filter rail beside the toolbar and games -->
    <div v-else class="library-split">
      <div class="library-split-rail library-skeleton-rail">
        <SkeletonBlock class="library-skeleton-search" />
        <div v-for="(section, index) in RAIL_SECTIONS" :key="index">
          <SkeletonBlock class="library-skeleton-rail-heading" />
          <div v-for="item in section" :key="item" class="library-skeleton-rail-item">
            <SkeletonBlock class="library-skeleton-rail-label" :style="{ width: item }" />
            <SkeletonBlock class="library-skeleton-rail-count" />
          </div>
        </div>
      </div>

      <div class="library-split-main">
        <div class="library-toolbar">
          <span class="library-toolbar-grow"></span>
          <SkeletonBlock class="library-skeleton-select" />
          <SkeletonBlock class="library-skeleton-select" />
        </div>
        <LibrarySkeleton :variant="grouped ? 'shelves' : 'grid'" />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import SkeletonBlock from "@/components/SkeletonBlock.vue";
import LibrarySkeleton from "@/components/library/LibrarySkeleton.vue";

// The whole library tab in outline, for the first load, before even the filter
// rail's counts have arrived. It reuses the page's layout classes so the rail,
// toolbar and grid sit where the real ones will.
defineProps<{
  phone: boolean;
  // Whether the games will be shown as status shelves or as one grid.
  grouped: boolean;
}>();

const PILL_WIDTHS = ["52px", "96px", "84px", "100px", "92px"];
// Label widths for the rail's status, platform and store lists.
const RAIL_SECTIONS = [
  ["56%", "48%", "40%", "60%", "70%", "44%", "52%", "58%"],
  ["44%", "52%", "36%"],
  ["40%", "48%"]
];
</script>

<style scoped>
/* ── Phone ── */
.library-pills {
  overflow: hidden;
}

.library-skeleton-pill {
  flex-shrink: 0;
  height: 32px;
  border-radius: 999px;
}

.library-skeleton-phone-search {
  flex: 1;
  height: 40px;
}

.library-skeleton-phone-sort {
  flex-shrink: 0;
  width: 40px;
  height: 40px;
}

.library-skeleton-rows {
  /* .library-rows draws this line above the real list */
  border-top: 1px solid var(--color-border);
}

/* ── Desktop rail ── */
.library-skeleton-rail {
  /* The real rail's content pushes it out to its max-width; match that. */
  flex-basis: 240px;
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.library-skeleton-search {
  height: 34px;
}

.library-skeleton-rail-heading {
  width: 52px;
  height: 8px;
  margin: 4px 0 12px;
  border-radius: 4px;
}

/* Each item is the height of a rail button (0.8rem text, 6px padding). */
.library-skeleton-rail-item {
  display: flex;
  align-items: center;
  height: calc(0.8rem * 1.5 + 12px);
  margin-bottom: 2px;
  padding: 0 8px;
}

.library-skeleton-rail-label {
  height: 9px;
  border-radius: 4px;
}

.library-skeleton-rail-count {
  width: 16px;
  height: 8px;
  margin-left: auto;
  border-radius: 4px;
}

/* ── Toolbar ── */
.library-skeleton-select {
  width: 128px;
  height: 30px;
  border-radius: 4px;
}
</style>
