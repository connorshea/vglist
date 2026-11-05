<template>
  <div class="games-index">
    <div class="page-header">
      <h1 class="page-title">Games</h1>
      <span v-if="headerCount !== null" class="page-sub" aria-live="polite">{{ headerCount }}</span>
    </div>

    <nav class="sort-tabs" aria-label="Sort games">
      <router-link
        v-for="option in GAME_SORTS"
        :key="option.slug"
        :to="{ query: queryFor(option, filters) }"
        class="sort-tab"
        :class="{ on: sort === option }"
        :aria-current="sort === option ? 'page' : undefined"
      >
        <component :is="SORT_ICONS[option.slug]" :size="15" aria-hidden="true" />
        {{ option.label }}
      </router-link>
    </nav>

    <div class="facets">
      <span class="facets-label" id="platform-pills-label">Platform</span>
      <div class="platform-pills" role="group" aria-labelledby="platform-pills-label">
        <button
          type="button"
          class="filter-pill"
          :class="{ on: !filters.platform }"
          :aria-pressed="!filters.platform"
          @click="setPlatform(null)"
        >
          All
        </button>
        <button
          v-for="platform in platformPills"
          :key="platform.id"
          type="button"
          class="filter-pill"
          :class="{ on: filters.platform === platform.id }"
          :aria-pressed="filters.platform === platform.id"
          @click="setPlatform(platform)"
        >
          {{ platform.name }}
        </button>
      </div>
      <span class="grow"></span>
      <div ref="moreRef" class="more-filters">
        <button
          ref="moreButtonRef"
          type="button"
          class="more-btn"
          :class="{ on: moreCount > 0 || panelOpen }"
          :aria-expanded="panelOpen && !isPhone"
          aria-controls="games-more-filters"
          @click="togglePanel"
        >
          <ListFilter :size="14" aria-hidden="true" />
          More filters
          <span v-if="moreCount > 0" class="count-badge"> {{ moreCount }}<span class="is-sr-only"> active</span> </span>
        </button>
        <GamesFilterPanel
          v-if="panelOpen && !isPhone"
          id="games-more-filters"
          v-model="draft"
          variant="popover"
          :names="draftNames"
          :genres="topGenres"
          :count="draftCount"
          :signed-in="authStore.isAuthenticated"
          @named="rememberName"
          @apply="applyDraft"
          @close="closePanel"
        />
      </div>
    </div>

    <div v-if="activeChips.length" class="active-filters">
      <span v-for="chip in activeChips" :key="chip.key" class="filter-chip">
        {{ chip.label }}
        <button
          type="button"
          class="filter-chip-remove"
          :aria-label="`Remove ${chip.label} filter`"
          @click="updateFilters(chip.clear)"
        >
          <X :size="12" aria-hidden="true" />
        </button>
      </span>
      <button v-if="activeChips.length > 1" type="button" class="clear-all" @click="updateFilters(EMPTY_FILTERS)">
        Clear all
      </button>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load games: {{ error.message }}</p>
    </div>

    <div v-if="!data && loading" class="loading-more" role="status">
      <span class="spinner" aria-hidden="true"></span>
      Loading games&hellip;
    </div>
    <div v-else-if="data && games.length === 0" class="empty-state">
      <p>No games match these filters.</p>
      <button v-if="activeChips.length || filters.platform" type="button" class="clear-all" @click="clearAll">
        Clear filters
      </button>
    </div>

    <ul v-if="games.length" class="games-grid" :class="{ 'is-stale': refreshing }">
      <li v-for="game in games" :key="game.id">
        <GameTile
          :id="game.id"
          :name="game.name"
          :cover-url="game.coverUrl ?? null"
          :meta="tileMeta(game)"
          :rating="game.avgRating"
          :in-library="game.isInLibrary"
          :completion-status="game.libraryCompletionStatus"
        />
      </li>
    </ul>

    <div v-if="hasNextPage" ref="sentinelRef" class="loading-more">
      <template v-if="loadingMore">
        <span class="spinner" aria-hidden="true"></span>
        <span role="status">Loading more games&hellip;</span>
      </template>
      <button v-else type="button" class="load-more-btn" @click="loadMore">Load more games</button>
    </div>

    <button
      v-if="isPhone"
      ref="fabRef"
      type="button"
      class="filters-fab"
      :aria-expanded="panelOpen"
      aria-controls="games-filter-sheet"
      @click="togglePanel"
    >
      <ListFilter :size="16" aria-hidden="true" />
      Filters
      <span v-if="phoneCount > 0" class="fab-count">{{ phoneCount }}<span class="is-sr-only"> active</span></span>
    </button>
    <template v-if="panelOpen && isPhone">
      <div class="sheet-scrim" aria-hidden="true" @click="closePanel"></div>
      <GamesFilterPanel
        id="games-filter-sheet"
        v-model="draft"
        variant="sheet"
        :names="draftNames"
        :genres="topGenres"
        :count="draftCount"
        :signed-in="authStore.isAuthenticated"
        @named="rememberName"
        @apply="applyDraft"
        @close="closePanel"
      />
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref, watch, type Component } from "vue";
import { useRoute, useRouter } from "vue-router";
import { CalendarDays, Flame, Heart, ListFilter, Plus, Star, X } from "@lucide/vue";
import { useQuery } from "@/composables/useGraphQL";
import { GET_GAMES_INDEX, GET_GAMES_INDEX_COUNT, GET_GAMES_INDEX_FILTERS } from "@/graphql/queries/games-index";
import { useAuthStore } from "@/stores/auth";
import type { GetGamesIndexCountQuery, GetGamesIndexFiltersQuery, GetGamesIndexQuery } from "@/types/graphql";
import GameTile from "@/components/games-index/GameTile.vue";
import GamesFilterPanel from "@/components/games-index/GamesFilterPanel.vue";
import {
  DEFAULT_GAME_SORT,
  EMPTY_FILTERS,
  GAME_SORTS,
  countLabel,
  filterVariables,
  filtersFromQuery,
  filtersToQuery,
  gameSortFromSlug,
  moreFiltersCount,
  tileMeta,
  type GameFilters,
  type GameSortOption
} from "@/components/games-index/format";

