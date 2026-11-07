<template>
  <div class="library-page" :class="{ 'is-phone': isPhone }">
    <div v-if="pageLoading && !pageData" class="library-message">
      <p>Loading…</p>
    </div>

    <div v-else-if="pageError" class="notification is-danger">
      <p>{{ pageError.message }}</p>
    </div>

    <template v-if="user">
      <!-- Phone: status pills, search and sort, then a list -->
      <template v-if="isPhone">
        <div class="library-pills" role="group" aria-label="Filter by status">
          <button
            type="button"
            class="library-pill"
            :class="{ 'is-active': status === null }"
            :aria-pressed="status === null"
            @click="setStatus(null)"
          >
            All <span class="library-pill-count">{{ gamesCount }}</span>
          </button>
          <button
            v-for="s in statusFilters"
            :key="s.key"
            type="button"
            class="library-pill"
            :class="{ 'is-active': status === s.key }"
            :aria-pressed="status === s.key"
            @click="setStatus(s.key)"
          >
            <span class="status-dot" :class="s.className" aria-hidden="true"></span>
            {{ s.label }}
            <span class="library-pill-count">{{ statusCounts[s.key] ?? 0 }}</span>
          </button>
        </div>

        <div class="library-phone-controls">
          <label class="library-search">
            <span class="is-sr-only">Search library</span>
            <Search :size="14" aria-hidden="true" />
            <input v-model="search" type="search" placeholder="Search library…" />
          </label>
          <label class="library-sort-button">
            <span class="is-sr-only">Sort by</span>
            <ArrowUpDown :size="18" aria-hidden="true" />
            <select :value="sortBy" @change="setSort(($event.target as HTMLSelectElement).value)">
              <option v-for="s in LIBRARY_SORTS" :key="s.key" :value="s.key">{{ s.label }}</option>
            </select>
          </label>
        </div>

        <div v-if="activeChips.length" class="library-chips library-phone-chips">
          <button
            v-for="chip in activeChips"
            :key="chip.key"
            type="button"
            class="library-chip"
            :aria-label="`Remove filter: ${chip.label}`"
            @click="chip.remove()"
          >
            {{ chip.label }} <X :size="12" aria-hidden="true" />
          </button>
        </div>

        <div class="library-rows">
          <LibraryPhoneRow
            v-for="purchase in games"
            :key="purchase.id"
            :purchase="purchase"
            :hide-hours="user.hideDaysPlayed"
          />
        </div>
        <LibraryEmptyState
          v-if="!games.length"
          :loading="gamesLoading"
          :error="gamesError"
          :library-empty="gamesCount === 0"
        />
        <div v-if="gamesHasNextPage" class="library-load-more">
          <button type="button" class="library-button" :disabled="gamesLoading" @click="loadMoreGames">
            {{ gamesLoading ? "Loading…" : "Load more games" }}
          </button>
        </div>
      </template>

      <!-- Desktop: filter rail beside the grid -->
      <div v-else class="library-split">
        <LibraryFilterRail
          class="library-split-rail"
          :search="search"
          :status="status"
          :games-count="gamesCount"
          :status-counts="statusCounts"
          :platforms="statistics?.platformCounts ?? []"
          :stores="statistics?.storeCounts ?? []"
          :platform-ids="platformIds"
          :store-ids="storeIds"
          :min-rating="minRating"
          :max-rating="maxRating"
          @update:search="search = $event"
          @update:status="setStatus"
          @toggle-platform="togglePlatform"
          @toggle-store="toggleStore"
          @update:rating="setRating"
        />

        <main class="library-split-main">
          <div class="library-toolbar">
            <div v-if="activeChips.length" class="library-chips">
              <button
                v-for="chip in activeChips"
                :key="chip.key"
                type="button"
                class="library-chip"
                :aria-label="`Remove filter: ${chip.label}`"
                @click="chip.remove()"
              >
                {{ chip.label }} <X :size="12" aria-hidden="true" />
              </button>
              <button v-if="activeChips.length > 1" type="button" class="library-clear" @click="clearFilters">
                Clear all
              </button>
            </div>
            <span class="library-toolbar-grow"></span>
            <label class="library-select">
              <span class="is-sr-only">Grouping</span>
              <select
                :value="groupBy"
                :disabled="status !== null"
                @change="setGroup(($event.target as HTMLSelectElement).value)"
              >
                <option value="status">Group by status</option>
                <option value="none">No grouping</option>
              </select>
              <ChevronDown :size="14" aria-hidden="true" />
            </label>
            <label class="library-select">
              <span class="is-sr-only">Sort by</span>
              <select :value="sortBy" @change="setSort(($event.target as HTMLSelectElement).value)">
                <option v-for="s in LIBRARY_SORTS" :key="s.key" :value="s.key">{{ s.label }}</option>
              </select>
              <ChevronDown :size="14" aria-hidden="true" />
            </label>
          </div>

          <!-- Grouped into a shelf per status -->
          <template v-if="grouped">
            <template v-for="shelf in shelves" :key="shelf.status.key">
              <section v-if="shelf.totalCount > 0" class="library-shelf" :aria-labelledby="`shelf-${shelf.status.key}`">
                <div class="library-shelf-header">
                  <span class="status-dot" :class="shelf.status.className" aria-hidden="true"></span>
                  <h2 :id="`shelf-${shelf.status.key}`">{{ shelf.status.label }}</h2>
                  <span class="library-shelf-count">{{ shelf.totalCount }}</span>
                  <button
                    v-if="shelf.totalCount > shelf.purchases.length"
                    type="button"
                    class="library-shelf-more"
                    @click="setStatus(shelf.status.key)"
                  >
                    Show all {{ shelf.totalCount }}
                  </button>
                </div>
                <div v-if="shelf.status.key === 'IN_PROGRESS'" class="library-playing">
                  <LibraryPlayingCard
                    v-for="purchase in playing"
                    :key="purchase.id"
                    :purchase="purchase"
                    :hide-hours="user.hideDaysPlayed"
                  />
                </div>
                <div v-else class="library-grid">
                  <LibraryGameTile
                    v-for="purchase in shelf.purchases"
                    :key="purchase.id"
                    :purchase="purchase"
                    :hide-hours="user.hideDaysPlayed"
                  />
                </div>
              </section>
            </template>
            <LibraryEmptyState
              v-if="!shelves.some((shelf) => shelf.totalCount > 0)"
              :loading="shelvesLoading"
              :error="shelvesError"
              :library-empty="gamesCount === 0"
            />
          </template>

          <!-- One status, or everything in one grid -->
          <template v-else>
            <p class="library-result-count" aria-live="polite">
              {{ gamesTotal.toLocaleString() }} game{{ gamesTotal === 1 ? "" : "s" }}
            </p>
            <div class="library-grid">
              <LibraryGameTile
                v-for="purchase in games"
                :key="purchase.id"
                :purchase="purchase"
                :hide-hours="user.hideDaysPlayed"
              />
            </div>
            <LibraryEmptyState
              v-if="!games.length"
              :loading="gamesLoading"
              :error="gamesError"
              :library-empty="gamesCount === 0"
            />
            <div v-if="gamesHasNextPage" class="library-load-more">
              <button type="button" class="library-button" :disabled="gamesLoading" @click="loadMoreGames">
                {{ gamesLoading ? "Loading…" : "Load more games" }}
              </button>
            </div>
          </template>
        </main>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from "vue";
