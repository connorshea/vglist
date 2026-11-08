<template>
  <section class="game-card" aria-labelledby="game-reviews-heading">
    <div class="game-card-head">
      <h2 id="game-reviews-heading" class="game-card-title">
        Reviews<span v-if="totalCount > 0" class="game-card-count">{{ totalCount.toLocaleString() }}</span>
      </h2>
    </div>

    <div v-if="totalCount > 1" class="review-sorts" role="group" aria-label="Sort reviews">
      <button
        v-for="option in SORT_OPTIONS"
        :key="option.key"
        type="button"
        :aria-pressed="sort === option.key"
        @click="emit('update:sort', option.key)"
      >
        {{ option.label }}
      </button>
    </div>

    <p v-if="!loading && reviews.length === 0" class="game-card-empty">
      No reviews yet. Reviews are the notes people leave on their library entries.
    </p>

    <div :class="{ 'reviews-refreshing': loading && reviews.length > 0 }" :aria-busy="loading">
      <article v-for="review in reviews" :key="review.id" class="review">
        <router-link :to="`/users/${review.user.slug}`" tabindex="-1" aria-hidden="true">
          <UserAvatar :user="review.user" :size="40" />
        </router-link>
        <div class="review-body">
          <div class="review-top">
            <router-link class="review-user" :to="`/users/${review.user.slug}`">{{ review.user.username }}</router-link>
            <span v-if="review.rating !== null" class="review-score" :class="ratingTier(review.rating)">
              <span class="visually-hidden">Rated </span>{{ review.rating }}
            </span>
            <span v-if="statusFor(review)" class="review-status" :class="statusFor(review)?.className">
              {{ statusFor(review)?.label }}
            </span>
            <time :datetime="review.updatedAt" :title="new Date(review.updatedAt).toLocaleString()">
              {{ timeAgo(review.updatedAt) }}
            </time>
          </div>
          <p class="review-text">
            {{ isExpanded(review) ? review.comments : truncate(review.comments) }}
            <button
              v-if="isLong(review)"
              type="button"
              class="review-more"
              :aria-expanded="isExpanded(review)"
              @click="toggleExpanded(review.id)"
            >
              {{ isExpanded(review) ? "Show less" : "Read more" }}
            </button>
          </p>
          <p v-if="metaFor(review)" class="review-meta">{{ metaFor(review) }}</p>
        </div>
      </article>
    </div>

    <button
      v-if="reviews.length < totalCount"
      type="button"
      class="review-load-more"
      :disabled="loading"
      @click="emit('load-more')"
    >
      {{ loading ? "Loading…" : "Show more reviews" }}
    </button>
  </section>
</template>

<script setup lang="ts">
import { ref } from "vue";
import type { GameReviewSort, GetGameReviewsQuery } from "@/types/graphql";
import { formatHours, libraryStatus, ratingTier } from "@/utils/library";
import { timeAgo } from "@/utils/time";
import UserAvatar from "@/components/game/UserAvatar.vue";

export type GameReview = NonNullable<GetGameReviewsQuery["game"]>["reviews"]["nodes"][number];

defineProps<{
  reviews: GameReview[];
  totalCount: number;
  sort: GameReviewSort;
  loading: boolean;
}>();

const emit = defineEmits<{
  "update:sort": [sort: GameReviewSort];
  "load-more": [];
}>();

const SORT_OPTIONS: readonly { key: GameReviewSort; label: string }[] = [
  { key: "RECENT", label: "Recent" },
  { key: "HIGHEST_RATING", label: "Highest rated" },
  { key: "LOWEST_RATING", label: "Lowest rated" }
];

// Long reviews are cut at a word boundary until the reader asks for the rest.
const TRUNCATE_AT = 480;
const expanded = ref(new Set<string>());

function isLong(review: GameReview): boolean {
  return (review.comments ?? "").length > TRUNCATE_AT;
}

function isExpanded(review: GameReview): boolean {
  return !isLong(review) || expanded.value.has(review.id);
}

function toggleExpanded(id: string) {
  const next = new Set(expanded.value);
  if (next.has(id)) {
    next.delete(id);
  } else {
    next.add(id);
  }
  expanded.value = next;
}

function truncate(text: string | null): string {
  const value = text ?? "";
  if (value.length <= TRUNCATE_AT) {
    return value;
  }
  const cut = value.slice(0, TRUNCATE_AT);
  const lastSpace = cut.lastIndexOf(" ");
  return `${(lastSpace > TRUNCATE_AT * 0.8 ? cut.slice(0, lastSpace) : cut).trimEnd()}…`;
}

function statusFor(review: GameReview) {
  return libraryStatus(review.completionStatus);
}

// "68h played · Nintendo Switch 2 · Played twice"
function metaFor(review: GameReview): string {
  const parts: string[] = [];
  const hours = formatHours(review.hoursPlayed);
  if (hours) {
    parts.push(`${hours} played`);
  }
  if (review.platforms.nodes.length) {
    parts.push(review.platforms.nodes.map((p) => p.name).join(", "));
  }
  if (review.replayCount === 1) {
    parts.push("Played twice");
  } else if (review.replayCount > 1) {
    parts.push(`Played ${review.replayCount + 1} times`);
  }
  return parts.join(" · ");
}
</script>

