<template>
  <Teleport to="body">
    <div
      v-if="isOpen"
      ref="overlayRef"
      class="search-overlay"
      role="dialog"
      aria-modal="true"
      aria-label="Search"
      @click.self="close"
    >
      <div class="search-header">
        <div class="search-bar-wrap">
          <Search class="search-icon" :stroke-width="2" />
          <input
            ref="searchInputRef"
            v-model="query"
            class="search-input"
            type="text"
            placeholder="Search games, companies, users…"
            @input="onSearch"
            @keydown.enter="goToFirstResult"
          />
          <div class="search-hint"><kbd class="kbd">Esc</kbd> to close</div>
          <button class="search-close" aria-label="Close search" @click="close">
            <X :size="16" :stroke-width="2" />
          </button>
        </div>
      </div>

      <div class="search-results">
        <!-- Empty state -->
        <div v-if="!query || query.length < 2" class="search-empty">
          <Search class="search-empty-icon" :stroke-width="1.5" />
          <p>Start typing to search games, companies, users, and more.</p>
        </div>

        <!-- Loading state -->
        <div v-else-if="loading" class="search-empty">
          <div class="search-spinner"></div>
          <p>Searching…</p>
        </div>

        <!-- Error state -->
        <div v-else-if="error" class="search-empty">
          <p class="search-error-text">Search failed: {{ error }}</p>
          <p class="search-empty-hint">Try again or check your connection</p>
        </div>

        <!-- No results -->
        <div v-else-if="hasSearched && totalResults === 0" class="search-empty">
          <p>
            No results found for "<span class="search-query-highlight">{{ query }}</span
            >"
          </p>
          <p class="search-empty-hint">Try a different search term</p>
        </div>

        <!-- Results grid -->
        <div v-else-if="totalResults > 0" class="results-grid" :class="gridColumnsClass">
          <!-- Games column -->
          <div v-if="gameResults.length" class="category">
            <div class="category-header">
              <Gamepad2 class="category-icon" />
              <span class="category-title">Games</span>
              <span class="category-count"
                >{{ gameResults.length }} result{{ gameResults.length === 1 ? "" : "s" }}</span
              >
            </div>

            <a
              v-for="(game, idx) in gameResults"
              :key="game.searchableId"
              :href="resultHref(game)"
              class="result-item"
              :style="{ animationDelay: `${0.04 + idx * 0.03}s` }"
              @click.prevent="goToResult(game)"
            >
              <div class="result-thumb">
                <img v-if="game.coverUrl" :src="game.coverUrl" :alt="game.content" />
                <div v-else class="result-thumb-placeholder">
                  {{ gameInitials(game.content) }}
                </div>
              </div>
              <div class="result-info">
                <div class="result-title">{{ game.content }}</div>
                <div class="result-meta">
                  <span v-if="game.releaseDate" class="result-year">{{ releaseYear(game.releaseDate) }}</span>
                  <span v-if="game.developerName" class="result-developer">{{ game.developerName }}</span>
                </div>
              </div>
            </a>
          </div>

          <!-- Companies column -->
          <div v-if="companyResults.length" class="category">
            <div class="category-header">
              <Briefcase class="category-icon" />
              <span class="category-title">Companies</span>
              <span class="category-count"
                >{{ companyResults.length }} result{{ companyResults.length === 1 ? "" : "s" }}</span
              >
            </div>

            <a
              v-for="(company, idx) in companyResults"
              :key="company.searchableId"
              :href="resultHref(company)"
              class="result-item result-item--compact"
              :style="{ animationDelay: `${0.05 + idx * 0.03}s` }"
              @click.prevent="goToResult(company)"
            >
              <div class="result-thumb">
                <div class="result-thumb-placeholder">
                  {{ company.content.charAt(0).toUpperCase() }}
                </div>
              </div>
              <div class="result-info">
                <div class="result-title">{{ company.content }}</div>
              </div>
            </a>
          </div>

          <!-- Platforms column -->
          <div v-if="platformResults.length" class="category">
            <div class="category-header">
              <Monitor class="category-icon" />
              <span class="category-title">Platforms</span>
              <span class="category-count"
                >{{ platformResults.length }} result{{ platformResults.length === 1 ? "" : "s" }}</span
              >
            </div>

            <a
              v-for="(platform, idx) in platformResults"
              :key="platform.searchableId"
              :href="resultHref(platform)"
              class="result-item result-item--compact"
              :style="{ animationDelay: `${0.06 + idx * 0.03}s` }"
              @click.prevent="goToResult(platform)"
            >
              <div class="result-thumb">
                <div class="result-thumb-placeholder">
                  {{ platform.content.charAt(0).toUpperCase() }}
                </div>
              </div>
              <div class="result-info">
                <div class="result-title">{{ platform.content }}</div>
              </div>
            </a>
          </div>

          <!-- Other resources column -->
          <div v-if="otherResults.length" class="category">
            <div class="category-header">
              <Briefcase class="category-icon" />
              <span class="category-title">Other</span>
              <span class="category-count"
                >{{ otherResults.length }} result{{ otherResults.length === 1 ? "" : "s" }}</span
              >
            </div>

            <a
              v-for="(item, idx) in otherResults"
              :key="item.searchableId"
              :href="resultHref(item)"
              class="result-item result-item--compact"
              :style="{ animationDelay: `${0.06 + idx * 0.03}s` }"
              @click.prevent="goToResult(item)"
            >
              <div class="result-thumb">
                <div class="result-thumb-placeholder">
                  {{ item.content.charAt(0).toUpperCase() }}
                </div>
              </div>
              <div class="result-info">
                <div class="result-title">{{ item.content }}</div>
                <div class="result-meta">
                  <span class="result-type-tag">{{
                    item.searchableType.charAt(0) + item.searchableType.slice(1).toLowerCase()
                  }}</span>
                </div>
              </div>
            </a>
          </div>

          <!-- Users column -->
          <div v-if="userResults.length" class="category">
            <div class="category-header">
              <Users class="category-icon" />
              <span class="category-title">Users</span>
              <span class="category-count"
                >{{ userResults.length }} result{{ userResults.length === 1 ? "" : "s" }}</span
              >
            </div>

            <a
              v-for="(user, idx) in userResults"
              :key="user.searchableId"
              :href="resultHref(user)"
              class="result-item result-item--compact"
              :style="{ animationDelay: `${0.08 + idx * 0.03}s` }"
              @click.prevent="goToResult(user)"
            >
              <div class="result-thumb">
                <img v-if="user.avatarUrl" :src="user.avatarUrl" :alt="user.content" />
                <div v-else class="result-thumb-placeholder">
                  {{ user.content.charAt(0).toUpperCase() }}
                </div>
              </div>
              <div class="result-info">
                <div class="result-title">{{ user.content }}</div>
              </div>
            </a>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick, onBeforeUnmount } from "vue";
