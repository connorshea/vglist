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
          <SearchIcon class="search-icon" stroke-width="2" />
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
            <CloseIcon width="16" height="16" stroke-width="2" />
          </button>
        </div>
      </div>

      <div class="search-results">
        <!-- Empty state -->
        <div v-if="!query || query.length < 2" class="search-empty">
          <SearchIcon class="search-empty-icon" stroke-width="1.5" />
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
          <p>No results found for "{{ query }}"</p>
          <p class="search-empty-hint">Try a different search term</p>
        </div>

        <!-- Results grid -->
        <div v-else-if="totalResults > 0" class="results-grid" :class="gridColumnsClass">
          <!-- Games column -->
          <div v-if="gameResults.length" class="category">
            <div class="category-header">
              <GamepadIcon class="category-icon" />
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
                  <span v-if="game.releaseDate" class="result-year">{{
                    releaseYear(game.releaseDate)
                  }}</span>
                  <span v-if="game.developerName" class="result-developer">{{
                    game.developerName
                  }}</span>
                </div>
              </div>
            </a>
          </div>

          <!-- Companies column -->
          <div v-if="companyResults.length" class="category">
            <div class="category-header">
              <BriefcaseIcon class="category-icon" />
              <span class="category-title">Companies</span>
              <span class="category-count"
                >{{ companyResults.length }} result{{
                  companyResults.length === 1 ? "" : "s"
                }}</span
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
              <MonitorIcon class="category-icon" />
              <span class="category-title">Platforms</span>
              <span class="category-count"
                >{{ platformResults.length }} result{{
                  platformResults.length === 1 ? "" : "s"
                }}</span
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
              <BriefcaseIcon class="category-icon" />
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
              <UsersIcon class="category-icon" />
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
import type { SearchResultNode } from "@/types/graphql";
import SearchIcon from "@/components/icons/SearchIcon.vue";
import CloseIcon from "@/components/icons/CloseIcon.vue";
import GamepadIcon from "@/components/icons/GamepadIcon.vue";
import BriefcaseIcon from "@/components/icons/BriefcaseIcon.vue";
import MonitorIcon from "@/components/icons/MonitorIcon.vue";
import UsersIcon from "@/components/icons/UsersIcon.vue";

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
const results = ref<SearchResultNode[]>([]);
const loading = ref(false);
const hasSearched = ref(false);
const error = ref<string | null>(null);

