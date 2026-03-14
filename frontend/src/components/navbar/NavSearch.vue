<template>
  <div class="navbar-search" style="position: relative">
    <div class="control">
      <input
        v-model="query"
        @input="onSearch"
        @keyup.enter="goToSearch"
        class="input is-small"
        type="search"
        placeholder="Search..."
      />
    </div>
    <div
      v-if="showDropdown && results.length > 0"
      class="navbar-search-dropdown box p-2"
      style="position: absolute; top: 100%; left: 0; z-index: 100; min-width: 300px"
    >
      <a
        v-for="result in results"
        :key="`${result.searchableType}-${result.searchableId}`"
        class="navbar-item"
        @click="goToResult(result)"
      >
        <span class="tag is-light mr-2">{{ result.searchableType }}</span>
        {{ result.content }}
      </a>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from "vue";
import { useRouter } from "vue-router";
import { debounce } from "lodash-es";
import { gqlClient } from "@/graphql/client";
import { GLOBAL_SEARCH } from "@/graphql/queries/resources";

interface SearchResult {
  searchableId: string;
  searchableType: string;
  content: string;
}

const router = useRouter();
const query = ref("");
const results = ref<SearchResult[]>([]);
const showDropdown = ref(false);

const performSearch = debounce(async () => {
  if (query.value.length < 2) {
    results.value = [];
    showDropdown.value = false;
    return;
  }

  const data = await gqlClient.request<{
    globalSearch: { nodes: SearchResult[] };
  }>(GLOBAL_SEARCH, { query: query.value });

  results.value = data.globalSearch.nodes;
  showDropdown.value = true;
}, 250);

function onSearch() {
  performSearch();
}

function goToSearch() {
  if (query.value.length > 0) {
    router.push({ name: "search", query: { q: query.value } });
    showDropdown.value = false;
    query.value = "";
  }
}

function goToResult(result: SearchResult) {
  const typeRouteMap: Record<string, string> = {
    Game: "game",
    User: "user",
    Platform: "platform",
    Company: "company",
    Engine: "engine",
    Genre: "genre",
    Series: "series",
    Store: "store"
  };

  const routeName = typeRouteMap[result.searchableType];
  if (routeName) {
    router.push({ name: routeName, params: { id: result.searchableId } });
  }

  showDropdown.value = false;
  query.value = "";
}

// Close dropdown when clicking elsewhere
watch(query, (val) => {
  if (val.length === 0) showDropdown.value = false;
});
</script>
