<template>
  <section class="res-games" :aria-label="label">
    <div class="res-toolbar">
      <div class="res-seg" role="group" aria-label="Sort games">
        <button
          v-for="option in RESOURCE_GAME_SORTS"
          :key="option.value"
          type="button"
          class="res-seg-btn"
          :class="{ 'is-active': option.value === sortBy }"
          :aria-pressed="option.value === sortBy"
          @click="sortBy = option.value"
        >
          {{ option.label }}
        </button>
      </div>
    </div>

    <p v-if="!games.length && !refreshing" class="res-empty">{{ emptyText }}</p>

    <ul class="res-grid" :class="{ 'is-refreshing': refreshing }" :aria-busy="refreshing">
      <li v-for="game in games" :key="game.id">
        <router-link :to="{ name: 'game', params: { id: game.id } }" class="res-card">
          <span class="res-cover">
            <img v-if="game.coverUrl" :src="game.coverUrl" alt="" loading="lazy" />
            <span v-else class="res-cover-ph" aria-hidden="true">{{ initials(game.name) }}</span>
            <span v-if="game.isInLibrary" class="res-owned">
              <Check :size="11" :stroke-width="3" aria-hidden="true" />
              In library
            </span>
          </span>
          <b class="res-card-name">{{ game.name }}</b>
          <span v-if="game.releaseDate" class="res-card-meta">{{ game.releaseDate.slice(0, 4) }}</span>
        </router-link>
      </li>
    </ul>

    <p v-if="loadMoreError" class="res-load-error" role="alert">Failed to load more games: {{ loadMoreError }}</p>

    <div v-if="hasNextPage" class="res-more">
      <button type="button" class="res-more-btn" :disabled="loadingMore" @click="emit('loadMore')">
        {{ loadingMore ? "Loading…" : "Show more games" }}
      </button>
    </div>
  </section>
</template>

<script setup lang="ts">
import { Check } from "@lucide/vue";
import { RESOURCE_GAME_SORTS } from "@/composables/useResourceGames";
import type { ResourceGameFieldsFragment, ResourceGameSort } from "@/types/graphql";

defineProps<{
  label: string;
  games: ResourceGameFieldsFragment[];
  emptyText: string;
  // A new sort order is loading; the current games stay up, dimmed.
  refreshing: boolean;
  hasNextPage: boolean;
  loadingMore: boolean;
  loadMoreError?: string | null;
}>();

const sortBy = defineModel<ResourceGameSort>("sortBy", { required: true });

const emit = defineEmits<{
  loadMore: [];
}>();

function initials(name: string): string {
  return name
    .split(/[\s:]+/)
    .filter((w) => w.length > 0)
    .slice(0, 3)
    .map((w) => w[0].toUpperCase())
    .join("");
}
</script>

<style scoped>
.res-games {
  padding: 1.5rem 0 1rem;
}

.res-toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  margin-bottom: 1rem;
}

.res-seg {
  display: inline-flex;
  max-width: 100%;
  overflow-x: auto;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
}

.res-seg-btn {
  position: relative;
  padding: 6px 12px;
  font: inherit;
  font-size: 0.75rem;
  white-space: nowrap;
  color: var(--color-text-secondary);
  background: none;
  border: 0;
  cursor: pointer;
}

.res-seg-btn + .res-seg-btn::before {
  content: "";
  position: absolute;
  left: 0;
  top: 25%;
  height: 50%;
  width: 1px;
  background: var(--color-border);
}

.res-seg-btn:hover {
  color: var(--color-text-primary);
}

.res-seg-btn.is-active {
  background: color-mix(in srgb, var(--color-accent) 14%, transparent);
  color: var(--color-accent);
  font-weight: 500;
}

.res-seg-btn:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: -2px;
}

.res-empty {
  color: var(--color-text-secondary);
  font-size: 0.875rem;
}

.res-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(170px, 1fr));
  gap: 24px 16px;
  transition: opacity var(--transition-normal);
}

@media screen and (max-width: 768px) {
  .res-grid {
    grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
    gap: 20px 12px;
  }
}

.res-grid.is-refreshing {
  opacity: 0.5;
}

.res-card {
  display: block;
  color: var(--color-text-primary);
  border-radius: var(--radius-md);
}

.res-card:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 4px;
}

.res-cover {
  position: relative;
  display: block;
  aspect-ratio: 3 / 4;
  overflow: hidden;
  border-radius: 10px;
  background: var(--color-bg-subtle);
  transition:
    transform var(--transition-fast),
    box-shadow var(--transition-fast);
}

.res-card:hover .res-cover {
  transform: translateY(-2px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
}

@media (prefers-color-scheme: dark) {
  .res-card:hover .res-cover {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.4);
  }
}

.res-cover img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.res-cover-ph {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #e879a0 0%, #c266d6 50%, #7c5ce7 100%);
  color: #fff;
  font-size: 1.75rem;
  font-weight: 700;
  letter-spacing: 0.05em;
  user-select: none;
}

.res-owned {
  position: absolute;
  top: 6px;
  left: 6px;
  display: inline-flex;
  align-items: center;
  gap: 3px;
  padding: 2px 7px 2px 5px;
  font-size: 0.625rem;
  font-weight: 600;
  color: #fff;
  background: rgba(17, 11, 36, 0.72);
  border-radius: 999px;
  backdrop-filter: blur(4px);
}

.res-card-name {
  display: block;
  margin-top: 8px;
  font-size: 0.8125rem;
  font-weight: 600;
  line-height: 1.3;
}

.res-card:hover .res-card-name {
  color: var(--color-accent);
}

.res-card-meta {
  display: block;
  margin-top: 2px;
  font-size: 0.72rem;
  color: var(--color-text-secondary);
}

.res-load-error {
  margin-top: 1.5rem;
  color: var(--r-500);
  font-size: 0.875rem;
}

.res-more {
  display: flex;
  justify-content: center;
  margin-top: 2rem;
}

.res-more-btn {
  padding: 8px 20px;
  font: inherit;
  font-size: 0.8rem;
  font-weight: 500;
  color: var(--color-text-secondary);
  background: transparent;
  border: 1px solid var(--color-border);
  border-radius: 999px;
  cursor: pointer;
}

.res-more-btn:hover:not(:disabled) {
  color: var(--color-text-primary);
  border-color: var(--color-text-tertiary);
}

.res-more-btn:disabled {
  cursor: progress;
  opacity: 0.7;
}

.res-more-btn:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}
</style>
