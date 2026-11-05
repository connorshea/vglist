<template>
  <section class="section search-page">
    <h1 class="title">Search</h1>

    <form class="search-form" role="search" @submit.prevent="submit">
      <input
        v-model="draft"
        class="input"
        type="search"
        placeholder="Search games, companies, users…"
        aria-label="Search vglist"
      />
      <button class="button is-primary" type="submit">
        <Search :size="16" :stroke-width="2" aria-hidden="true" />
        <span>Search</span>
      </button>
    </form>

    <p v-if="!hasQuery" class="search-prompt">Enter at least {{ MIN_QUERY_LENGTH }} characters to search.</p>

    <template v-else>
      <div class="search-tabs" role="tablist" aria-label="Result types" @keydown="onTabKeydown">
        <button
          v-for="tab in SEARCH_TABS"
          :id="`search-tab-${tab.key}`"
          :key="tab.key"
          :ref="(el) => setTabRef(tab.key, el)"
          type="button"
          role="tab"
          class="search-tab"
          :class="{ 'is-active': tab.key === activeTab }"
          :aria-selected="tab.key === activeTab"
          aria-controls="search-panel"
          :tabindex="tab.key === focusedTab ? 0 : -1"
          @click="selectTab(tab.key)"
          @focus="focusedTab = tab.key"
        >
          {{ tab.label }}<template v-if="countFor(tab.key) !== null"> ({{ countFor(tab.key) }})</template>
        </button>
      </div>

      <div id="search-panel" role="tabpanel" :aria-labelledby="`search-tab-${activeTab}`">
        <div v-if="activeError" class="notification is-danger search-error">
          <p>Search failed: {{ extractGqlError(activeError) }}</p>
          <button class="button is-small retry-button" type="button" @click="retry">Retry</button>
        </div>

        <ul v-else-if="waitingForFirstResults" class="skeleton-list" aria-hidden="true">
          <li v-for="n in 5" :key="n" class="skeleton-row"></li>
        </ul>

        <p v-else-if="activeTotal === 0" class="search-empty">No results for "{{ searchQuery }}"</p>

        <!-- Earlier results stay on screen (marked busy) while newer ones
             load, so the pagination controls, and focus, don't disappear. -->
        <div v-else-if="activeTab === 'all'" :aria-busy="overviewLoading">
          <section
            v-for="section in overviewSections"
            :key="section.type"
            class="search-section"
            :aria-labelledby="`search-section-${section.type}`"
          >
            <h2 :id="`search-section-${section.type}`" class="search-section-title">{{ labelFor(section.type) }}</h2>
            <SearchResultList :section="section" />
            <RouterLink
              v-if="section.totalCount > section.nodes.length"
              :to="tabLocation(section.type)"
              class="see-all"
            >
              See all {{ section.totalCount }} {{ labelFor(section.type).toLowerCase() }} →
            </RouterLink>
          </section>
        </div>

        <div v-else-if="list" :aria-busy="tabLoading">
          <SearchResultList :section="list.section" />
          <PaginationNav
            v-if="page > 1 || list.hasNextPage"
            :current-page="page"
            :has-next-page="list.hasNextPage"
            :loading="tabLoading"
            @prev="prevPage"
            @next="nextPage"
          />
        </div>
      </div>
    </template>

    <p class="is-sr-only" aria-live="polite">{{ liveMessage }}</p>
  </section>
</template>

<script setup lang="ts">
import { computed, nextTick, ref, watch, type ComponentPublicInstance } from "vue";
import { useRoute, useRouter, type RouteLocationRaw } from "vue-router";
import { Search } from "@lucide/vue";
import { useQuery } from "@/composables/useGraphQL";
import { SEARCH_OVERVIEW, SEARCH_TAB } from "@/graphql/queries/search";
import type { SearchOverviewQuery, SearchTabQuery } from "@/types/graphql";
import PaginationNav from "@/components/PaginationNav.vue";
import SearchResultList from "@/components/search/SearchResultList.vue";
import { extractGqlError } from "@/utils/graphql-errors";
import {
  MIN_QUERY_LENGTH,
  SEARCH_TABS,
  pageSizeFor,
  parseSearchState,
  searchSection,
  type SearchSection,
  type SearchTabKey,
  type SearchTypeKey
} from "@/utils/search";

