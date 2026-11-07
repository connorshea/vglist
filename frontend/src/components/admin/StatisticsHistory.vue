<template>
  <section class="box mt-5" aria-labelledby="statistics-history-heading">
    <div class="history-header">
      <h3 id="statistics-history-heading" class="has-text-weight-bold">Statistics Over Time</h3>
      <div class="group-switcher" role="tablist" aria-label="Statistic group">
        <button
          v-for="(group, index) in GROUPS"
          :id="`statistics-history-tab-${group.key}`"
          :key="group.key"
          :ref="(el) => (tabRefs[index] = el as HTMLButtonElement | null)"
          type="button"
          role="tab"
          class="group-tab"
          :class="{ 'is-active': activeGroup === group.key }"
          :aria-selected="activeGroup === group.key"
          aria-controls="statistics-history-panel"
          :tabindex="activeGroup === group.key ? 0 : -1"
          @click="activeGroup = group.key"
          @keydown="onTabKeydown($event, index)"
        >
          {{ group.label }}
        </button>
      </div>
    </div>

    <div id="statistics-history-panel" role="tabpanel" :aria-labelledby="`statistics-history-tab-${activeGroup}`">
      <div v-if="loading && !data" class="has-text-centered py-5">Loading statistics history...</div>
      <div v-if="error" class="notification is-danger">{{ error.message }}</div>

      <template v-if="data">
        <p v-if="rows.length === 0" class="has-text-centered has-text-grey py-4">
          No statistics have been recorded yet.
        </p>
        <div v-else class="table-container">
          <table class="table is-fullwidth is-narrow history-table">
            <caption class="is-sr-only">
              {{
                currentGroup.label
              }}
              statistics, newest first
            </caption>
            <thead>
              <tr>
                <th scope="col" class="date-col">Date</th>
                <th v-for="column in currentGroup.columns" :key="column.field" scope="col" class="has-text-right">
                  {{ column.label }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in rows" :key="row.id">
                <th scope="row" class="date-col">
                  <time :datetime="row.timestamp" :title="formatTimestamp(row.timestamp)">{{
                    formatDate(row.timestamp)
                  }}</time>
                </th>
                <td v-for="column in currentGroup.columns" :key="column.field" class="has-text-right">
                  {{ formatCount(row[column.field]) }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <PaginationNav
          v-if="currentPage > 1 || hasNextPage"
          :current-page="currentPage"
          :has-next-page="hasNextPage"
          :loading="loading"
          @prev="prevPage"
          @next="nextPage"
        />
      </template>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { useQuery } from "@/composables/useGraphQL";
import { GET_SITE_STATISTICS } from "@/graphql/queries/admin";
import type { GetSiteStatisticsQuery } from "@/types/graphql";
import PaginationNav from "@/components/PaginationNav.vue";

type StatisticRow = NonNullable<GetSiteStatisticsQuery["siteStatistics"]>["nodes"][number];
type CountField = Exclude<keyof StatisticRow, "id" | "timestamp">;

interface Column {
  field: CountField;
  label: string;
}

interface Group {
  key: "counts" | "externalIds" | "versions";
  label: string;
  columns: Column[];
}

const GROUPS: Group[] = [
  {
    key: "counts",
    label: "Counts",
    columns: [
      { field: "users", label: "Users" },
      { field: "games", label: "Games" },
      { field: "platforms", label: "Platforms" },
      { field: "series", label: "Series" },
      { field: "engines", label: "Engines" },
      { field: "companies", label: "Companies" },
      { field: "genres", label: "Genres" },
      { field: "stores", label: "Stores" },
      { field: "events", label: "Events" },
      { field: "gamePurchases", label: "Game Purchases" },
      { field: "relationships", label: "Relationships" },
      { field: "gamesWithCovers", label: "Games with Covers" },
      { field: "gamesWithReleaseDates", label: "Games with Release Dates" },
      { field: "bannedUsers", label: "Banned Users" },
      { field: "unmatchedGames", label: "Unmatched Games" }
    ]
  },
  {
    key: "externalIds",
    label: "External IDs",
    columns: [
      { field: "mobygamesIds", label: "MobyGames" },
      { field: "pcgamingwikiIds", label: "PCGamingWiki" },
      { field: "wikidataIds", label: "Wikidata" },
      { field: "giantbombIds", label: "GiantBomb" },
      { field: "steamAppIds", label: "Steam" },
      { field: "epicGamesStoreIds", label: "Epic Games Store" },
      { field: "gogIds", label: "GOG" },
      { field: "igdbIds", label: "IGDB" }
    ]
  },
  {
    key: "versions",
    label: "Versions",
    columns: [
      { field: "companyVersions", label: "Companies" },
      { field: "gameVersions", label: "Games" },
      { field: "genreVersions", label: "Genres" },
      { field: "engineVersions", label: "Engines" },
      { field: "platformVersions", label: "Platforms" },
      { field: "seriesVersions", label: "Series" }
    ]
  }
];

const PAGE_SIZE = 30;

const activeGroup = ref<Group["key"]>("counts");
const currentGroup = computed(() => GROUPS.find((group) => group.key === activeGroup.value) ?? GROUPS[0]!);
const tabRefs = ref<(HTMLButtonElement | null)[]>([]);

// Arrow keys move between tabs (WAI-ARIA tabs pattern), with automatic activation.
function onTabKeydown(event: KeyboardEvent, index: number) {
  let next: number;
  if (event.key === "ArrowRight") next = (index + 1) % GROUPS.length;
  else if (event.key === "ArrowLeft") next = (index - 1 + GROUPS.length) % GROUPS.length;
  else if (event.key === "Home") next = 0;
  else if (event.key === "End") next = GROUPS.length - 1;
  else return;

  event.preventDefault();
  activeGroup.value = GROUPS[next]!.key;
  tabRefs.value[next]?.focus();
}

const currentPage = ref(1);
const pageCursors = ref<(string | null)[]>([null]);

const { data, loading, error } = useQuery<GetSiteStatisticsQuery>(GET_SITE_STATISTICS, {
  variables: () => ({
    first: PAGE_SIZE,
    after: pageCursors.value[currentPage.value - 1]
  })
});

const rows = computed(() => data.value?.siteStatistics?.nodes ?? []);
const hasNextPage = computed(() => data.value?.siteStatistics?.pageInfo.hasNextPage ?? false);

watch(data, (val) => {
  const endCursor = val?.siteStatistics?.pageInfo.endCursor;
  if (endCursor) pageCursors.value[currentPage.value] = endCursor;
});

function nextPage() {
  if (hasNextPage.value) currentPage.value++;
}

function prevPage() {
  if (currentPage.value > 1) currentPage.value--;
}

// The stats task runs once a day at midnight UTC, so show the UTC date (a
// local date would read as the previous day west of Greenwich) and keep the
// exact time in the tooltip.
const dateFormat = new Intl.DateTimeFormat(undefined, { dateStyle: "medium", timeZone: "UTC" });
const timestampFormat = new Intl.DateTimeFormat(undefined, {
  dateStyle: "medium",
  timeStyle: "short",
  timeZone: "UTC"
});

function formatDate(timestamp: string): string {
  return dateFormat.format(new Date(timestamp));
}

function formatTimestamp(timestamp: string): string {
  return `${timestampFormat.format(new Date(timestamp))} UTC`;
}

// Older records predate some columns (e.g. IGDB IDs, version counts), so
// those come back null.
function formatCount(value: number | null): string {
  return value === null ? "—" : value.toLocaleString();
}
</script>

<style scoped>
.history-header {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.group-switcher {
  display: inline-flex;
  padding: 3px;
  gap: 2px;
  border-radius: 8px;
  background: var(--color-bg-subtle);
  border: 1px solid var(--color-border);
}

.group-tab {
  appearance: none;
  border: 0;
  background: transparent;
  color: var(--color-text-secondary);
  font: inherit;
  font-size: 0.875rem;
  font-weight: 500;
  padding: 0.3rem 0.75rem;
  border-radius: 6px;
  cursor: pointer;
  white-space: nowrap;
}

.group-tab:hover {
  color: var(--color-text-primary);
}

.group-tab.is-active {
  background: var(--color-surface);
  color: var(--color-text-primary);
  font-weight: 600;
  box-shadow: 0 1px 2px rgb(0 0 0 / 0.08);
}

.group-tab:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 1px;
}

.history-table {
  font-variant-numeric: tabular-nums;
  font-size: 0.875rem;
  /* Sit on the box rather than Bulma's darker table background in dark mode. */
  background: transparent;
}

.history-table th {
  white-space: nowrap;
}

/* Keep the date visible while the wide table scrolls sideways. */
.history-table .date-col {
  position: sticky;
  left: 0;
  z-index: 1;
  background: var(--bulma-box-background-color, var(--color-surface));
  font-weight: 500;
  min-width: 8rem;
}

@media (max-width: 768px) {
  .history-header {
    flex-direction: column;
    align-items: stretch;
  }

  .group-switcher {
    align-self: stretch;
  }

  .group-tab {
    flex: 1;
    padding-inline: 0.5rem;
  }
}
</style>
