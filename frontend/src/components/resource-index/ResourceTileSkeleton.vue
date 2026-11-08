<template>
  <div class="resource-tile-skeleton" aria-hidden="true">
    <div class="s-mosaic">
      <SkeletonBlock v-for="slot in 4" :key="slot" class="s-slot" />
    </div>
    <div class="s-text">
      <div class="s-name">
        <SkeletonBlock class="s-bar s-name-bar" :style="{ width: nameWidth }" />
      </div>
      <div class="s-meta">
        <SkeletonBlock class="s-bar s-meta-bar" />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import SkeletonBlock from "@/components/SkeletonBlock.vue";

// Stands in for a ResourceTile on an index page while the first page loads.
// The tile's border, mosaic height, padding and line boxes are copied from
// ResourceTile (wide screens) and its phone row layout, so the grid doesn't
// move when the real tiles arrive; keep them in step.
withDefaults(
  defineProps<{
    // Width of the name bar, varied by the parent so the grid isn't a pattern.
    nameWidth?: string;
  }>(),
  { nameWidth: "60%" }
);
</script>

<style scoped>
.resource-tile-skeleton {
  height: 100%;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background: var(--color-surface);
  overflow: hidden;
}

.s-bar {
  border-radius: 4px;
}

.s-mosaic {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 3px;
  height: 132px;
}

.s-slot {
  height: 100%;
  border-radius: 0;
}

.s-text {
  padding: 12px 14px 14px;
}

/* Each row is the height of the real line box, with a shorter bar centred in
   it. */
.s-name {
  display: flex;
  align-items: center;
  height: calc(15px * 1.3);
}

.s-name-bar {
  height: 11px;
}

.s-meta {
  display: flex;
  align-items: center;
  height: calc(12.5px * 1.5);
  margin-top: 3px;
}

.s-meta-bar {
  width: 96px;
  height: 8px;
}

/* Phone: a list row with one cover-sized block where the stack of covers
   goes. */
@media screen and (max-width: 768px) {
  .resource-tile-skeleton {
    display: flex;
    align-items: center;
    gap: 12px;
    min-height: 76px;
    padding: 10px 0;
    border: 0;
    border-bottom: 1px solid var(--color-border);
    border-radius: 0;
    background: transparent;
  }

  .s-mosaic {
    display: block;
    flex-shrink: 0;
    width: 66px;
    height: 56px;
  }

  .s-slot {
    width: 42px;
    border-radius: 4px;
  }

  .s-slot:not(:first-child) {
    display: none;
  }

  .s-text {
    flex: 1;
    padding: 0;
  }
}
</style>
