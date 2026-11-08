<template>
  <div class="resource-show-skeleton" aria-hidden="true">
    <header class="s-head" :class="{ 'has-tabs': tabs > 0 }">
      <div class="container s-head-inner">
        <div class="s-kind">
          <SkeletonBlock class="s-bar s-kind-bar" />
        </div>
        <div class="s-name">
          <SkeletonBlock class="s-bar s-name-bar" />
        </div>
        <div class="s-facts">
          <SkeletonBlock v-for="fact in facts" :key="fact" class="s-bar s-fact-bar" />
          <SkeletonBlock class="s-bar s-wikidata-bar" />
        </div>
        <div v-if="tabs > 0" class="s-tabs">
          <div v-for="tab in tabs" :key="tab" class="s-tab">
            <SkeletonBlock class="s-bar s-tab-bar" />
          </div>
        </div>
      </div>
    </header>

    <section class="s-games">
      <div class="s-seg">
        <div v-for="option in RESOURCE_GAME_SORTS" :key="option.value" class="s-seg-btn">
          <!-- The real label, invisible, so each segment is as wide as it will be. -->
          <span class="s-seg-label">{{ option.label }}</span>
        </div>
      </div>

      <ul class="s-grid">
        <li v-for="card in CARDS" :key="card">
          <SkeletonBlock class="s-cover" />
          <div class="s-card-name">
            <SkeletonBlock class="s-bar s-card-name-bar" :style="{ width: nameWidth(card) }" />
          </div>
          <div class="s-card-meta">
            <SkeletonBlock class="s-bar s-card-meta-bar" />
          </div>
        </li>
      </ul>
    </section>
  </div>
</template>

<script setup lang="ts">
import SkeletonBlock from "@/components/SkeletonBlock.vue";
import { RESOURCE_GAME_SORTS } from "@/composables/useResourceGames";

// Stands in for a resource's page (a series, a company, ...) while it first
// loads: the ResourceHeader band, optional ResourceTabs, and the games grid
// from ResourceGameList. Each bar sits in a box the height of the real line of
// text, and the band, toolbar and cards use the same sizes as those
// components, so nothing moves when the page arrives; keep them in step. It's
// hidden from screen readers; the page announces the loading state itself.
withDefaults(
  defineProps<{
    // How many facts the header shows, e.g. "12 games".
    facts?: number;
    // How many tabs sit under the header, if any.
    tabs?: number;
  }>(),
  { facts: 1, tabs: 0 }
);

const CARDS = 12;

// Vary the game names a little so the grid doesn't look like a pattern.
const NAME_WIDTHS = ["82%", "64%", "90%", "56%", "74%", "68%"];
function nameWidth(i: number): string {
  return NAME_WIDTHS[(i - 1) % NAME_WIDTHS.length] ?? "70%";
}
</script>

<style scoped>
.s-bar {
  border-radius: 4px;
}

/* ── Header band (ResourceHeader) ── */
.s-head {
  width: 100vw;
  margin-left: calc(50% - 50vw);
  margin-top: -3rem;
  background: var(--color-bg-subtle);
  border-bottom: 1px solid var(--color-border);
}

.s-head-inner {
  padding: 2.5rem 1.5rem 1.75rem;
}

.s-head.has-tabs .s-head-inner {
  padding-bottom: 0;
}

@media screen and (min-width: 1024px) {
  .s-head-inner {
    padding-left: 0;
    padding-right: 0;
  }
}

/* Each row is the height of the real line box, with a shorter bar centred
   in it. The kind label is inline-flex, so its row is a full body-text line
   box (1rem × 1.5), not its own 0.7rem one. */
.s-kind {
  display: flex;
  align-items: center;
  height: calc(1rem * 1.5);
}

.s-kind-bar {
  width: 64px;
  height: 8px;
}

.s-name {
  display: flex;
  align-items: center;
  height: calc(2.5rem * 1.15);
  margin: 6px 0 8px;
}

.s-name-bar {
  width: min(360px, 70%);
  height: 30px;
  border-radius: 6px;
}

.s-facts {
  display: flex;
  align-items: center;
  gap: 8px 24px;
  height: calc(0.8125rem * 1.5);
}

.s-fact-bar {
  width: 76px;
  height: 9px;
}

.s-wikidata-bar {
  width: 64px;
  height: 9px;
}

@media screen and (max-width: 768px) {
  .s-name {
    height: calc(1.85rem * 1.15);
  }

  .s-name-bar {
    height: 22px;
  }
}

/* ── Tabs (ResourceTabs) ── */
.s-tabs {
  display: flex;
  margin-top: 1.75rem;
}

/* Padding, line box and bottom border of a real tab. */
.s-tab {
  display: flex;
  align-items: center;
  height: calc(0.875rem * 1.5);
  padding: 10px 18px;
  box-sizing: content-box;
  border-bottom: 2px solid transparent;
  margin-bottom: -1px;
}

.s-tab-bar {
  width: 80px;
  height: 9px;
}

/* ── Games (ResourceGameList) ── */
.s-games {
  padding: 1.5rem 0 1rem;
}

.s-seg {
  display: inline-flex;
  max-width: 100%;
  overflow: hidden;
  margin-bottom: 1rem;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface);
}

.s-seg-btn {
  position: relative;
  padding: 6px 12px;
  font-size: 0.75rem;
  white-space: nowrap;
}

.s-seg-btn + .s-seg-btn::before {
  content: "";
  position: absolute;
  left: 0;
  top: 25%;
  height: 50%;
  width: 1px;
  background: var(--color-border);
}

.s-seg-label {
  visibility: hidden;
}

@media screen and (max-width: 480px) {
  .s-seg-btn {
    padding: 8px 12px;
  }
}

.s-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(170px, 1fr));
  gap: 24px 16px;
}

@media screen and (max-width: 768px) {
  .s-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 16px 10px;
  }
}

.s-cover {
  aspect-ratio: 3 / 4;
  border-radius: 10px;
}

.s-card-name {
  display: flex;
  align-items: center;
  height: calc(0.8125rem * 1.3);
  margin-top: 8px;
}

.s-card-name-bar {
  height: 9px;
}

.s-card-meta {
  display: flex;
  align-items: center;
  height: calc(0.72rem * 1.5);
  margin-top: 2px;
}

.s-card-meta-bar {
  width: 32px;
  height: 7px;
}

/* Phones clamp names to two lines; most fit on one at 12px. */
@media screen and (max-width: 768px) {
  .s-card-name {
    height: calc(12px * 1.3);
  }
}
</style>
