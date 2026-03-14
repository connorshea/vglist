<template>
  <section class="section">
    <h1 class="title">Platforms</h1>

    <div v-if="loading && !result" class="has-text-centered">
      <p>Loading platforms...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load platforms: {{ error.message }}</p>
    </div>

    <div v-if="result" class="content">
      <ul>
        <li v-for="platform in result.platforms.nodes" :key="platform.id">
          <router-link :to="`/platforms/${platform.id}`">{{ platform.name }}</router-link>
        </li>
      </ul>
    </div>

    <div
      v-if="result?.platforms.pageInfo.hasNextPage"
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
import { GET_PLATFORMS } from '@/graphql/queries/resources'

const { result, loading, error, fetchMore } = useQuery(GET_PLATFORMS, {
  first: 25,
})

function loadMore() {
  fetchMore({
    variables: {
      first: 25,
      after: result.value.platforms.pageInfo.endCursor,
    },
    updateQuery(previousResult, { fetchMoreResult }) {
      if (!fetchMoreResult) return previousResult

      return {
        platforms: {
          ...fetchMoreResult.platforms,
          nodes: [
            ...previousResult.platforms.nodes,
            ...fetchMoreResult.platforms.nodes,
          ],
        },
      }
    },
  })
}
</script>
