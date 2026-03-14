<template>
  <section class="section">
    <h1 class="title">Games</h1>

    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading games...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load games: {{ error.message }}</p>
    </div>

    <div v-if="data" class="columns is-multiline">
      <div
        v-for="game in data.games.nodes"
        :key="game.id"
        class="column is-3"
      >
        <div class="card">
          <div class="card-image" v-if="game.coverUrl">
            <figure class="image is-3by4">
              <img :src="game.coverUrl" :alt="game.name" />
            </figure>
          </div>
          <div class="card-content">
            <p class="title is-5">
              <router-link :to="`/games/${game.id}`">{{ game.name }}</router-link>
            </p>
            <p class="subtitle is-6" v-if="game.releaseDate">
              {{ game.releaseDate }}
            </p>
            <p v-if="game.developers.nodes.length" class="is-size-7 has-text-grey">
              {{ game.developers.nodes.map((d: { name: string }) => d.name).join(', ') }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <div
      v-if="data?.games.pageInfo.hasNextPage"
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
import { GET_GAMES } from '@/graphql/queries/games'
import type { GetGamesQuery } from '@/types/graphql'

const { data, loading, error, fetchMore } = useQuery<GetGamesQuery>(GET_GAMES, {
  variables: { first: 20 },
})

function loadMore() {
  if (!data.value) return

  fetchMore(
    { first: 20, after: data.value.games.pageInfo.endCursor },
    (prev, next) => ({
      games: {
        ...next.games,
        nodes: [
          ...prev.games.nodes,
          ...next.games.nodes,
        ],
      },
    }),
  )
}
</script>