import { useRoute, useRouter, type LocationQuery, type LocationQueryValueRaw } from "vue-router";
import { ArrowUpDown, ChevronDown, Search, X } from "@lucide/vue";
import { debounce } from "lodash-es";
import { useQuery } from "@/composables/useGraphQL";
import { GET_LIBRARY_GAMES, GET_LIBRARY_PAGE, GET_LIBRARY_SHELVES } from "@/graphql/queries/library";
import type { GetLibraryGamesQuery, GetLibraryPageQuery, GetLibraryShelvesQuery } from "@/types/graphql";
import {
  DEFAULT_LIBRARY_SORT,
  LIBRARY_SORTS,
  LIBRARY_STATUSES,
  NO_STATUS,
  isLibrarySort,
  isLibraryStatusFilter,
  parseIdList,
  parseRating,
  type LibraryStatus,
  type LibraryStatusFilter
} from "@/utils/library";
import LibraryEmptyState from "@/components/library/LibraryEmptyState.vue";
import LibraryFilterRail from "@/components/library/LibraryFilterRail.vue";
import LibraryGameTile from "@/components/library/LibraryGameTile.vue";
import LibraryPhoneRow from "@/components/library/LibraryPhoneRow.vue";
import LibraryPlayingCard from "@/components/library/LibraryPlayingCard.vue";
import "@/assets/stylesheets/library.scss";

