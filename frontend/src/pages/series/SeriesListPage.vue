<template>
  <section class="section">
    <h1 class="title">Series</h1>

    <div v-if="loading && !result" class="has-text-centered">
      <p>Loading series...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load series: {{ error.message }}</p>
    </div>

    <div v-if="result" class="content">
      <ul>
        <li v-for="s in result.seriesList.nodes" :key="s.id">
          <router-link :to="`/series/${s.id}`">{{ s.name }}</router-link>
        </li>
      </ul>
    </div>

    <div
      v-if="result?.seriesList.pageInfo.hasNextPage"
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
import { GET_SERIES_LIST } from '@/graphql/queries/resources'

const { result, loading, error, fetchMore } = useQuery(GET_SERIES_LIST, {
  first: 25,
})

function loadMore() {
  fetchMore({
    variables: {
      first: 25,
      after: result.value.seriesList.pageInfo.endCursor,
    },
    updateQuery(previousResult, { fetchMoreResult }) {
      if (!fetchMoreResult) return previousResult

      return {
        seriesList: {
          ...fetchMoreResult.seriesList,
          nodes: [
            ...previousResult.seriesList.nodes,
            ...fetchMoreResult.seriesList.nodes,
          ],
        },
      }
    },
  })
}
</script>
