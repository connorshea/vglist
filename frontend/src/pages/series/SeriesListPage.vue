<template>
  <div class="series-index">
    <div class="page-header">
      <div class="page-heading">
        <h1 class="page-title">Series</h1>
        <span v-if="countText" class="page-sub" aria-live="polite">{{ countText }}</span>
      </div>
      <router-link v-if="authStore.isModerator" :to="{ name: 'seriesNew' }" class="new-btn">
        <Plus :size="15" aria-hidden="true" />
        New series
      </router-link>
    </div>

    <div class="toolbar">
      <label class="search">
        <Search :size="15" aria-hidden="true" />
        <span class="is-sr-only">Search series</span>
        <input v-model="searchText" type="search" placeholder="Search series…" autocomplete="off" />
      </label>
      <span class="grow"></span>
      <div class="seg" role="group" aria-label="Sort series">
        <router-link
          v-for="option in SERIES_SORTS"
          :key="option.slug"
          :to="{ query: queryFor(option, nameFilter) }"
          class="seg-btn"
          :class="{ 'is-active': sort === option }"
          :aria-current="sort === option ? 'true' : undefined"
        >
          {{ option.label }}
        </router-link>
      </div>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load series: {{ error.message }}</p>
    </div>

    <div v-if="!data && loading" class="loading-more" role="status">
      <span class="spinner" aria-hidden="true"></span>
      Loading series&hellip;
    </div>
    <div v-else-if="data && series.length === 0" class="empty-state">
      <p v-if="nameFilter">No series match &ldquo;{{ nameFilter }}&rdquo;.</p>
      <p v-else>No series yet.</p>
    </div>

    <ul v-if="series.length" class="series-grid" :class="{ 'is-stale': refreshing }">
      <li v-for="s in series" :key="s.id">
        <SeriesTile
          :id="s.id"
          :name="s.name"
          :games-count="s.gamesCount"
          :first-release-year="s.firstReleaseYear"
          :last-release-year="s.lastReleaseYear"
          :games="s.games.nodes"
          :can-edit="authStore.isModerator"
          @delete="seriesToDelete = s"
        />
      </li>
    </ul>

    <div v-if="hasNextPage" ref="sentinelRef" class="loading-more">
      <template v-if="loadingMore">
        <span class="spinner" aria-hidden="true"></span>
        <span role="status">Loading more series&hellip;</span>
      </template>
      <button v-else type="button" class="load-more-btn" @click="loadMore">Load more series</button>
    </div>

    <ConfirmDialog
      v-model="showDeleteConfirm"
      title="Delete series?"
      confirm-label="Delete series"
      loading-label="Deleting…"
      :loading="deleting"
      @confirm="confirmDelete"
    >
      <template #icon>
        <CircleAlert :size="22" :stroke-width="1.8" />
      </template>
      <strong>{{ seriesToDelete?.name }}</strong> will be permanently deleted, and removed from every game in it. This
      cannot be undone.
    </ConfirmDialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { CircleAlert, Plus, Search } from "@lucide/vue";
import { useAuthStore } from "@/stores/auth";
import { useMutation, useQuery } from "@/composables/useGraphQL";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_SERIES_INDEX } from "@/graphql/queries/resources";
import { DELETE_SERIES } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { DeleteSeriesMutation, GetSeriesIndexQuery, SeriesSort } from "@/types/graphql";
import { countLabel } from "@/components/games-index/format";
import SeriesTile from "@/components/series/SeriesTile.vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";

interface SeriesSortOption {
  slug: string;
  label: string;
  value: SeriesSort;
}

const SERIES_SORTS: SeriesSortOption[] = [
  { slug: "most", label: "Most games", value: "MOST_GAMES" },
  { slug: "name", label: "A → Z", value: "NAME" },
  { slug: "recent", label: "Recently added", value: "RECENTLY_ADDED" }
];
const DEFAULT_SORT = SERIES_SORTS[0];
const PAGE_SIZE = 24;
const SEARCH_DEBOUNCE_MS = 250;

const route = useRoute();
const router = useRouter();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

// Sort and search live in the URL, so a view can be reloaded, shared and
// navigated back to.
const sort = computed(() => SERIES_SORTS.find((o) => o.slug === route.query.sort) ?? DEFAULT_SORT);
const nameFilter = computed(() => (typeof route.query.q === "string" ? route.query.q.trim() : ""));

function queryFor(option: SeriesSortOption, q: string) {
  return {
    ...(option === DEFAULT_SORT ? {} : { sort: option.slug }),
    ...(q ? { q } : {})
  };
}

// The input updates the URL after a pause in typing rather than on every key.
const searchText = ref(nameFilter.value);
let searchTimer: ReturnType<typeof setTimeout> | undefined;

watch(searchText, (text) => {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => {
    void router.replace({ query: queryFor(sort.value, text.trim()) });
  }, SEARCH_DEBOUNCE_MS);
});

// Back/forward to a different search puts its text back in the input.
watch(nameFilter, (q) => {
  if (q !== searchText.value.trim()) searchText.value = q;
});

// ── Series ──
const variables = computed(() => ({
  first: PAGE_SIZE,
  after: null as string | null,
  sortBy: sort.value.value,
  nameContains: nameFilter.value || null
}));