interface NamedRecord {
  id: string;
  name: string;
}

const PAGE_SIZE = 36;

const SORT_ICONS: Record<GameSortOption["slug"], Component> = {
  popular: Flame,
  new: CalendarDays,
  top: Star,
  favorited: Heart,
  added: Plus
};

const route = useRoute();
const router = useRouter();
const authStore = useAuthStore();

// Sort and filters live in the URL, so a view can be reloaded, shared and
// navigated back to.
const sort = computed(() => gameSortFromSlug(route.query.sort));
const filters = computed(() => filtersFromQuery(route.query));

function queryFor(option: GameSortOption, f: GameFilters) {
  return {
    ...(option === DEFAULT_GAME_SORT ? {} : { sort: option.slug }),
    ...filtersToQuery(f)
  };
}

function updateFilters(changes: Partial<GameFilters>) {
  void router.push({ query: queryFor(sort.value, { ...filters.value, ...changes }) });
}

function clearAll() {
  updateFilters(EMPTY_FILTERS);
}

// ── Games ──
const variables = computed(() => ({
  first: PAGE_SIZE,
  after: null as string | null,
  sortBy: sort.value.value,
  ...filterVariables(filters.value),
  // Counting means grouping every game under some sorts, so only the first
  // page asks for it. Later pages keep the count the first one got.
  withCount: true
}));

const { data, loading, error, fetchMore } = useQuery<GetGamesIndexQuery>(GET_GAMES_INDEX, {
  variables: () => variables.value
});

const games = computed(() => data.value?.games?.nodes ?? []);
const hasNextPage = computed(() => data.value?.games?.pageInfo.hasNextPage ?? false);
const loadingMore = ref(false);
// The grid is showing results for the previous sort or filters.
const refreshing = computed(() => loading.value && !loadingMore.value);