const route = useRoute();
const router = useRouter();

const state = computed(() => parseSearchState(route.query));
// Separate computeds so each query only refetches when its own inputs
// change: switching tabs mustn't refetch the overview.
const searchQuery = computed(() => state.value.query);
const activeTab = computed(() => state.value.tab);
const listType = computed<SearchTypeKey | null>(() => (activeTab.value === "all" ? null : activeTab.value));
const hasQuery = computed(() => searchQuery.value.length >= MIN_QUERY_LENGTH);

const draft = ref(searchQuery.value);
watch(searchQuery, (value) => {
  draft.value = value;
});

const {
  data: overview,
  loading: overviewLoading,
  error: overviewError,
  refetch: refetchOverview
} = useQuery<SearchOverviewQuery>(SEARCH_OVERVIEW, {
  variables: () => ({ query: searchQuery.value }),
  enabled: () => hasQuery.value
});

// Prev/next with a history of cursors, like the other list pages. It belongs
// to one query and tab, so a new search or tab starts back on page 1.
const listKey = computed(() => `${searchQuery.value}\n${activeTab.value}`);
const pagination = ref({ key: "", page: 1, cursors: [null] as (string | null)[] });
const page = computed(() => (pagination.value.key === listKey.value ? pagination.value.page : 1));
const after = computed(() =>
  pagination.value.key === listKey.value ? pagination.value.cursors[page.value - 1] : null
);

const {
  data: tabData,
  loading: tabLoading,
  error: tabError,
  refetch: refetchTab
} = useQuery<SearchTabQuery>(SEARCH_TAB, {
  variables: () => ({
    query: searchQuery.value,
    first: pageSizeFor(listType.value ?? "games"),
    after: after.value,
    // Only the active tab's field is fetched.
    ...Object.fromEntries(SEARCH_TABS.filter((t) => t.key !== "all").map((t) => [t.key, t.key === listType.value]))
  }),
  enabled: () => hasQuery.value && listType.value !== null
});

const list = computed(() => {
  const type = listType.value;
  const data = tabData.value;
  if (!type || !data) return null;
  const section = searchSection(data, type);
  const pageInfo = data[type]?.pageInfo;
  if (!section || !pageInfo) return null;
  return { section, hasNextPage: pageInfo.hasNextPage, endCursor: pageInfo.endCursor };
});

function nextPage() {
  const current = list.value;
  if (!current?.hasNextPage) return;
  const cursors = pagination.value.key === listKey.value ? [...pagination.value.cursors] : [null];
  cursors[page.value] = current.endCursor;
  pagination.value = { key: listKey.value, page: page.value + 1, cursors };
}

function prevPage() {
  if (page.value <= 1) return;
  pagination.value = { ...pagination.value, page: page.value - 1 };
}

const activeError = computed(() => (activeTab.value === "all" ? overviewError.value : tabError.value));
// Only before anything has loaded for this tab; after that, earlier results
// stay up while newer ones load.
const waitingForFirstResults = computed(() => (activeTab.value === "all" ? !overview.value : !list.value));

function countFor(key: SearchTabKey): number | null {
  if (key === "all" || !overview.value) return null;
  return overview.value[key]?.totalCount ?? 0;
}

const activeTotal = computed(() => {
  if (activeTab.value === "all") {
    return overview.value ? SEARCH_TABS.reduce((sum, tab) => sum + (countFor(tab.key) ?? 0), 0) : null;
  }
  return list.value?.section.totalCount ?? null;
});

const overviewSections = computed(() => {
  const data = overview.value;
  if (!data) return [];
  return SEARCH_TABS.flatMap((tab) => (tab.key === "all" ? [] : [searchSection(data, tab.key)])).filter(
    (section): section is SearchSection => section !== null && section.totalCount > 0
  );
});

