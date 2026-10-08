<template>
  <RouterLink :to="recordPath('games', game.id)" class="result-row">
    <div class="result-cover">
      <img v-if="game.coverUrl" :src="game.coverUrl" alt="" loading="lazy" />
      <div v-else class="cover-placeholder" aria-hidden="true">{{ game.name.charAt(0).toUpperCase() }}</div>
    </div>

    <div class="result-body">
      <div class="result-heading">
        <span class="result-name">{{ game.name }}</span>
        <span v-if="game.isInLibrary === true" class="library-badge">
          <Check :size="12" :stroke-width="2.5" aria-hidden="true" />
          In your library
        </span>
      </div>

      <p v-if="metaParts.length" class="result-meta">{{ metaParts.join(" · ") }}</p>

      <div v-if="platforms.shown.length || game.series" class="result-tags">
        <!-- No aria-label here: the row is one link named by its text, and a
             label would replace the platform names in that name. -->
        <ul v-if="platforms.shown.length" class="platform-list">
          <li v-for="name in platforms.shown" :key="name" class="platform-chip">{{ name }}</li>
          <li v-if="platforms.hiddenCount > 0" class="platform-chip platform-more" :title="platforms.hiddenLabel">
            <span aria-hidden="true">+{{ platforms.hiddenCount }}</span>
            <span class="is-sr-only">Also on {{ platforms.hiddenLabel }}</span>
          </li>
        </ul>
        <span v-if="game.series" class="result-series">Series: {{ game.series.name }}</span>
      </div>
    </div>
  </RouterLink>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { Check } from "@lucide/vue";
import { recordPath } from "@/utils/search";
import type { SearchGameFieldsFragment } from "@/types/graphql";

const props = defineProps<{
  game: SearchGameFieldsFragment;
}>();

const MAX_PLATFORM_CHIPS = 4;

// Platforms are what tell same-named games apart, so show a few as chips and
// summarize the rest (in the title on hover, and in full for screen readers).
// Only the first few platforms are fetched, so `totalCount` covers the others.
const platforms = computed(() => {
  const names = props.game.platforms.nodes.map((p) => p.name);
  const total = props.game.platforms.totalCount;
  const hidden = names.slice(MAX_PLATFORM_CHIPS);
  const unfetched = total - names.length;

  return {
    shown: names.slice(0, MAX_PLATFORM_CHIPS),
    hiddenCount: Math.max(total - MAX_PLATFORM_CHIPS, 0),
    hiddenLabel: (unfetched > 0 ? [...hidden, `and ${unfetched} more`] : hidden).join(", ")
  };
});

const metaParts = computed(() => {
  const parts: string[] = [];
  if (props.game.releaseDate) parts.push(props.game.releaseDate.split("-")[0]);

  const companies = [...props.game.developers.nodes, ...props.game.publishers.nodes]
    .map((c) => c.name)
    .filter((name, i, all) => all.indexOf(name) === i);
  if (companies.length) parts.push(companies.join(" / "));

  return parts;
});
</script>

<style scoped>
.result-row {
  display: flex;
  gap: 14px;
  padding: 10px 12px;
  border-radius: 8px;
  color: inherit;
}

.result-row:hover {
  background: var(--color-bg-subtle);
}

.result-row:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.result-cover {
  flex: 0 0 48px;
  height: 64px;
  border-radius: 4px;
  overflow: hidden;
  background: var(--color-bg-subtle);
}

.result-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.cover-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  font-weight: 600;
  color: var(--color-text-tertiary);
}

.result-body {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.result-heading {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
}

.result-name {
  font-weight: 600;
  color: var(--color-text-primary);
}

.library-badge {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  padding: 1px 7px;
  border-radius: 999px;
  font-size: 0.75rem;
  color: var(--color-accent);
  border: 1px solid currentColor;
}

.result-meta,
.result-series {
  font-size: 0.85rem;
  color: var(--color-text-secondary);
}

.result-tags {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px 10px;
}

.platform-list {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  list-style: none;
  margin: 0;
  padding: 0;
}

.platform-chip {
  padding: 1px 7px;
  border-radius: 4px;
  font-size: 0.75rem;
  color: var(--color-text-secondary);
  background: var(--color-bg-subtle);
  border: 1px solid var(--color-border);
}
</style>