async function loadMore() {
  const cursor = data.value?.games?.pageInfo.endCursor;
  if (!cursor || loadingMore.value || refreshing.value) return;
  loadingMore.value = true;
  try {
    await fetchMore({ ...variables.value, after: cursor, withCount: false }, (prev, next) => ({
      games:
        prev.games && next.games
          ? {
              ...next.games,
              totalCount: prev.games.totalCount,
              nodes: [...prev.games.nodes, ...next.games.nodes]
            }
          : next.games
    }));
  } finally {
    loadingMore.value = false;
  }
}

// Load the next page as the end of the grid scrolls into view. The "Load
// more" button stays as a fallback for keyboards and when this doesn't fire.
const sentinelRef = ref<HTMLElement | null>(null);
let observer: IntersectionObserver | undefined;

watch(sentinelRef, (el, oldEl) => {
  if (oldEl) observer?.unobserve(oldEl);
  if (el) observer?.observe(el);
});

// ── Filter names, pills and the site-wide count ──
const { data: filtersData } = useQuery<GetGamesIndexFiltersQuery>(GET_GAMES_INDEX_FILTERS, {
  variables: () => ({
    platformId: filters.value.platform || "0",
    hasPlatform: !!filters.value.platform,
    genreId: filters.value.genre || "0",
    hasGenre: !!filters.value.genre,
    engineId: filters.value.engine || "0",
    hasEngine: !!filters.value.engine
  })
});

// Names of records picked in this session, so a pill or chip has a label
// before the filters query comes back with it.
const pickedNames = reactive<Record<string, string>>({});

function rememberName(record: NamedRecord) {
  pickedNames[record.id] = record.name;
}

function nameFor(id: string, fetched: NamedRecord | null | undefined): string | null {
  if (!id) return null;
  if (fetched?.id === id) return fetched.name;
  return pickedNames[id] ?? null;
}

const topGenres = computed(() => filtersData.value?.genres?.nodes ?? []);

const platformPills = computed(() => {
  const top = filtersData.value?.platforms?.nodes ?? [];
  const picked = filters.value.platform;
  const pickedName = nameFor(picked, filtersData.value?.platform);
  if (picked && pickedName && !top.some((p) => p.id === picked)) {
    return [...top, { id: picked, name: pickedName }];
  }
  return top;
});

function setPlatform(platform: NamedRecord | null) {
  if (platform) rememberName(platform);
  updateFilters({ platform: platform?.id ?? "" });
}

const headerCount = computed(() => {
  const anyFilter = Object.keys(filtersToQuery(filters.value)).length > 0;
  const shown = data.value?.games?.totalCount;
  if (anyFilter && shown !== undefined) return countLabel(shown, "game");
  const total = filtersData.value?.basicSiteStatistics.games;
  return total !== undefined ? countLabel(total, "game") : null;
});

const moreCount = computed(() => moreFiltersCount(filters.value));
const phoneCount = computed(() => moreCount.value + (filters.value.platform ? 1 : 0));

const activeChips = computed(() => {
  const f = filters.value;
  const chips: { key: string; label: string; clear: Partial<GameFilters> }[] = [];
  if (f.genre)
    chips.push({ key: "genre", label: nameFor(f.genre, filtersData.value?.genre) ?? "Genre", clear: { genre: "" } });
  if (f.fromYear || f.toYear) {
    let label: string;
    if (f.fromYear && f.toYear) label = f.fromYear === f.toYear ? f.fromYear : `${f.fromYear}–${f.toYear}`;
    else if (f.fromYear) label = `${f.fromYear} or later`;
    else label = `${f.toYear} or earlier`;
    chips.push({ key: "year", label, clear: { fromYear: "", toYear: "" } });
  }
  if (f.engine) {
    chips.push({
      key: "engine",
      label: nameFor(f.engine, filtersData.value?.engine) ?? "Engine",
      clear: { engine: "" }
    });
  }
  if (f.hideLibrary) chips.push({ key: "library", label: "Not in my library", clear: { hideLibrary: false } });
  return chips;
});

// ── Filter popover / sheet ──
const panelOpen = ref(false);
const draft = ref<GameFilters>({ ...EMPTY_FILTERS });
const moreRef = ref<HTMLElement | null>(null);
const moreButtonRef = ref<HTMLButtonElement | null>(null);
const fabRef = ref<HTMLButtonElement | null>(null);