const SHELF_SIZE = 12;
// The Playing shelf's cards are larger, so it shows a row's worth at most.
const PLAYING_SIZE = 6;
const PAGE_SIZE = 48;
const PHONE_QUERY = "(max-width: 768px)";

const route = useRoute("userLibrary");
const router = useRouter();

// ── Layout ──────────────────────────────────────────────────────────────────
// The phone layout is a different arrangement rather than a squeezed one, so
// it's chosen in script and only one layout's data is fetched.
const isPhone = ref(false);
let phoneMedia: MediaQueryList | null = null;

function updateIsPhone() {
  isPhone.value = phoneMedia?.matches ?? false;
}

onMounted(() => {
  if (typeof window.matchMedia !== "function") return;
  phoneMedia = window.matchMedia(PHONE_QUERY);
  updateIsPhone();
  phoneMedia.addEventListener("change", updateIsPhone);
});

onBeforeUnmount(() => phoneMedia?.removeEventListener("change", updateIsPhone));

// ── Statistics ──────────────────────────────────────────────────────────────
// The filter rail's counts. The header above the tabs is the profile layout's.
const {
  data: pageData,
  loading: pageLoading,
  error: pageError
} = useQuery<GetLibraryPageQuery>(GET_LIBRARY_PAGE, {
  variables: () => ({ slug: route.params.slug })
});

const user = computed(() => pageData.value?.user ?? null);
const statistics = computed(() => user.value?.libraryStatistics ?? null);
const gamesCount = computed(() => statistics.value?.gamesCount ?? 0);

// The statistics leave out the games with no status, so they're whatever the
// statuses don't add up to.
const statusCounts = computed(() => {
  const counts: Partial<Record<LibraryStatusFilter, number>> = {};
  let counted = 0;
  for (const { status: key, count } of statistics.value?.statusCounts ?? []) {
    counts[key] = count;
    counted += count;
  }
  if (gamesCount.value > counted) counts[NO_STATUS.key] = gamesCount.value - counted;
  return counts;
});

// ── Filters ─────────────────────────────────────────────────────────────────
// Every filter lives in the query string, so a filtered library can be linked
// to and survives a reload.
const status = computed(() => (isLibraryStatusFilter(route.query.status) ? route.query.status : null));
const sortBy = computed(() => (isLibrarySort(route.query.sort) ? route.query.sort : DEFAULT_LIBRARY_SORT));
const groupBy = computed(() => (route.query.group === "none" ? "none" : "status"));
const platformIds = computed(() => parseIdList(route.query.platforms));
const storeIds = computed(() => parseIdList(route.query.stores));
const minRating = computed(() => parseRating(route.query.min));
const maxRating = computed(() => parseRating(route.query.max));
const searchQuery = computed(() => (typeof route.query.q === "string" ? route.query.q : ""));

function updateQuery(patch: Record<string, LocationQueryValueRaw>) {
  const query: LocationQuery = { ...route.query };
  for (const [key, value] of Object.entries(patch)) {
    if (value === null || value === undefined || value === "") {
      delete query[key];
    } else {
      query[key] = String(value);
    }
  }
  void router.replace({ query });
}

// "No status" is only offered when some game has no status, or it's the
// active filter (say, from a link).
const statusFilters = computed<readonly LibraryStatus<LibraryStatusFilter>[]>(() =>
  (statusCounts.value.NONE ?? 0) > 0 || status.value === NO_STATUS.key
    ? [...LIBRARY_STATUSES, NO_STATUS]
    : LIBRARY_STATUSES
);

function setStatus(value: LibraryStatusFilter | null) {
  updateQuery({ status: value });
}

function setSort(value: string) {
  updateQuery({ sort: isLibrarySort(value) && value !== DEFAULT_LIBRARY_SORT ? value : null });
}

function setGroup(value: string) {
  updateQuery({ group: value === "none" ? "none" : null });
}