import { useRouter } from "vue-router";
import { debounce } from "lodash-es";
import { gqlClient } from "@/graphql/client";
import { GLOBAL_SEARCH } from "@/graphql/queries/resources";
import { useSearchOverlay } from "@/composables/useSearchOverlay";
import type { GameSearchResult, SearchResultUnion, UserSearchResult } from "@/types/graphql";
import { Search, X, Gamepad2, Briefcase, Monitor, Users } from "lucide-vue-next";

const router = useRouter();
const { isOpen, close } = useSearchOverlay();
const searchInputRef = ref<HTMLInputElement | null>(null);
const overlayRef = ref<HTMLElement | null>(null);

// Close overlay on Escape, and trap focus within the overlay
function onDocumentKeydown(e: KeyboardEvent) {
  if (e.key === "Escape") {
    close();
    return;
  }

  if (e.key === "Tab" && overlayRef.value) {
    const focusable = overlayRef.value.querySelectorAll<HTMLElement>(
      'input, button, a[href], [tabindex]:not([tabindex="-1"])'
    );
    if (focusable.length === 0) return;

    const first = focusable[0];
    const last = focusable[focusable.length - 1];

    if (e.shiftKey) {
      if (document.activeElement === first) {
        e.preventDefault();
        last.focus();
      }
    } else {
      if (document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
    }
  }
}

onBeforeUnmount(() => {
  document.removeEventListener("keydown", onDocumentKeydown);
});

const query = ref("");
const results = ref<SearchResultUnion[]>([]);
const loading = ref(false);
const hasSearched = ref(false);
const error = ref<string | null>(null);

// Group results by type
const dedicatedTypes = new Set(["GAME", "COMPANY", "PLATFORM", "USER"]);
const gameResults = computed(() => results.value.filter((r): r is GameSearchResult => r.searchableType === "GAME"));
const companyResults = computed(() => results.value.filter((r) => r.searchableType === "COMPANY"));
const platformResults = computed(() => results.value.filter((r) => r.searchableType === "PLATFORM"));
const userResults = computed(() => results.value.filter((r): r is UserSearchResult => r.searchableType === "USER"));
const otherResults = computed(() => results.value.filter((r) => !dedicatedTypes.has(r.searchableType)));

const totalResults = computed(() => results.value.length);

// Dynamically set grid columns based on which categories have results
const gridColumnsClass = computed(() => {
  const cols = [
    gameResults.value.length > 0,
    companyResults.value.length > 0,
    platformResults.value.length > 0,
    otherResults.value.length > 0,
    userResults.value.length > 0
  ].filter(Boolean).length;
  return `grid-cols-${Math.min(cols, 4)}`;
});

// Focus input when overlay opens, and listen for Escape globally
watch(isOpen, async (open) => {
  if (open) {
    await nextTick();
    searchInputRef.value?.focus();
    document.body.style.overflow = "hidden";
    document.addEventListener("keydown", onDocumentKeydown);
  } else {
    document.body.style.overflow = "";
    document.removeEventListener("keydown", onDocumentKeydown);
    query.value = "";
    results.value = [];
    hasSearched.value = false;
    loading.value = false;
    error.value = null;
  }
});

const performSearch = debounce(async () => {
  if (query.value.length < 2) {
    results.value = [];
    hasSearched.value = false;
    error.value = null;
    return;
  }

  loading.value = true;
  error.value = null;
  try {
    const data = await gqlClient.request<{
      globalSearch: { nodes: SearchResultUnion[] };
    }>(GLOBAL_SEARCH, { query: query.value });

    results.value = data.globalSearch.nodes;
    hasSearched.value = true;
  } catch (e: unknown) {
    const message = e instanceof Error ? e.message : "Unknown error";
    error.value = message;
    results.value = [];
    hasSearched.value = true;
  } finally {
    loading.value = false;
  }
}, 250);

function onSearch() {
  performSearch();
}

function goToFirstResult() {
  if (results.value.length > 0) {
    goToResult(results.value[0]);
  }
}

const typeRouteMap: Record<string, string> = {
  GAME: "games",
  USER: "users",
  PLATFORM: "platforms",
  COMPANY: "companies",
  ENGINE: "engines",
  GENRE: "genres",
  SERIES: "series",
  STORE: "stores"
};

function resultHref(result: SearchResultUnion): string {
  const path = typeRouteMap[result.searchableType];
  if (!path) return "#";
  const id = result.searchableType === "USER" ? (result as UserSearchResult).slug : result.searchableId;
  return `/${path}/${id}`;
}

function goToResult(result: SearchResultUnion) {
  const href = resultHref(result);
  if (href !== "#") {
    router.push(href);
  }
  close();
}

function gameInitials(name: string): string {
  return name
    .split(/[\s:]+/)
    .filter((w) => w.length > 0)
    .slice(0, 4)
    .map((w) => w.charAt(0).toUpperCase())
    .join("");
}

function releaseYear(date: string): string {
  return date.split("-")[0];
}
</script>

<style scoped>
/* ── Overlay backdrop (frosted glass) ── */
.search-overlay {
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  flex-direction: column;
  align-items: center;
  overflow-y: auto;
  backdrop-filter: blur(28px) saturate(1.2);
  -webkit-backdrop-filter: blur(28px) saturate(1.2);
  background: rgba(30, 33, 48, 0.72);
}

@media (prefers-color-scheme: light) {
  .search-overlay {
    background: rgba(30, 33, 48, 0.88);
  }
}

/* ── Search bar area ── */
.search-header {
  flex-shrink: 0;
  padding: 48px 24px 0;
  max-width: 780px;
  width: 100%;
}

.search-bar-wrap {
  view-transition-name: search-bar;
  position: relative;
  display: flex;
  align-items: center;
  background: var(--s-600);
  border: 1.5px solid var(--s-300);
  border-radius: 14px;
  padding: 0 14px 0 18px;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.15);
  transition:
    border-color 0.2s,
    box-shadow 0.2s;
}

