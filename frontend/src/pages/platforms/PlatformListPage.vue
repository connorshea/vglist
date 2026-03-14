<template>
  <section class="section">
    <h1 class="title">Platforms</h1>

    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading platforms...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load platforms: {{ error.message }}</p>
    </div>

    <div v-if="data" class="content">
      <ul>
        <li v-for="platform in data.platforms.nodes" :key="platform.id">
          <router-link :to="`/platforms/${platform.id}`">{{ platform.name }}</router-link>
        </li>
      </ul>
    </div>

    <div
      v-if="data?.platforms.pageInfo.hasNextPage"
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
import { GET_PLATFORMS } from '@/graphql/queries/resources'
import type { GetPlatformsQuery } from '@/types/graphql'

const { data, loading, error, fetchMore } = useQuery<GetPlatformsQuery>(GET_PLATFORMS, {
  variables: { first: 25 },
})

function loadMore() {
  if (!data.value) return

  fetchMore(
    { first: 25, after: data.value.platforms.pageInfo.endCursor },
    (prev, next) => ({
      platforms: {
        ...next.platforms,
        nodes: [...prev.platforms.nodes, ...next.platforms.nodes],
      },
    }),
  )
}
</script>