function toggleId(ids: string[], id: string): string | null {
  const next = ids.includes(id) ? ids.filter((existing) => existing !== id) : [...ids, id];
  return next.length ? next.join(",") : null;
}

function togglePlatform(id: string) {
  updateQuery({ platforms: toggleId(platformIds.value, id) });
}

function toggleStore(id: string) {
  updateQuery({ stores: toggleId(storeIds.value, id) });
}

function setRating(min: number | null, max: number | null) {
  updateQuery({ min, max });
}

function clearFilters() {
  search.value = "";
  updateQuery({ q: null, platforms: null, stores: null, min: null, max: null });
}

// The search box updates immediately; the query string (and so the request)
// catches up once typing pauses.
const search = ref(searchQuery.value);
const commitSearch = debounce((value: string) => updateQuery({ q: value.trim() || null }), 300);
watch(search, (value) => commitSearch(value));
watch(searchQuery, (value) => {
  if (value !== search.value.trim()) search.value = value;
});
onBeforeUnmount(() => commitSearch.cancel());

interface Chip {
  key: string;
  label: string;
  remove: () => void;
}

const activeChips = computed<Chip[]>(() => {
  const chips: Chip[] = [];
  if (searchQuery.value) {
    chips.push({
      key: "q",
      label: `“${searchQuery.value}”`,
      remove: () => {
        search.value = "";
        updateQuery({ q: null });
      }
    });
  }
  const platformNames = new Map((statistics.value?.platformCounts ?? []).map((p) => [p.platform.id, p.platform.name]));
  for (const id of platformIds.value) {
    chips.push({ key: `p${id}`, label: platformNames.get(id) ?? "Platform", remove: () => togglePlatform(id) });
  }
  const storeNames = new Map((statistics.value?.storeCounts ?? []).map((s) => [s.store.id, s.store.name]));
  for (const id of storeIds.value) {
    chips.push({ key: `s${id}`, label: storeNames.get(id) ?? "Store", remove: () => toggleStore(id) });
  }
  if (minRating.value !== null || maxRating.value !== null) {
    chips.push({
      key: "rating",
      label: `Rating ${minRating.value ?? 0}–${maxRating.value ?? 100}`,
      remove: () => setRating(null, null)
    });
  }
  return chips;
});

const filterVariables = computed(() => ({
  slug: route.params.slug,
  search: searchQuery.value || null,
  sortBy: sortBy.value,
  platformIds: platformIds.value.length ? platformIds.value : null,
  storeIds: storeIds.value.length ? storeIds.value : null,
  minRating: minRating.value,
  maxRating: maxRating.value
}));

// Shelves only make sense on the desktop layout when no single status is
// picked; otherwise the library is one paginated grid (or list).
const grouped = computed(() => !isPhone.value && status.value === null && groupBy.value === "status");

// ── Shelves ─────────────────────────────────────────────────────────────────
const {
  data: shelvesData,
  loading: shelvesLoading,
  error: shelvesError
} = useQuery<GetLibraryShelvesQuery>(GET_LIBRARY_SHELVES, {
  variables: () => ({ ...filterVariables.value, first: SHELF_SIZE }),
  enabled: () => grouped.value
});

type ShelfKey = Exclude<keyof NonNullable<GetLibraryShelvesQuery["user"]>, "id">;

const SHELF_ORDER: { key: ShelfKey; status: LibraryStatusFilter }[] = [
  { key: "inProgress", status: "IN_PROGRESS" },
  { key: "paused", status: "PAUSED" },
  { key: "completed", status: "COMPLETED" },
  { key: "fullyCompleted", status: "FULLY_COMPLETED" },
  { key: "unplayed", status: "UNPLAYED" },
  { key: "dropped", status: "DROPPED" },
  { key: "notApplicable", status: "NOT_APPLICABLE" },
  { key: "noStatus", status: NO_STATUS.key }
];

const shelves = computed(() => {
  const shelvesUser = shelvesData.value?.user;
  return SHELF_ORDER.map(({ key, status: shelfStatus }) => {
    const nodes = shelvesUser?.[key].nodes ?? [];
    return {
      status: [...LIBRARY_STATUSES, NO_STATUS].find((s) => s.key === shelfStatus) as LibraryStatus<LibraryStatusFilter>,
      totalCount: shelvesUser?.[key].totalCount ?? 0,
      // What the shelf shows, so "Show all" appears whenever games are left out.
      purchases: key === "inProgress" ? nodes.slice(0, PLAYING_SIZE) : nodes
    };
  });
});

