<template>
  <section class="section">
    <h1 class="title">Engines</h1>

    <div v-if="loading && !result" class="has-text-centered">
      <p>Loading engines...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load engines: {{ error.message }}</p>
    </div>

    <div v-if="result" class="content">
      <ul>
        <li v-for="engine in result.engines.nodes" :key="engine.id">
          <router-link :to="`/engines/${engine.id}`">{{ engine.name }}</router-link>
        </li>
      </ul>
    </div>

    <div
      v-if="result?.engines.pageInfo.hasNextPage"
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
import { GET_ENGINES } from '@/graphql/queries/resources'

const { result, loading, error, fetchMore } = useQuery(GET_ENGINES, {
  first: 25,
})

function loadMore() {
  fetchMore({
    variables: {
      first: 25,
      after: result.value.engines.pageInfo.endCursor,
    },
    updateQuery(previousResult, { fetchMoreResult }) {
      if (!fetchMoreResult) return previousResult

      return {
        engines: {
          ...fetchMoreResult.engines,
          nodes: [
            ...previousResult.engines.nodes,
            ...fetchMoreResult.engines.nodes,
          ],
        },
      }
    },
  })
}
</script>
