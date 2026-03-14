<template>
  <section class="section">
    <h1 class="title">Search Results</h1>

    <div v-if="!query" class="notification is-info">
      <p>Enter a search query to find games, companies, platforms, and more.</p>
    </div>

    <div v-if="loading && !data" class="has-text-centered">
      <p>Searching...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Search failed: {{ error.message }}</p>
    </div>

    <div v-if="data && query">
      <div v-if="data.globalSearch.nodes.length === 0" class="notification is-warning">
        <p>No results found for "{{ query }}".</p>
      </div>

      <div v-for="(items, type) in groupedResults" :key="type" class="mb-5">
        <h2 class="title is-4">{{ type }}</h2>
        <div class="content">
          <ul>
            <li v-for="item in items" :key="item.searchableId">
              <router-link :to="resultLink(item)">{{ item.content }}</router-link>
            </li>
          </ul>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useQuery } from '@/composables/useGraphQL'
import { GLOBAL_SEARCH } from '@/graphql/queries/resources'
import type { GlobalSearchQuery } from '@/types/graphql'

const route = useRoute()

const query = computed(() => (route.query.q as string) ?? '')

const { data, loading, error } = useQuery<GlobalSearchQuery>(GLOBAL_SEARCH, {
  variables: () => ({ query: query.value }),
  enabled: () => query.value.length > 0,
})

interface SearchResult {
  searchableId: string
  searchableType: string
  content: string
}

const groupedResults = computed(() => {
  if (!data.value) return {}

  const groups: Record<string, SearchResult[]> = {}
  for (const node of data.value.globalSearch.nodes) {
    const type = node.searchableType as string
    if (!groups[type]) {
      groups[type] = []
    }
    groups[type].push(node as SearchResult)
  }
  return groups
})

function resultLink(item: SearchResult): string {
  const typeToPath: Record<string, string> = {
    Game: 'games',
    Company: 'companies',
    Platform: 'platforms',
    Engine: 'engines',
    Genre: 'genres',
    Series: 'series',
    Store: 'stores',
    User: 'users',
  }

  const path = typeToPath[item.searchableType] ?? 'games'
  return `/${path}/${item.searchableId}`
}
</script>