<style scoped>
.review-sorts {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin: 8px 0 4px;
}

.review-sorts button {
  display: inline-flex;
  align-items: center;
  height: 32px;
  padding: 0 12px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-pill);
  background: transparent;
  color: var(--color-text-secondary);
  font: inherit;
  line-height: 1;
  font-size: 0.8125rem;
  font-weight: 500;
  cursor: pointer;
}

.review-sorts button:hover {
  color: var(--color-text-primary);
  border-color: var(--color-text-tertiary);
}

.review-sorts button[aria-pressed="true"] {
  background: var(--vglist-theme);
  border-color: var(--vglist-theme);
  color: #fff;
}

.review-sorts button:focus-visible,
.review-more:focus-visible,
.review-load-more:focus-visible,
.review a:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.reviews-refreshing {
  opacity: 0.6;
  transition: opacity var(--transition-normal);
}

.review {
  display: grid;
  grid-template-columns: 40px minmax(0, 1fr);
  gap: 14px;
  padding: 18px 0;
  border-top: 1px solid var(--color-border);
}

.review:first-child {
  border-top: 0;
}

.review-top {
  display: flex;
  flex-wrap: wrap;
  /* Baseline, so the name, score, status and time share one text line. */
  align-items: baseline;
  gap: 6px 10px;
  margin-bottom: 6px;
  font-size: 0.875rem;
}

.review-user {
  font-weight: 600;
  color: var(--color-text-primary);
}

.review-user:hover {
  text-decoration: underline;
}

.review-top time {
  margin-left: auto;
  font-size: 0.8125rem;
  color: var(--color-text-secondary);
}

.review-score,
.review-status {
  display: inline-flex;
  align-items: center;
  height: 22px;
  padding: 0 8px;
  border-radius: var(--radius-pill);
  line-height: 1;
}

.review-score {
  position: relative;
  font-variant-numeric: tabular-nums;
  color: #fff;
  font-size: 0.75rem;
  font-weight: 700;
}

.r-great {
  background: #16a34a;
}
.r-good {
  background: #2563eb;
}
.r-ok {
  background: #b45309;
}
.r-low {
  background: #dc2626;
}

.review-status {
  --status: #6b7280;
  background: color-mix(in srgb, var(--status) 14%, transparent);
  color: color-mix(in srgb, var(--status) 80%, var(--color-text-primary));
  font-size: 0.75rem;
  font-weight: 600;
}

.st-in-progress {
  --status: #3b82f6;
}
.st-completed {
  --status: #22c55e;
}
.st-fully-completed {
  --status: #16a34a;
}
.st-paused {
  --status: #f59e0b;
}
.st-dropped {
  --status: #ef4444;
}
.st-unplayed {
  --status: #a855f7;
}

.review-text {
  font-size: 0.9375rem;
  line-height: 1.6;
  white-space: pre-line;
  overflow-wrap: anywhere;
  color: var(--color-text-primary);
}

.review-more {
  padding: 0;
  border: 0;
  background: none;
  color: var(--color-accent);
  font: inherit;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
}

.review-more:hover {
  text-decoration: underline;
}

.review-meta {
  margin-top: 8px;
  font-size: 0.8125rem;
  color: var(--color-text-secondary);
}

.review-load-more {
  width: 100%;
  min-height: 40px;
  margin-top: 4px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background: transparent;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
}

.review-load-more:hover {
  background: var(--color-bg-subtle);
}

.review-load-more:disabled {
  cursor: progress;
  opacity: 0.7;
}

.visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  margin: -1px;
  padding: 0;
  overflow: hidden;
  clip: rect(0 0 0 0);
  white-space: nowrap;
  border: 0;
}

@media (max-width: 768px) {
  .review {
    grid-template-columns: 32px minmax(0, 1fr);
    gap: 12px;
  }

  .review {
    --avatar-size: 32px;
    align-items: center;
    row-gap: 10px;
  }

  /* Let the header sit beside the avatar while the review text and meta span
     the full card width, instead of leaving a column of dead space under the
     avatar on narrow screens. */
  .review-body {
    display: contents;
  }

  .review-top {
    margin-bottom: 0;
  }

  .review-text,
  .review-meta {
    grid-column: 1 / -1;
  }

  /* Always put the time on its own line. Otherwise it wraps or doesn't
     depending on name length and which badges a review has, so neighbouring
     reviews end up with different header layouts. */
  .review-top time {
    flex-basis: 100%;
    margin-left: 0;
  }

  .review-sorts {
    flex-wrap: nowrap;
    overflow-x: auto;
    margin-right: -16px;
    padding-right: 16px;
  }

  .review-sorts button {
    flex-shrink: 0;
  }
}
</style>