const draftNames = computed(() => ({
  platform: nameFor(draft.value.platform, filtersData.value?.platform),
  genre: nameFor(draft.value.genre, filtersData.value?.genre),
  engine: nameFor(draft.value.engine, filtersData.value?.engine)
}));

const { data: countData } = useQuery<GetGamesIndexCountQuery>(GET_GAMES_INDEX_COUNT, {
  variables: () => filterVariables(draft.value),
  enabled: () => panelOpen.value
});
const draftCount = computed(() => countData.value?.games?.totalCount ?? null);

function togglePanel() {
  if (panelOpen.value) {
    closePanel();
    return;
  }
  draft.value = { ...filters.value };
  panelOpen.value = true;
}

function closePanel() {
  if (!panelOpen.value) return;
  panelOpen.value = false;
  void nextTick(() => (isPhone.value ? fabRef.value : moreButtonRef.value)?.focus());
}

function applyDraft() {
  updateFilters(draft.value);
  closePanel();
}

function onDocumentPointerDown(e: PointerEvent) {
  if (!panelOpen.value || isPhone.value) return;
  if (moreRef.value && !moreRef.value.contains(e.target as Node)) closePanel();
}

// Don't let the page scroll behind the phone sheet.
watch(
  () => panelOpen.value && isPhone.value,
  (locked) => {
    document.body.style.overflow = locked ? "hidden" : "";
  }
);

// ── Layout ──
const phoneQuery = window.matchMedia("(max-width: 768px)");
const isPhone = ref(phoneQuery.matches);

function onPhoneChange(e: MediaQueryListEvent) {
  isPhone.value = e.matches;
}

onMounted(() => {
  phoneQuery.addEventListener("change", onPhoneChange);
  document.addEventListener("pointerdown", onDocumentPointerDown);
  observer = new IntersectionObserver(
    (entries) => {
      if (entries.some((entry) => entry.isIntersecting)) void loadMore();
    },
    { rootMargin: "600px 0px" }
  );
  if (sentinelRef.value) observer.observe(sentinelRef.value);
});

onBeforeUnmount(() => {
  phoneQuery.removeEventListener("change", onPhoneChange);
  document.removeEventListener("pointerdown", onDocumentPointerDown);
  observer?.disconnect();
  document.body.style.overflow = "";
});
</script>

<style scoped>
.page-header {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 12px;
}

.page-title {
  font-size: 24px;
  font-weight: 600;
  letter-spacing: -0.3px;
  color: var(--color-text-primary);
}

.page-sub {
  font-size: 13px;
  color: var(--color-text-secondary);
}

/* Sort tabs */
.sort-tabs {
  display: flex;
  overflow-x: auto;
  overflow-y: hidden;
  /* The baseline is an inset shadow rather than a border so the active tab's
     underline can sit on it without a negative margin. That margin made the
     tabs 1px taller than the bar, which let the bar scroll vertically. */
  box-shadow: inset 0 -1px 0 var(--color-border);
  scrollbar-width: none;
}

.sort-tab {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 10px 16px;
  border-bottom: 2px solid transparent;
  color: var(--color-text-secondary);
  font-size: 14px;
  white-space: nowrap;
}

.sort-tab:hover {
  color: var(--color-text-primary);
}

.sort-tab.on {
  border-bottom-color: var(--color-accent);
  color: var(--color-accent);
  font-weight: 500;
}

/* Platform pills and More filters */
.facets {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 16px 0 24px;
}

.facets-label {
  margin-right: 4px;
  font-size: 12px;
  color: var(--color-text-tertiary);
  white-space: nowrap;
}

.platform-pills {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.grow {
  flex: 1;
}

.filter-pill {
  padding: 4.8px 12px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-pill);
  background: transparent;
  color: var(--color-text-secondary);
  font: inherit;
  font-size: 12px;
  white-space: nowrap;
  cursor: pointer;
}

.filter-pill:hover {
  border-color: var(--color-text-tertiary);
  color: var(--color-text-primary);
}

.filter-pill.on {
  border-color: var(--p-100);
  background: var(--p-100);
  color: var(--p-700);
  font-weight: 500;
}