const { data, loading, error, refetch, fetchMore } = useQuery<GetSeriesIndexQuery>(GET_SERIES_INDEX, {
  variables: () => variables.value
});

const series = computed(() => data.value?.seriesList?.nodes ?? []);
const hasNextPage = computed(() => data.value?.seriesList?.pageInfo.hasNextPage ?? false);
const countText = computed(() => {
  const total = data.value?.seriesList?.totalCount;
  return total === undefined ? null : countLabel(total, "series", "series");
});

const loadingMore = ref(false);
// The grid is showing results for the previous sort or search.
const refreshing = computed(() => loading.value && !loadingMore.value);

async function loadMore() {
  const cursor = data.value?.seriesList?.pageInfo.endCursor;
  if (!cursor || loadingMore.value || refreshing.value) return;
  loadingMore.value = true;
  try {
    await fetchMore({ ...variables.value, after: cursor }, (prev, next) => ({
      seriesList:
        prev.seriesList && next.seriesList
          ? { ...next.seriesList, nodes: [...prev.seriesList.nodes, ...next.seriesList.nodes] }
          : next.seriesList
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

onMounted(() => {
  observer = new IntersectionObserver(
    (entries) => {
      if (entries.some((entry) => entry.isIntersecting)) void loadMore();
    },
    { rootMargin: "600px 0px" }
  );
  if (sentinelRef.value) observer.observe(sentinelRef.value);
});

onBeforeUnmount(() => {
  observer?.disconnect();
  clearTimeout(searchTimer);
});

// ── Delete ──
type SeriesNode = NonNullable<GetSeriesIndexQuery["seriesList"]>["nodes"][number];

const seriesToDelete = ref<SeriesNode | null>(null);
const showDeleteConfirm = computed({
  get: () => seriesToDelete.value !== null,
  set: (open) => {
    if (!open) seriesToDelete.value = null;
  }
});

const { mutate: deleteSeries, loading: deleting } = useMutation<DeleteSeriesMutation>(DELETE_SERIES);

async function confirmDelete() {
  const target = seriesToDelete.value;
  if (!target) return;

  try {
    await deleteSeries({ seriesId: target.id });
    showSnackbar(`${target.name} has been deleted.`);
    void refetch();
  } catch (e) {
    showSnackbar(`Failed to delete series: ${extractGqlError(e)}`, "error");
  } finally {
    seriesToDelete.value = null;
  }
}
</script>

<style scoped>
.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 20px;
}

.page-heading {
  display: flex;
  align-items: baseline;
  flex-wrap: wrap;
  gap: 12px;
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

.new-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 7px 14px;
  border-radius: var(--radius-sm);
  background: var(--p-500);
  color: #fff;
  font-size: 13px;
  font-weight: 600;
}

.new-btn:hover {
  background: var(--p-600);
  color: #fff;
}

.new-btn:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.toolbar {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 24px;
}

.grow {
  flex: 1;
}

.search {
  display: flex;
  flex: 1;
  align-items: center;
  gap: 8px;
  min-width: 240px;
  max-width: 420px;
  height: 38px;
  padding: 0 10px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface);
  color: var(--color-text-secondary);
}

.search:focus-within {
  border-color: var(--color-accent);
  box-shadow: 0 0 0 2px color-mix(in srgb, var(--color-accent) 25%, transparent);
}

.search input {
  flex: 1;
  min-width: 0;
  height: 100%;
  border: 0;
  background: transparent;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 14px;
  outline: none;
}

.search input::placeholder {
  color: var(--color-text-tertiary);
}

.seg {
  display: inline-flex;
  max-width: 100%;
  overflow-x: auto;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface);
}

.seg-btn {
  position: relative;
  padding: 8px 14px;
  font-size: 13px;
  white-space: nowrap;
  color: var(--color-text-secondary);
}

.seg-btn + .seg-btn::before {
  content: "";
  position: absolute;
  top: 25%;
  left: 0;
  width: 1px;
  height: 50%;
  background: var(--color-border);
}

.seg-btn:hover {
  color: var(--color-text-primary);
}

.seg-btn.is-active {
  background: color-mix(in srgb, var(--color-accent) 14%, transparent);
  color: var(--color-accent);
  font-weight: 500;
}

.seg-btn:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: -2px;
}

.series-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 16px;
  transition: opacity var(--transition-fast);
}

.series-grid.is-stale {
  opacity: 0.55;
}

.empty-state {
  padding: 48px 0;
  text-align: center;
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

.load-more-btn:hover {
  border-color: var(--p-300);
}

.load-more-btn:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

@media (prefers-color-scheme: dark) {
  .seg-btn.is-active {
    background: color-mix(in srgb, var(--p-300) 22%, transparent);
    color: var(--p-100);
  }
}

/* Phone: search on its own row, full-width sort, rows instead of tiles. */
@media screen and (max-width: 768px) {
  .page-title {
    font-size: 20px;
  }

  .search {
    flex-basis: 100%;
    max-width: none;
    height: 44px;
  }

  .grow {
    display: none;
  }

  .seg {
    display: flex;
    width: 100%;
  }

  .seg-btn {
    flex: 1 1 auto;
    padding: 10px 8px;
    text-align: center;
  }

  .toolbar {
    margin-bottom: 4px;
  }

  .series-grid {
    grid-template-columns: 1fr;
    gap: 0;
  }
}
</style>
