<template>
  <section class="admin-section" aria-labelledby="statistics-overview-heading">
    <div class="admin-section-header">
      <h2 id="statistics-overview-heading" class="admin-section-title">
        Overview
        <span class="admin-section-note">{{ snapshotNote }}</span>
      </h2>
      <div class="range-switcher" role="group" aria-label="Trend range">
        <button
          v-for="range in RANGES"
          :key="range.days"
          type="button"
          class="range-button"
          :class="{ 'is-active': rangeDays === range.days }"
          :aria-pressed="rangeDays === range.days"
          :aria-label="`Past ${range.days} days`"
          @click="rangeDays = range.days"
        >
          {{ range.label }}
        </button>
      </div>
    </div>

    <div class="kpi-grid">
      <div v-for="tile in featuredTiles" :key="tile.field" class="kpi-tile">
        <span class="kpi-label">{{ tile.label }}</span>
        <span class="kpi-value">{{ tile.value }}</span>
        <span class="kpi-delta" :class="{ 'is-up': tile.up }">
          <ArrowUp v-if="tile.up" :size="12" :stroke-width="2.5" aria-hidden="true" />
          {{ tile.deltaText }}
        </span>
        <svg
          v-if="tile.line"
          class="kpi-sparkline"
          viewBox="0 0 120 36"
          preserveAspectRatio="none"
          aria-hidden="true"
          focusable="false"
        >
          <polygon class="kpi-sparkline-area" :points="`0,36 ${tile.line} 120,36`" />
          <polyline class="kpi-sparkline-line" :points="tile.line" />
        </svg>
      </div>
    </div>

    <dl class="mini-grid">
      <div v-for="tile in compactTiles" :key="tile.field" class="mini-tile">
        <dt class="mini-label">{{ tile.label }}</dt>
        <dd class="mini-values">
          <span class="kpi-delta" :class="{ 'is-up': tile.up }">
            <span v-if="tile.delta === null || tile.delta === 0" aria-label="No change">—</span>
            <template v-else>{{ tile.shortDelta }}</template>
          </span>
          <span class="mini-value">{{ tile.value }}</span>
        </dd>
      </div>
    </dl>
  </section>
</template>

<script setup lang="ts">
import { computed, ref } from "vue";
import { ArrowUp } from "@lucide/vue";
import { computeTrend, sparklinePoints } from "@/utils/statisticTrends";
import type { GetLiveStatisticsQuery, GetSiteStatisticsQuery } from "@/types/graphql";

type LiveStatistics = NonNullable<GetLiveStatisticsQuery["liveStatistics"]>;
type Snapshot = NonNullable<GetSiteStatisticsQuery["siteStatistics"]>["nodes"][number];
type TrendField = keyof LiveStatistics & keyof Snapshot;

interface TileDefinition {
  field: TrendField;
  label: string;
  /** Growth isn't good news for this one, so don't colour it as such. */
  neutral?: boolean;
}

const props = defineProps<{
  stats: LiveStatistics;
  /** Daily snapshots, newest first. */
  history: Snapshot[];
  /** Injectable for tests. */
  now?: Date;
}>();

const RANGES = [
  { days: 7, label: "7d" },
  { days: 30, label: "30d" },
  { days: 90, label: "90d" }
] as const;

const FEATURED: TileDefinition[] = [
  { field: "users", label: "Users" },
  { field: "games", label: "Games" },
  { field: "gamePurchases", label: "Library entries" },
  { field: "events", label: "Activity events" }
];

const COMPACT: TileDefinition[] = [
  { field: "companies", label: "Companies" },
  { field: "series", label: "Series" },
  { field: "engines", label: "Engines" },
  { field: "platforms", label: "Platforms" },
  { field: "genres", label: "Genres" },
  { field: "stores", label: "Stores" },
  { field: "relationships", label: "Follows" },
  { field: "bannedUsers", label: "Banned users", neutral: true }
];

const rangeDays = ref<number>(30);

const shortDate = new Intl.DateTimeFormat(undefined, { month: "short", day: "numeric", timeZone: "UTC" });
const snapshotFormat = new Intl.DateTimeFormat(undefined, {
  dateStyle: "medium",
  timeStyle: "short",
  timeZone: "UTC"
});

const snapshotNote = computed(() => {
  const latest = props.history[0];
  if (!latest) {
    return "Live counts";
  }
  return `Live counts · last snapshot ${snapshotFormat.format(new Date(latest.timestamp))} UTC`;
});

function signed(n: number): string {
  if (n > 0) {
    return `+${n.toLocaleString()}`;
  }
  // A real minus sign rather than a hyphen.
  if (n < 0) {
    return `−${Math.abs(n).toLocaleString()}`;
  }
  return "0";
}

