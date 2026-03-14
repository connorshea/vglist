<template>
  <section class="section">
    <h1 class="title">Genres</h1>

    <div v-if="loading && !result" class="has-text-centered">
      <p>Loading genres...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load genres: {{ error.message }}</p>
    </div>

    <div v-if="result" class="content">
      <ul>
        <li v-for="genre in result.genres.nodes" :key="genre.id">
          <router-link :to="`/genres/${genre.id}`">{{ genre.name }}</router-link>
        </li>
      </ul>
    </div>

    <div
      v-if="result?.genres.pageInfo.hasNextPage"
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
import { GET_GENRES } from '@/graphql/queries/resources'

const { result, loading, error, fetchMore } = useQuery(GET_GENRES, {
  first: 25,
})

function loadMore() {
  fetchMore({
    variables: {
      first: 25,
      after: result.value.genres.pageInfo.endCursor,
    },
    updateQuery(previousResult, { fetchMoreResult }) {
      if (!fetchMoreResult) return previousResult

      return {
        genres: {
          ...fetchMoreResult.genres,
          nodes: [
            ...previousResult.genres.nodes,
            ...fetchMoreResult.genres.nodes,
          ],
        },
      }
    },
  })
}
</script>
