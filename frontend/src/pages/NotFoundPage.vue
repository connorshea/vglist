<template>
  <div class="not-found">
    <div class="not-found-top">
      <div class="not-found-slot" aria-hidden="true">
        <span class="not-found-slot-mark">?</span>
        <span class="not-found-slot-code">404</span>
      </div>

      <div class="not-found-text">
        <h1 class="not-found-heading">This one’s not on the shelf</h1>
        <p class="not-found-lede">
          We couldn’t find <code class="not-found-path">{{ route.path }}</code
          >. Try searching for it instead.
        </p>
      </div>

      <form class="not-found-search" role="search" @submit.prevent="search">
        <Search :size="18" aria-hidden="true" />
        <label for="not-found-query" class="is-sr-only">Search games</label>
        <input
          id="not-found-query"
          v-model="query"
          type="search"
          autocomplete="off"
          placeholder="Search games, series and companies"
        />
        <button type="submit" class="not-found-search-btn">Search</button>
      </form>
    </div>

    <nav class="not-found-links" aria-label="Other places to go">
      <span>Or go to</span>
      <router-link to="/">Home</router-link>
      <router-link :to="{ name: 'games' }">Games</router-link>
      <router-link v-if="librarySlug" :to="{ name: 'userLibrary', params: { slug: librarySlug } }">
        Your library
      </router-link>
      <router-link :to="{ name: 'activity' }">Activity</router-link>
    </nav>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { useRoute } from "vue-router";
import { Search } from "@lucide/vue";
import { useAuthStore } from "@/stores/auth";
import { useSearchOverlay } from "@/composables/useSearchOverlay";
import { searchQueryFromPath } from "@/utils/not-found";

const route = useRoute();
const authStore = useAuthStore();
const { open: openSearch } = useSearchOverlay();

// Prefilled from the missing URL, and refilled when another missing URL
// reuses this page.
const query = ref(searchQueryFromPath(route.path));
watch(
  () => route.path,
  (path) => {
    query.value = searchQueryFromPath(path);
  }
);

const librarySlug = computed(() => (authStore.isAuthenticated ? (authStore.user?.slug ?? null) : null));

function search() {
  openSearch(query.value.trim());
}
</script>

<style scoped>
.not-found {
  --not-found-muted: var(--n-500);

  padding: 1rem 0 2rem;
}

@media (prefers-color-scheme: dark) {
  .not-found {
    --not-found-muted: var(--s-100);
  }
}

.not-found-top {
  display: grid;
  grid-template-columns: 168px minmax(0, 1fr);
  grid-template-rows: auto auto;
  column-gap: 40px;
  row-gap: 20px;
  max-width: 860px;
}

/* An empty, dashed cover slot where the missing game would sit. */
.not-found-slot {
  grid-row: span 2;
  aspect-ratio: 3 / 4;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  border: 2px dashed var(--color-border);
  border-radius: 10px;
  background: var(--color-bg-subtle);
  color: var(--not-found-muted);
}

.not-found-slot-mark {
  font-size: 64px;
  font-weight: 800;
  line-height: 1;
}

.not-found-slot-code {
  font-family: monospace;
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.12em;
}

.not-found-text {
  align-self: end;
}

.not-found-heading {
  margin: 0 0 10px;
  font-size: 36px;
  font-weight: 700;
  line-height: 1.15;
  letter-spacing: -0.4px;
  text-wrap: balance;
  color: var(--color-text-primary);
}

.not-found-lede {
  margin: 0;
  font-size: 16px;
  line-height: 1.6;
  color: var(--not-found-muted);
}

.not-found-path {
  display: inline-block;
  max-width: 100%;
  box-sizing: border-box;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  vertical-align: bottom;
  padding: 1px 8px;
  border: 1px solid var(--color-border);
  border-radius: 6px;
  background: var(--color-bg-subtle);
  color: var(--color-text-primary);
  font-size: 0.95em;
}

.not-found-search {
  align-self: start;
  display: flex;
  align-items: center;
  gap: 10px;
  max-width: 560px;
  height: 48px;
  box-sizing: border-box;
  padding: 0 6px 0 14px;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  background: var(--color-surface);
  color: var(--not-found-muted);
}

.not-found-search:focus-within {
  outline: 3px solid var(--p-300);
  outline-offset: 1px;
}

.not-found-search input {
  flex: 1;
  min-width: 0;
  border: 0;
  background: transparent;
  font: inherit;
  font-size: 16px;
  color: var(--color-text-primary);
  outline: none;
}

.not-found-search-btn {
  min-height: 36px;
  padding: 0 16px;
  border: 0;
  border-radius: 8px;
  background: var(--p-500);
  color: #fff;
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}

.not-found-search-btn:hover {
  background: var(--p-600);
}

.not-found-search-btn:focus-visible {
  outline: 3px solid var(--p-300);
  outline-offset: 2px;
}

.not-found-links {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px 18px;
  margin-top: 40px;
  padding-top: 20px;
  border-top: 1px solid var(--color-border);
  font-size: 14px;
  color: var(--not-found-muted);
}

.not-found-links a {
  font-weight: 500;
}

@media (max-width: 768px) {
  .not-found {
    padding: 0;
  }

  .not-found-top {
    grid-template-columns: 84px minmax(0, 1fr);
    column-gap: 16px;
    row-gap: 16px;
  }

  .not-found-slot {
    grid-row: auto;
    border-radius: 8px;
  }

  .not-found-slot-mark {
    font-size: 32px;
  }

  .not-found-slot-code {
    font-size: 10px;
  }

  .not-found-text {
    align-self: center;
  }

  .not-found-heading {
    margin: 0;
    font-size: 22px;
  }

  .not-found-lede {
    display: none;
  }

  .not-found-search {
    grid-column: 1 / -1;
    max-width: none;
  }
}
</style>