function buildTile(definition: TileDefinition) {
  const current = props.stats[definition.field] ?? 0;
  const trend = computeTrend(
    props.history.map((snapshot) => ({ timestamp: snapshot.timestamp, value: snapshot[definition.field] })),
    current,
    rangeDays.value,
    props.now ?? new Date()
  );
  const period = trend.partialSince
    ? `since ${shortDate.format(new Date(trend.partialSince))}`
    : `in ${rangeDays.value} days`;

  let deltaText: string;
  if (trend.delta === null) {
    deltaText = "No history yet";
  } else if (trend.delta === 0) {
    deltaText = `No change ${period}`;
  } else {
    deltaText = `${signed(trend.delta)} ${period}`;
  }

  return {
    field: definition.field,
    label: definition.label,
    value: current.toLocaleString(),
    delta: trend.delta,
    shortDelta: trend.delta === null ? "" : signed(trend.delta),
    deltaText,
    up: !definition.neutral && trend.delta !== null && trend.delta > 0,
    line: trend.points.length > 1 ? sparklinePoints(trend.points, 120, 36) : ""
  };
}

const featuredTiles = computed(() => FEATURED.map(buildTile));
const compactTiles = computed(() => COMPACT.map(buildTile));
</script>

<style scoped>
.range-switcher {
  display: inline-flex;
  padding: 3px;
  gap: 2px;
  border-radius: 8px;
  background: var(--color-bg-subtle);
  border: 1px solid var(--color-border);
}

.range-button {
  appearance: none;
  border: 0;
  background: transparent;
  color: var(--color-text-secondary);
  font: inherit;
  font-size: 0.8125rem;
  font-weight: 500;
  padding: 0.25rem 0.75rem;
  min-width: 44px;
  border-radius: 6px;
  cursor: pointer;
}

.range-button:hover {
  color: var(--color-text-primary);
}

.range-button.is-active {
  background: var(--color-surface);
  color: var(--color-text-primary);
  font-weight: 600;
  box-shadow: 0 1px 2px rgb(0 0 0 / 0.08);
}

.range-button:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 1px;
}

.kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
}

.kpi-tile {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
  padding: 14px 16px 12px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background: var(--color-surface);
}

.kpi-label {
  font-size: 0.75rem;
  font-weight: 500;
  color: var(--color-text-secondary);
}

.kpi-value {
  font-size: 1.75rem;
  font-weight: 650;
  letter-spacing: -0.5px;
  line-height: 1.2;
  font-variant-numeric: tabular-nums;
  color: var(--color-text-primary);
}

.kpi-delta {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 0.75rem;
  font-variant-numeric: tabular-nums;
  color: var(--color-text-secondary);
}

.kpi-delta.is-up {
  color: var(--admin-up);
  font-weight: 600;
}

.kpi-sparkline {
  display: block;
  width: 100%;
  height: 36px;
  margin-top: 8px;
  overflow: visible;
}

.kpi-sparkline-line {
  fill: none;
  stroke: var(--admin-spark);
  stroke-width: 1.75;
  stroke-linejoin: round;
  vector-effect: non-scaling-stroke;
}

.kpi-sparkline-area {
  fill: var(--admin-spark);
  opacity: 0.12;
}

.mini-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
  margin: 12px 0 0;
}

.mini-tile {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 8px;
  min-width: 0;
  padding: 10px 16px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
}

.mini-label {
  font-size: 0.8125rem;
  color: var(--color-text-secondary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.mini-values {
  display: flex;
  align-items: baseline;
  gap: 8px;
  margin: 0;
}

.mini-value {
  font-size: 1rem;
  font-weight: 600;
  font-variant-numeric: tabular-nums;
  color: var(--color-text-primary);
}

@media (max-width: 1023px) {
  .kpi-grid,
  .mini-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 768px) {
  .kpi-grid {
    gap: 10px;
  }

  .kpi-tile {
    padding: 12px 12px 10px;
  }

  .kpi-value {
    font-size: 1.375rem;
  }

  .kpi-sparkline {
    height: 28px;
  }

  /* One bordered list rather than a grid of small boxes. */
  .mini-grid {
    grid-template-columns: 1fr;
    gap: 0;
    border: 1px solid var(--color-border);
    border-radius: var(--radius-md);
  }

  .mini-tile {
    border: 0;
    border-radius: 0;
    border-bottom: 1px solid var(--color-border);
    padding: 11px 14px;
  }

  .mini-tile:last-child {
    border-bottom: 0;
  }

  .mini-label {
    font-size: 0.875rem;
  }
}
</style>