.more-filters {
  position: relative;
  flex-shrink: 0;
}

.more-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 34px;
  padding: 0 12px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface);
  color: var(--color-text-primary);
  font: inherit;
  font-size: 13px;
  cursor: pointer;
}

.more-btn.on {
  border-color: var(--p-300);
  background: var(--p-50);
  color: var(--p-700);
  font-weight: 500;
}

.count-badge {
  padding: 0 6px;
  border-radius: 999px;
  background: var(--p-500);
  color: #fff;
  font-size: 11px;
  font-weight: 600;
  line-height: 16px;
}

/* Active filter chips */
.active-filters {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  margin: -8px 0 20px;
}

.filter-chip {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 4px 4px 10px;
  border-radius: 999px;
  background: var(--p-100);
  color: var(--p-700);
  font-size: 12px;
  font-weight: 500;
}

.filter-chip-remove {
  display: flex;
  padding: 2px;
  border: none;
  border-radius: 50%;
  background: none;
  color: inherit;
  cursor: pointer;
}

.filter-chip-remove:hover {
  background: color-mix(in srgb, var(--p-700) 15%, transparent);
}

.clear-all {
  padding: 0;
  border: none;
  background: none;
  color: var(--color-accent);
  font: inherit;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
}

/* Grid */
.games-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 28px 18px;
  transition: opacity var(--transition-fast);
}

.games-grid.is-stale {
  opacity: 0.55;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 48px 0;
  color: var(--color-text-secondary);
}

.loading-more {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 32px 0 64px;
  font-size: 13px;
  color: var(--color-text-secondary);
}

.spinner {
  width: 16px;
  height: 16px;
  border: 2px solid var(--color-border);
  border-top-color: var(--p-500);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

@media (prefers-reduced-motion: reduce) {
  .spinner {
    animation-duration: 2.4s;
  }
}

.load-more-btn {
  padding: 7px 18px;
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius-pill);
  background: transparent;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 13px;
  cursor: pointer;
}

/* Phone filters */
.filters-fab {
  position: fixed;
  z-index: 40;
  left: 50%;
  bottom: calc(20px + env(safe-area-inset-bottom));
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 44px;
  padding: 0 20px;
  transform: translateX(-50%);
  border: none;
  border-radius: 999px;
  background: var(--s-700);
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.25);
  color: var(--s-50);
  font: inherit;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
}

.fab-count {
  padding: 0 7px;
  border-radius: 999px;
  background: var(--p-400);
  color: #fff;
  font-size: 11px;
  font-weight: 700;
  line-height: 18px;
}

.sheet-scrim {
  position: fixed;
  inset: 0;
  z-index: 45;
  background: rgba(0, 0, 0, 0.45);
}

.sort-tab:focus-visible,
.filter-pill:focus-visible,
.more-btn:focus-visible,
.filter-chip-remove:focus-visible,
.clear-all:focus-visible,
.load-more-btn:focus-visible,
.filters-fab:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

@media (prefers-color-scheme: dark) {
  .filter-pill.on,
  .filter-chip {
    border-color: transparent;
    background: color-mix(in srgb, var(--p-300) 22%, transparent);
    color: var(--p-100);
  }

  .more-btn.on {
    border-color: var(--p-400);
    background: color-mix(in srgb, var(--p-500) 20%, transparent);
    color: var(--p-100);
  }

  .filter-chip-remove:hover {
    background: rgba(255, 255, 255, 0.12);
  }

  .filters-fab {
    background: var(--p-500);
    color: #fff;
  }

  .fab-count {
    background: #fff;
    color: var(--p-700);
  }
}

@media (max-width: 768px) {
  .sort-tab {
    padding: 12px;
  }

  .sort-tab :deep(svg) {
    display: none;
  }

  .facets {
    margin: 12px 0 16px;
  }

  .facets-label,
  .more-filters {
    display: none;
  }

  .platform-pills {
    flex-wrap: nowrap;
    overflow-x: auto;
    scrollbar-width: none;
    margin: 0 -4px;
    padding: 0 4px;
  }

  .games-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 16px 10px;
  }

  .loading-more {
    padding-bottom: 96px;
  }
}
</style>