const playing = computed(() => (shelvesData.value?.user?.inProgress.nodes ?? []).slice(0, PLAYING_SIZE));

// ── Single grid ─────────────────────────────────────────────────────────────
const gamesVariables = computed(() => ({
  ...filterVariables.value,
  first: PAGE_SIZE,
  completionStatus: status.value === NO_STATUS.key ? null : status.value,
  noCompletionStatus: status.value === NO_STATUS.key ? true : null
}));

const {
  data: gamesData,
  loading: gamesLoading,
  error: gamesError,
  fetchMore: fetchMoreGames
} = useQuery<GetLibraryGamesQuery>(GET_LIBRARY_GAMES, {
  variables: () => gamesVariables.value,
  enabled: () => !grouped.value
});

const gamesConnection = computed(() => gamesData.value?.user?.gamePurchases ?? null);
const games = computed(() => gamesConnection.value?.nodes ?? []);
const gamesTotal = computed(() => gamesConnection.value?.totalCount ?? 0);
const gamesHasNextPage = computed(() => gamesConnection.value?.pageInfo.hasNextPage ?? false);

async function loadMoreGames() {
  const cursor = gamesConnection.value?.pageInfo.endCursor;
  if (!gamesHasNextPage.value || gamesLoading.value || !cursor) return;

  await fetchMoreGames({ ...gamesVariables.value, after: cursor }, (prev, next) => {
    if (!prev.user || !next.user) return next;
    return {
      ...next,
      user: {
        ...next.user,
        gamePurchases: {
          ...next.user.gamePurchases,
          nodes: [...prev.user.gamePurchases.nodes, ...next.user.gamePurchases.nodes]
        }
      }
    };
  });
}
</script>

<style scoped>
.library-page {
  padding-bottom: 64px;
}

.library-button {
  display: inline-flex;
  gap: 6px;
  align-items: center;
  padding: 7px 20px;
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius-button);
  background: transparent;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 0.85rem;
  font-weight: 500;
  line-height: 1.4;
  cursor: pointer;
}

.library-button:hover {
  border-color: var(--color-accent);
  color: var(--color-accent);
}

.library-button.is-primary {
  border-color: var(--vglist-theme);
  background: var(--vglist-theme);
  color: #fff;
}

.library-button.is-primary:hover {
  border-color: var(--p-600);
  background: var(--p-600);
}

.library-button:disabled {
  opacity: 0.6;
  cursor: default;
}

.library-button:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

/* ── Desktop layout ── */
.library-split {
  display: flex;
  flex-wrap: wrap;
  gap: 32px;
  align-items: flex-start;
  padding-top: 24px;
}

.library-split-rail {
  flex: 1 1 220px;
  max-width: 240px;
}

.library-split-main {
  flex: 999 1 560px;
  min-width: 0;
}

.library-toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  align-items: center;
  margin-bottom: 16px;
}

.library-toolbar-grow {
  flex: 1;
}

.library-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  align-items: center;
}

.library-chip {
  display: inline-flex;
  gap: 6px;
  align-items: center;
  padding: 4px 8px 4px 10px;
  border: 0;
  border-radius: 999px;
  background: var(--p-100);
  color: var(--p-700);
  font: inherit;
  font-size: 0.75rem;
  font-weight: 500;
  cursor: pointer;
}

.library-chip:hover {
  background: var(--p-200);
}

.library-chip:focus-visible,
.library-clear:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.library-clear {
  padding: 4px;
  border: 0;
  background: none;
  color: var(--color-text-secondary);
  font: inherit;
  font-size: 0.75rem;
  cursor: pointer;
}

.library-clear:hover {
  color: var(--color-accent);
}

.library-select {
  position: relative;
  display: inline-flex;
  align-items: center;
  color: var(--color-text-secondary);
}

.library-select select {
  height: 30px;
  padding: 0 26px 0 8px;
  border: 1px solid var(--color-border);
  border-radius: 4px;
  background: var(--color-surface);
  color: var(--color-text-primary);
  font: inherit;
  font-size: 0.75rem;
  cursor: pointer;
  appearance: none;
}