.search-bar-wrap:focus-within {
  border-color: var(--p-400);
  box-shadow:
    0 0 0 3px rgba(123, 119, 209, 0.15),
    0 4px 24px rgba(0, 0, 0, 0.15);
}

.search-icon {
  flex-shrink: 0;
  width: 20px;
  height: 20px;
  color: var(--s-200);
  transition: color 0.2s;
}

.search-bar-wrap:focus-within .search-icon {
  color: var(--p-300);
}

.search-input {
  flex: 1;
  background: none;
  border: none;
  outline: none;
  color: var(--s-50);
  font-family: inherit;
  font-size: 18px;
  font-weight: 400;
  padding: 18px 14px;
  caret-color: var(--p-300);
}

.search-input::placeholder {
  color: var(--s-200);
  font-weight: 400;
}

.search-hint {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  gap: 5px;
  color: var(--s-200);
  font-size: 12px;
}

.kbd {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 2px 7px;
  border-radius: 5px;
  background: rgba(85, 90, 110, 0.3);
  border: 1px solid var(--s-300);
  font-family: inherit;
  font-size: 11px;
  font-weight: 500;
  color: var(--s-200);
  line-height: 1.4;
}

.search-close {
  flex-shrink: 0;
  margin-left: 8px;
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: 1px solid var(--s-300);
  background: rgba(85, 90, 110, 0.3);
  color: var(--s-200);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s;
}

