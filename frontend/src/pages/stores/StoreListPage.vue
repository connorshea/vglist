<template>
  <section class="section">
    <h1 class="title">Stores</h1>

    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading stores...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load stores: {{ error.message }}</p>
    </div>

    <div v-if="data" class="content">
      <ul>
        <li v-for="store in data.stores.nodes" :key="store.id">
          <router-link :to="`/stores/${store.id}`">{{ store.name }}</router-link>
        </li>
      </ul>
    </div>

    <div
      v-if="data?.stores.pageInfo.hasNextPage"
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
import { GET_STORES } from '@/graphql/queries/resources'
import type { GetStoresQuery } from '@/types/graphql'

const { data, loading, error, fetchMore } = useQuery<GetStoresQuery>(GET_STORES, {
  variables: { first: 25 },
})

function loadMore() {
  if (!data.value) return

  fetchMore(
    { first: 25, after: data.value.stores.pageInfo.endCursor },
    (prev, next) => ({
      stores: {
        ...next.stores,
        nodes: [...prev.stores.nodes, ...next.stores.nodes],
      },
    }),
  )
}
</script>
