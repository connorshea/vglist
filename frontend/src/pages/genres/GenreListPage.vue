<template>
  <section class="section">
    <h1 class="title">Genres</h1>

    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading genres...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load genres: {{ error.message }}</p>
    </div>

    <div v-if="data" class="content">
      <ul>
        <li v-for="genre in data.genres.nodes" :key="genre.id">
          <router-link :to="`/genres/${genre.id}`">{{ genre.name }}</router-link>
        </li>
      </ul>
    </div>

    <div
      v-if="data?.genres.pageInfo.hasNextPage"
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
import { GET_GENRES } from '@/graphql/queries/resources'
import type { GetGenresQuery } from '@/types/graphql'

const { data, loading, error, fetchMore } = useQuery<GetGenresQuery>(GET_GENRES, {
  variables: { first: 25 },
})

function loadMore() {
  if (!data.value) return

  fetchMore(
    { first: 25, after: data.value.genres.pageInfo.endCursor },
    (prev, next) => ({
      genres: {
        ...next.genres,
        nodes: [...prev.genres.nodes, ...next.genres.nodes],
      },
    }),
  )
}
</script>