.search-close:hover,
.search-close:focus-visible {
  background: var(--s-400);
  color: var(--s-50);
  border-color: var(--s-200);
}

.search-close:focus-visible {
  outline: 2px solid var(--p-400);
  outline-offset: 2px;
}

/* ── Empty / loading / error states ── */
.search-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 4rem 2rem;
  color: var(--s-200);
  font-size: 15px;
  text-align: center;
}

.search-empty-icon {
  width: 56px;
  height: 56px;
  color: var(--s-200);
  opacity: 0.7;
}

.search-empty-hint {
  font-size: 13px;
  color: var(--s-200);
}

.search-query-highlight {
  color: var(--p-300);
  font-weight: 500;
}

.search-error-text {
  color: var(--r-200);
}

.search-spinner {
  width: 32px;
  height: 32px;
  border: 3px solid rgba(85, 90, 110, 0.4);
  border-top-color: var(--p-300);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

/* ── Results area ── */
.search-results {
  flex: 1;
  overflow-y: auto;
  padding: 12px 24px 40px;
  max-width: 780px;
  width: 100%;
  scrollbar-width: thin;
  scrollbar-color: var(--s-300) transparent;
}

.search-results::-webkit-scrollbar {
  width: 6px;
}

.search-results::-webkit-scrollbar-track {
  background: transparent;
}

.search-results::-webkit-scrollbar-thumb {
  background: var(--s-300);
  border-radius: 3px;
}

.results-grid {
  display: grid;
  gap: 0;
}

.grid-cols-1 {
  grid-template-columns: 1fr;
}

.grid-cols-2 {
  grid-template-columns: 1fr 1fr;
}

.grid-cols-3 {
  grid-template-columns: 1fr 1fr 1fr;
}

.grid-cols-4 {
  grid-template-columns: 1fr 1fr 1fr 1fr;
}

/* ── Category column ── */
.category {
  min-width: 0;
  padding: 0 8px;
}

.category + .category {
  border-left: 1px solid rgba(85, 90, 110, 0.4);
  padding-left: 24px;
}

.category:first-child {
  padding-right: 24px;
}

.category-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
  padding: 4px 8px 10px;
}

