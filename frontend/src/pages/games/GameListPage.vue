<template>
  <section class="section">
    <h1 class="title">Games</h1>

    <div v-if="loading && !result" class="has-text-centered">
      <p>Loading games...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load games: {{ error.message }}</p>
    </div>

    <div v-if="result" class="columns is-multiline">
      <div
        v-for="game in result.games.nodes"
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
            <p v-if="game.developers.length" class="is-size-7 has-text-grey">
              {{ game.developers.map((d: { name: string }) => d.name).join(', ') }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <div
      v-if="result?.games.pageInfo.hasNextPage"
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
import { GET_GAMES } from '@/graphql/queries/games'

const { result, loading, error, fetchMore } = useQuery(GET_GAMES, {
  first: 20,
})

function loadMore() {
  fetchMore({
    variables: {
      first: 20,
      after: result.value.games.pageInfo.endCursor,
    },
    updateQuery(previousResult, { fetchMoreResult }) {
      if (!fetchMoreResult) return previousResult

      return {
        games: {
          ...fetchMoreResult.games,
          nodes: [
            ...previousResult.games.nodes,
            ...fetchMoreResult.games.nodes,
          ],
        },
      }
    },
  })
}
</script>