function labelFor(key: SearchTabKey): string {
  return SEARCH_TABS.find((t) => t.key === key)?.label ?? "";
}

const liveMessage = computed(() => {
  if (!hasQuery.value) return "";
  if (activeTab.value === "all" ? overviewLoading.value : tabLoading.value) return "Searching…";
  if (activeTotal.value === null) return "";
  const noun = activeTab.value === "all" ? "results" : labelFor(activeTab.value).toLowerCase();
  return `${activeTotal.value} ${noun} for "${searchQuery.value}"`;
});

function tabLocation(key: SearchTabKey): RouteLocationRaw {
  const query: Record<string, string> = { query: searchQuery.value };
  if (key !== "all") query.type = key;
  return { name: "search", query };
}

function submit() {
  void router.push({ name: "search", query: { query: draft.value.trim() } });
}

function selectTab(key: SearchTabKey) {
  void router.push(tabLocation(key));
}

function retry() {
  void (activeTab.value === "all" ? refetchOverview() : refetchTab());
}

// Tabs follow the ARIA tabs pattern with manual activation: arrow keys move
// focus, Enter/Space selects. Selecting loads results and adds a history
// entry, so it shouldn't happen for every tab an arrow key passes over.
const focusedTab = ref<SearchTabKey>(activeTab.value);
watch(activeTab, (key) => {
  focusedTab.value = key;
});

const tabRefs = new Map<SearchTabKey, HTMLElement>();

function setTabRef(key: SearchTabKey, el: Element | ComponentPublicInstance | null) {
  if (el instanceof HTMLElement) tabRefs.set(key, el);
}

function onTabKeydown(event: KeyboardEvent) {
  // Leave modified keys alone, e.g. Alt+Left is the browser's Back.
  if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return;

  const current = SEARCH_TABS.findIndex((t) => t.key === focusedTab.value);
  const last = SEARCH_TABS.length - 1;
  const nextIndex: Record<string, number> = {
    ArrowRight: current === last ? 0 : current + 1,
    ArrowLeft: current === 0 ? last : current - 1,
    Home: 0,
    End: last
  };
  if (!(event.key in nextIndex)) return;

  event.preventDefault();
  const next = SEARCH_TABS[nextIndex[event.key]].key;
  focusedTab.value = next;
  void nextTick(() => tabRefs.get(next)?.focus());
}
</script>

<style scoped>
.search-page {
  max-width: 960px;
  margin: 0 auto;
}

.search-form {
  display: flex;
  gap: 8px;
  margin-bottom: 20px;
}

.search-form .button {
  gap: 6px;
}

.search-prompt,
.search-empty {
  color: var(--color-text-secondary);
}

.search-tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin-bottom: 16px;
  border-bottom: 1px solid var(--color-border);
}

.search-tab {
  padding: 8px 12px;
  border: none;
  border-bottom: 2px solid transparent;
  margin-bottom: -1px;
  background: none;
  color: var(--color-text-secondary);
  font: inherit;
  cursor: pointer;
}

.search-tab:hover {
  color: var(--color-text-primary);
}

.search-tab.is-active {
  color: var(--color-text-primary);
  border-bottom-color: var(--color-accent);
  font-weight: 600;
}

.search-tab:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: -2px;
}

.search-error {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.search-section + .search-section {
  margin-top: 24px;
}

.search-section-title {
  margin-bottom: 4px;
  font-size: 0.8rem;
  font-weight: 600;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  color: var(--color-text-primary);
}

.see-all {
  display: inline-block;
  margin: 4px 12px 0;
  font-size: 0.9rem;
}

.see-all:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.skeleton-list {
  list-style: none;
  margin: 0;
}

.skeleton-row {
  height: 64px;
  margin: 10px 12px;
  border-radius: 8px;
  background: var(--color-bg-subtle);
  animation: skeleton-pulse 1.2s ease-in-out infinite;
}

@keyframes skeleton-pulse {
  50% {
    opacity: 0.5;
  }
}

@media (prefers-reduced-motion: reduce) {
  .skeleton-row {
    animation: none;
  }
}
</style>