.category-icon {
  width: 14px;
  height: 14px;
  color: var(--s-200);
}

.category-title {
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.6px;
  text-transform: uppercase;
  color: var(--s-200);
}

.category-count {
  margin-left: auto;
  font-size: 11px;
  color: var(--s-200);
  font-weight: 400;
}

/* ── Result items ── */
.result-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.12s;
  position: relative;
  animation: itemSlideIn 0.25s ease-out both;
  text-decoration: none;
  color: inherit;
}

.result-item:hover,
.result-item:focus-visible {
  background: rgba(206, 203, 246, 0.06);
  outline: none;
}

.result-item:active {
  background: rgba(206, 203, 246, 0.1);
}

.result-item:focus-visible {
  background: var(--s-400);
  outline: 1px solid var(--s-300);
}

@keyframes itemSlideIn {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* ── Thumbnails ── */
.result-thumb {
  width: 44px;
  height: 58px;
  border-radius: 6px;
  overflow: hidden;
  flex-shrink: 0;
  background: var(--s-400);
  border: 1px solid var(--s-300);
}

.result-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.result-thumb-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--s-300);
  font-size: 9px;
  font-weight: 600;
  text-align: center;
  padding: 4px;
  text-transform: uppercase;
  letter-spacing: 0.3px;
  line-height: 1.3;
  user-select: none;
}

/* ── Compact items (users, companies) ── */
.result-item--compact .result-thumb {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: none;
  background: var(--p-500);
}

.result-item--compact .result-thumb-placeholder {
  color: #fff;
  font-size: 15px;
  font-weight: 600;
  text-transform: none;
  letter-spacing: 0;
}

.result-item--compact .result-title {
  font-size: 14px;
}

/* ── Result text ── */
.result-info {
  min-width: 0;
  flex: 1;
}

.result-title {
  font-size: 14px;
  font-weight: 500;
  color: var(--s-50);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  line-height: 1.3;
}

.result-item:hover .result-title {
  color: #fff;
}

.result-meta {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-top: 1px;
}

.result-year {
  font-size: 12px;
  color: var(--s-200);
}

.result-developer {
  font-size: 12px;
  color: var(--s-200);
}

.result-type-tag {
  display: inline-block;
  font-size: 10px;
  font-weight: 500;
  padding: 2px 8px;
  border-radius: 10px;
  background: rgba(206, 203, 246, 0.12);
  color: var(--p-200);
  letter-spacing: 0.2px;
}

/* ── Responsive ── */
@media (max-width: 900px) {
  .grid-cols-3,
  .grid-cols-4 {
    grid-template-columns: 1fr 1fr;
  }
}

@media (max-width: 640px) {
  .search-header {
    padding-top: 16px;
    padding-left: 12px;
    padding-right: 12px;
  }

  .search-results {
    padding-left: 12px;
    padding-right: 12px;
  }

  .search-bar-wrap {
    border-radius: 12px;
  }

  .search-input {
    font-size: 16px;
    padding: 14px 12px;
  }

  .search-hint {
    display: none;
  }

  .grid-cols-4,
  .grid-cols-3,
  .grid-cols-2 {
    grid-template-columns: 1fr;
  }

  .category + .category {
    border-left: none;
    padding-left: 8px;
    margin-top: 16px;
  }

  .category:first-child {
    padding-right: 8px;
  }
}
</style>
