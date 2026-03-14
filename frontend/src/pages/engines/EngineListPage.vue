<template>
  <section class="section">
    <h1 class="title">Engines</h1>

    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading engines...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load engines: {{ error.message }}</p>
    </div>

    <div v-if="data" class="content">
      <ul>
        <li v-for="engine in data.engines.nodes" :key="engine.id">
          <router-link :to="`/engines/${engine.id}`">{{ engine.name }}</router-link>
        </li>
      </ul>
    </div>

    <div
      v-if="data?.engines.pageInfo.hasNextPage"
      class="has-text-centered mt-5"
    >
      <button
        class="button is-primary"
        :class="{ 'is-loading': loading }"
        :disabled="loading"
        @click="loadMore"
      >
        Load More
      </button>
    </div>
  </section>
</template>

<script setup lang="ts">
import { useQuery } from '@/composables/useGraphQL'
import { GET_ENGINES } from '@/graphql/queries/resources'
import type { GetEnginesData } from '@/types/graphql'

const { data, loading, error, fetchMore } = useQuery<GetEnginesData>(GET_ENGINES, {
  variables: { first: 25 },
})

function loadMore() {
  if (!data.value) return

  fetchMore(
    { first: 25, after: data.value.engines.pageInfo.endCursor },
    (prev, next) => ({
      engines: {
        ...next.engines,
        nodes: [...prev.engines.nodes, ...next.engines.nodes],
      },
    }),
  )
}
</script>
