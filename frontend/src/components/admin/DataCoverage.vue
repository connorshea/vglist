<template>
  <section class="admin-section" aria-labelledby="data-coverage-heading">
    <div class="admin-section-header">
      <h2 id="data-coverage-heading" class="admin-section-title">
        Data coverage
        <span class="admin-section-note">share of {{ stats.games.toLocaleString() }} games</span>
      </h2>
    </div>

    <div class="coverage-card">
      <template v-for="group in groups" :key="group.label">
        <h3 class="coverage-group">{{ group.label }}</h3>
        <ul class="coverage-list">
          <li v-for="row in group.rows" :key="row.label" class="coverage-row">
            <span class="coverage-label">{{ row.label }}</span>
            <span class="coverage-track" aria-hidden="true">
              <span class="coverage-fill" :class="{ 'is-low': row.low }" :style="{ width: row.width }"></span>
            </span>
            <span class="coverage-count">
              <strong>{{ row.count }}</strong>
              <span class="coverage-percent">{{ row.percent }}</span>
            </span>
          </li>
        </ul>
      </template>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed } from "vue";
import type { GetLiveStatisticsQuery } from "@/types/graphql";

type LiveStatistics = NonNullable<GetLiveStatisticsQuery["liveStatistics"]>;

const props = defineProps<{ stats: LiveStatistics }>();

/** Below this share, a bar turns orange to flag the gap. */
const LOW_COVERAGE = 0.25;

function row(label: string, count: number) {
  const total = props.stats.games;
  const share = total > 0 ? count / total : 0;
  return {
    label,
    count: count.toLocaleString(),
    percent: `${(share * 100).toFixed(1)}%`,
    // Keep a sliver visible for tiny non-zero shares.
    width: `${count > 0 ? Math.max(share * 100, 0.8) : 0}%`,
    low: share < LOW_COVERAGE
  };
}

const groups = computed(() => {
  const s = props.stats;
  const externalIds: [string, number][] = [
    ["Wikidata", s.wikidataIds],
    ["IGDB", s.igdbIds ?? 0],
    ["MobyGames", s.mobygamesIds],
    ["Steam", s.steamAppIds],
    ["GiantBomb", s.giantbombIds],
    ["PCGamingWiki", s.pcgamingwikiIds],
    ["GOG", s.gogIds],
    ["Epic Games Store", s.epicGamesStoreIds]
  ];

  return [
    {
      label: "Game details",
      rows: [row("Release dates", s.gamesWithReleaseDates), row("Covers", s.gamesWithCovers)]
    },
    {
      label: "External IDs",
      rows: externalIds.sort((a, b) => b[1] - a[1]).map(([label, count]) => row(label, count))
    }
  ];
});
</script>

<style scoped>
.coverage-card {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  column-gap: 40px;
  padding: 8px 20px 12px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background: var(--color-surface);
}

.coverage-group {
  grid-column: 1 / -1;
  margin: 14px 0 2px;
  font-size: 0.6875rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--color-text-secondary);
}

/* The rows flow straight into the card's two-column grid. */
.coverage-list {
  display: contents;
}

.coverage-row {
  display: grid;
  grid-template-columns: 120px minmax(0, 1fr) 132px;
  align-items: center;
  gap: 14px;
  padding: 9px 0;
  border-bottom: 1px solid var(--color-border);
  font-size: 0.8125rem;
}

.coverage-label {
  font-weight: 500;
  white-space: nowrap;
  color: var(--color-text-primary);
}

.coverage-track {
  height: 8px;
  border-radius: 99px;
  background: var(--admin-track);
  overflow: hidden;
}

.coverage-fill {
  display: block;
  height: 100%;
  border-radius: 99px;
  background: var(--admin-spark);
}

.coverage-fill.is-low {
  background: var(--admin-low);
}

.coverage-count {
  text-align: right;
  white-space: nowrap;
  font-variant-numeric: tabular-nums;
  color: var(--color-text-primary);
}

.coverage-count strong {
  font-weight: 600;
  color: inherit;
}

.coverage-percent {
  display: inline-block;
  min-width: 44px;
  margin-left: 6px;
  color: var(--color-text-secondary);
}

@media (max-width: 768px) {
  .coverage-card {
    display: block;
    padding: 4px 14px 8px;
  }

  .coverage-list {
    display: block;
    margin: 0;
  }

  .coverage-row {
    grid-template-columns: minmax(0, 1fr) auto;
    row-gap: 6px;
    column-gap: 10px;
    padding: 10px 0;
  }

  .coverage-track {
    grid-column: 1 / -1;
    grid-row: 2;
  }
}
</style>