// Group results by type
const dedicatedTypes = new Set(["GAME", "COMPANY", "PLATFORM", "USER"]);
const gameResults = computed(() => results.value.filter((r) => r.searchableType === "GAME"));
const companyResults = computed(() => results.value.filter((r) => r.searchableType === "COMPANY"));
const platformResults = computed(() =>
  results.value.filter((r) => r.searchableType === "PLATFORM")
);
const userResults = computed(() => results.value.filter((r) => r.searchableType === "USER"));
const otherResults = computed(() =>
  results.value.filter((r) => !dedicatedTypes.has(r.searchableType))
);

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
      globalSearch: { nodes: SearchResultNode[] };
    }>(GLOBAL_SEARCH, { query: query.value });

    results.value = data.globalSearch.nodes;
    hasSearched.value = true;
  } catch (e: unknown) {
    const message = e instanceof Error ? e.message : "Unknown error";
    error.value = message;
    results.value = [];
    hasSearched.value = true;
    console.error("Search failed:", e);
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

function resultHref(result: SearchResultNode): string {
  const path = typeRouteMap[result.searchableType];
  if (!path) return "#";
  const id = result.searchableType === "USER" && result.slug ? result.slug : result.searchableId;
  return `/${path}/${id}`;
}

function goToResult(result: SearchResultNode) {
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
/* ── Overlay backdrop ── */
.search-overlay {
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  flex-direction: column;
  backdrop-filter: blur(24px) saturate(1.2);
  -webkit-backdrop-filter: blur(24px) saturate(1.2);
  background: rgba(14, 10, 24, 0.82);
}

/* ── Search bar area ── */
.search-header {
  flex-shrink: 0;
  padding: 1.5rem 2rem 0;
  max-width: 1100px;
  width: 100%;
  margin: 0 auto;
}

.search-bar-wrap {
  view-transition-name: search-bar;
  position: relative;
  display: flex;
  align-items: center;
  background: rgba(26, 22, 37, 0.72);
  border: 1px solid rgba(155, 127, 204, 0.18);
  border-radius: 20px;
  padding: 0 1.25rem;
  box-shadow:
    0 0 0 1px rgba(123, 94, 167, 0.08),
    0 8px 40px rgba(0, 0, 0, 0.35),
    inset 0 1px 0 rgba(255, 255, 255, 0.04);
  transition:
    border-color 0.2s,
    box-shadow 0.2s;
}

.search-bar-wrap:focus-within {
  border-color: rgba(155, 127, 204, 0.4);
  box-shadow:
    0 0 0 3px rgba(123, 94, 167, 0.35),
    0 8px 40px rgba(0, 0, 0, 0.35),
    inset 0 1px 0 rgba(255, 255, 255, 0.04);
}

.search-icon {
  flex-shrink: 0;
  width: 22px;
  height: 22px;
  color: #7a6b91;
}

.search-input {
  flex: 1;
  background: none;
  border: none;
  outline: none;
  color: #f0ecf5;
  font-family: inherit;
  font-size: 1.15rem;
  font-weight: 400;
  padding: 1rem 0.85rem;
  letter-spacing: 0.01em;
}

.search-input::placeholder {
  color: #7a6b91;
}

.search-hint {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  gap: 0.4rem;
  color: #7a6b91;
  font-size: 0.75rem;
}

.kbd {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.15rem 0.45rem;
  border-radius: 5px;
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.08);
  font-family: inherit;
  font-size: 0.7rem;
  color: #a99bbf;
  line-height: 1.4;
}

.search-close {
  flex-shrink: 0;
  margin-left: 0.75rem;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  border: none;
  background: rgba(255, 255, 255, 0.06);
  color: #a99bbf;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition:
    background 0.15s,
    color 0.15s;
}

.search-close:hover,
.search-close:focus-visible {
  background: rgba(255, 255, 255, 0.12);
  color: #f0ecf5;
}

.search-close:focus-visible {
  outline: 2px solid rgba(155, 127, 204, 0.5);
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
  color: #d0c5e0;
  font-size: 0.95rem;
  text-align: center;
}

.search-empty-icon {
  width: 48px;
  height: 48px;
  color: #a99bbf;
  opacity: 0.6;
}

.search-empty-hint {
  font-size: 0.8rem;
  color: #a99bbf;
}

.search-error-text {
  color: #e86b8a;
}

.search-spinner {
  width: 32px;
  height: 32px;
  border: 3px solid rgba(155, 127, 204, 0.2);
  border-top-color: #9b7fcc;
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
  padding: 1.5rem 2rem 3rem;
  max-width: 1100px;
  width: 100%;
  margin: 0 auto;
  scrollbar-width: thin;
  scrollbar-color: #4a2d7a transparent;
}

.search-results::-webkit-scrollbar {
  width: 6px;
}
.search-results::-webkit-scrollbar-track {
  background: transparent;
}
.search-results::-webkit-scrollbar-thumb {
  background: #4a2d7a;
  border-radius: 3px;
}

.results-grid {
  display: grid;
  gap: 1.75rem;
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
}

.category-header {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  margin-bottom: 1rem;
  padding-bottom: 0.6rem;
  border-bottom: 1px solid rgba(155, 127, 204, 0.12);
}

.category-icon {
  width: 18px;
  height: 18px;
  color: #9b7fcc;
  opacity: 0.7;
}

.category-title {
  font-size: 0.78rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #a99bbf;
}

.category-count {
  margin-left: auto;
  font-size: 0.7rem;
  color: #7a6b91;
  font-weight: 500;
}

/* ── Result items ── */
.result-item {
  display: flex;
  align-items: center;
  gap: 0.85rem;
  padding: 0.6rem 0.7rem;
  border-radius: 8px;
  cursor: pointer;
  transition:
    background 0.15s,
    transform 0.1s;
  position: relative;
  animation: itemSlideIn 0.25s ease-out both;
  text-decoration: none;
  color: inherit;
}

.result-item:hover,
.result-item:focus-visible {
  background: rgba(90, 70, 130, 0.55);
  transform: translateX(2px);
  box-shadow: inset 0 0 0 1px rgba(155, 127, 204, 0.25);
  outline: none;
}

.result-item:focus-visible {
  box-shadow:
    inset 0 0 0 1px rgba(155, 127, 204, 0.25),
    0 0 0 2px rgba(155, 127, 204, 0.5);
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
  width: 48px;
  height: 64px;
  border-radius: 6px;
  overflow: hidden;
  flex-shrink: 0;
  background: rgba(255, 255, 255, 0.04);
  position: relative;
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
  color: #7a6b91;
  font-size: 0.65rem;
  font-weight: 500;
  text-align: center;
  padding: 0.25rem;
  background: linear-gradient(135deg, rgba(123, 94, 167, 0.15), rgba(94, 212, 200, 0.08));
  user-select: none;
}

/* ── Compact items (users, companies) ── */
.result-item--compact .result-thumb {
  width: 40px;
  height: 40px;
  border-radius: 50%;
}

.result-item--compact .result-title {
  font-size: 0.84rem;
}

/* ── Result text ── */
.result-info {
  min-width: 0;
  flex: 1;
}

.result-title {
  font-size: 0.88rem;
  font-weight: 600;
  color: #f0ecf5;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  line-height: 1.3;
}

.result-meta {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-top: 0.2rem;
}

.result-year {
  font-size: 0.75rem;
  color: #7a6b91;
  font-weight: 500;
}

.result-developer {
  font-size: 0.72rem;
  color: #5ed4c8;
  font-weight: 500;
  padding: 0.1rem 0.4rem;
  border-radius: 4px;
  background: rgba(94, 212, 200, 0.1);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 160px;
}

.result-type-tag {
  font-size: 0.68rem;
  color: #e8c86b;
  font-weight: 500;
  padding: 0.1rem 0.4rem;
  border-radius: 4px;
  background: rgba(232, 200, 107, 0.1);
}

/* ── Responsive ── */
@media (max-width: 900px) {
  .grid-cols-3,
  .grid-cols-4 {
    grid-template-columns: 1fr 1fr;
  }
  .search-header,
  .search-results {
    padding-left: 1.25rem;
    padding-right: 1.25rem;
  }
}

@media (max-width: 600px) {
  .grid-cols-4,
  .grid-cols-3,
  .grid-cols-2 {
    grid-template-columns: 1fr;
    gap: 2rem;
  }
  .search-hint {
    display: none;
  }
}
</style>
