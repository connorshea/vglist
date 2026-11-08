<template>
  <div class="activity-feed-skeleton" aria-hidden="true">
    <div v-for="i in count" :key="i" class="s-card">
      <SkeletonBlock class="s-cover" />
      <div class="s-body">
        <div class="s-row1">
          <SkeletonBlock class="s-avatar" />
          <SkeletonBlock class="s-line s-sentence" :style="{ width: sentenceWidth(i) }" />
        </div>
        <div class="s-meta">
          <SkeletonBlock class="s-line s-time" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import SkeletonBlock from "@/components/SkeletonBlock.vue";

// Stands in for a list of activity cards (the global feed and a user's
// Activity tab) while the first page loads. The card, cover and text rows use
// the same sizes as the real `.a-card` so the list doesn't jump when events
// arrive; keep them in step. Announce the loading state from the page (a
// role="status" line), since this is hidden from screen readers.

withDefaults(defineProps<{ count?: number }>(), { count: 8 });

// Vary the sentence length a little so the list doesn't look like a grid.
const SENTENCE_WIDTHS = ["62%", "48%", "71%", "55%", "40%", "66%"];
function sentenceWidth(i: number): string {
  return SENTENCE_WIDTHS[(i - 1) % SENTENCE_WIDTHS.length] ?? "60%";
}
</script>

<style scoped>
.s-card {
  background: var(--color-surface);
  border-radius: 10px;
  padding: 14px 16px;
  display: flex;
  gap: 14px;
  align-items: flex-start;
  border: 1px solid rgba(0, 0, 0, 0.08);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  margin-bottom: 8px;
}

.s-cover {
  flex-shrink: 0;
  width: 52px;
  height: 68px;
  border-radius: 6px;
}

.s-body {
  flex: 1;
  min-width: 0;
}

/* Each row is one line box of the real card's text, with a shorter bar
   centred in it, so the rows take the height the text will. The first row is
   as tall as its 22px inline avatar, which stretches the 14px × 1.45 line box
   (about 22.2px measured). */
.s-row1 {
  display: flex;
  align-items: center;
  gap: 4px;
  height: 22px;
  max-width: 480px;
}

.s-avatar {
  flex-shrink: 0;
  width: 22px;
  height: 22px;
  border-radius: 50%;
}

.s-line {
  border-radius: 4px;
}

.s-sentence {
  height: 10px;
}

.s-meta {
  display: flex;
  align-items: center;
  margin-top: 6px;
  height: calc(12px * 1.5);
}

.s-time {
  width: 64px;
  height: 8px;
}

/* Phones hide the cover and tighten the card, like `.a-card`. */
@media (max-width: 768px) {
  .s-card {
    flex-direction: column;
    align-items: stretch;
    gap: 10px;
    padding: 12px 14px;
  }

  .s-cover {
    display: none;
  }

  .s-row1 {
    max-width: none;
  }
}
</style>