.library-select select:disabled {
  opacity: 0.5;
  cursor: default;
}

.library-select select:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 1px;
}

.library-select svg {
  position: absolute;
  right: 8px;
  pointer-events: none;
}

/* ── Shelves ── */
.library-shelf {
  margin-bottom: 32px;
}

.library-shelf-header {
  display: flex;
  gap: 8px;
  align-items: center;
  margin-bottom: 12px;
}

.library-shelf-header h2 {
  margin: 0;
  color: var(--color-text-primary);
  font-size: 0.95rem;
  font-weight: 600;
}

.library-shelf-count {
  color: var(--color-text-tertiary);
  font-size: 0.75rem;
}

.library-shelf-more {
  margin-left: auto;
  padding: 2px 4px;
  border: 0;
  background: none;
  color: var(--color-accent);
  font: inherit;
  font-size: 0.75rem;
  font-weight: 500;
  cursor: pointer;
}

.library-shelf-more:hover {
  text-decoration: underline;
}

.library-shelf-more:focus-visible {
  outline: 2px solid var(--color-accent);
  border-radius: var(--radius-sm);
}

.library-playing {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 12px;
}

.library-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
  gap: 10px;
}

.library-result-count {
  margin: 0 0 12px;
  color: var(--color-text-secondary);
  font-size: 0.8rem;
}

.library-load-more {
  display: flex;
  justify-content: center;
  margin-top: 24px;
}

.library-message {
  padding: 48px 0;
  color: var(--color-text-secondary);
  text-align: center;
}

.library-message-title {
  color: var(--color-text-primary);
  font-weight: 600;
}

/* ── Phone layout ── */
.library-page.is-phone {
  /* Rows and pills run edge to edge, so undo the page's side padding. */
  margin: 0 calc(-1 * var(--library-phone-gutter, 1.5rem));
}

.library-pills {
  display: flex;
  gap: 6px;
  padding: 12px 16px;
  overflow-x: auto;
  scrollbar-width: none;
}

.library-pill {
  display: inline-flex;
  flex-shrink: 0;
  gap: 5px;
  align-items: center;
  min-height: 32px;
  padding: 4px 12px;
  border: 1px solid var(--color-border);
  border-radius: 999px;
  background: transparent;
  color: var(--color-text-secondary);
  font: inherit;
  font-size: 0.75rem;
  white-space: nowrap;
  cursor: pointer;
}

.library-pill.is-active {
  border-color: transparent;
  background: var(--vglist-theme);
  color: #fff;
  font-weight: 600;
}

.library-pill:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.library-pill-count {
  font-size: 0.65rem;
  opacity: 0.6;
}

.library-phone-controls {
  display: flex;
  gap: 8px;
  padding: 0 16px 8px;
}

.library-search {
  display: flex;
  flex: 1;
  gap: 8px;
  align-items: center;
  height: 40px;
  padding: 0 10px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface);
  color: var(--color-text-tertiary);
}

.library-search:focus-within {
  border-color: var(--color-accent);
}

.library-search input {
  flex: 1;
  min-width: 0;
  border: 0;
  outline: 0;
  background: transparent;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 0.875rem;
}

.library-sort-button {
  position: relative;
  display: inline-flex;
  flex-shrink: 0;
  align-items: center;
  justify-content: center;
  width: 44px;
  height: 40px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface);
  color: var(--color-text-primary);
}

.library-sort-button:focus-within {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

/* The native select covers the button, so tapping it opens the OS picker. */
.library-sort-button select {
  position: absolute;
  inset: 0;
  width: 100%;
  opacity: 0;
  cursor: pointer;
}

.library-phone-chips {
  padding: 0 16px 8px;
}

.library-rows {
  border-top: 1px solid var(--color-border);
}

.is-phone .library-message {
  padding: 32px 16px;
}

@media (prefers-color-scheme: dark) {
  .library-chip {
    background: color-mix(in srgb, var(--p-500) 30%, transparent);
    color: var(--p-100);
  }

  .library-chip:hover {
    background: color-mix(in srgb, var(--p-500) 45%, transparent);
  }
}
</style>
