<template>
  <section class="section">
    <h1 class="title">Stores</h1>

    <div v-if="loading && !result" class="has-text-centered">
      <p>Loading stores...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load stores: {{ error.message }}</p>
    </div>

    <div v-if="result" class="content">
      <ul>
        <li v-for="store in result.stores.nodes" :key="store.id">
          <router-link :to="`/stores/${store.id}`">{{ store.name }}</router-link>
        </li>
      </ul>
    </div>

    <div
      v-if="result?.stores.pageInfo.hasNextPage"
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
import { useQuery } from '@vue/apollo-composable'
import { GET_STORES } from '@/graphql/queries/resources'

const { result, loading, error, fetchMore } = useQuery(GET_STORES, {
  first: 25,
})

function loadMore() {
  fetchMore({
    variables: {
      first: 25,
      after: result.value.stores.pageInfo.endCursor,
    },
    updateQuery(previousResult, { fetchMoreResult }) {
      if (!fetchMoreResult) return previousResult

      return {
        stores: {
          ...fetchMoreResult.stores,
          nodes: [
            ...previousResult.stores.nodes,
            ...fetchMoreResult.stores.nodes,
          ],
        },
      }
    },
  })
}
</script>
