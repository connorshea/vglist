<template>
  <section class="section">
    <div v-if="loading && !result" class="has-text-centered">
      <p>Loading game...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load game: {{ error.message }}</p>
    </div>

    <div v-if="game">
      <div class="columns">
        <div class="column is-3" v-if="game.coverUrl">
          <figure class="image">
            <img :src="game.coverUrl" :alt="game.name" />
          </figure>
        </div>

        <div class="column">
          <h1 class="title">{{ game.name }}</h1>

          <div class="tags" v-if="game.avgRating">
            <span class="tag is-info is-medium">
              Rating: {{ game.avgRating.toFixed(1) }}
            </span>
          </div>

          <table class="table is-fullwidth">
            <tbody>
              <tr v-if="game.releaseDate">
                <th>Release Date</th>
                <td>{{ game.releaseDate }}</td>
              </tr>
              <tr v-if="game.developers.length">
                <th>Developers</th>
                <td>{{ game.developers.map((d: { name: string }) => d.name).join(', ') }}</td>
              </tr>
              <tr v-if="game.publishers.length">
                <th>Publishers</th>
                <td>{{ game.publishers.map((p: { name: string }) => p.name).join(', ') }}</td>
              </tr>
              <tr v-if="game.platforms.length">
                <th>Platforms</th>
                <td>
                  <div class="tags">
                    <span
                      v-for="platform in game.platforms"
                      :key="platform.id"
                      class="tag"
                    >
                      {{ platform.name }}
                    </span>
                  </div>
                </td>
              </tr>
              <tr v-if="game.genres.length">
                <th>Genres</th>
                <td>
                  <div class="tags">
                    <span
                      v-for="genre in game.genres"
                      :key="genre.id"
                      class="tag is-primary is-light"
                    >
                      {{ genre.name }}
                    </span>
                  </div>
                </td>
              </tr>
              <tr v-if="game.engines.length">
                <th>Engines</th>
                <td>{{ game.engines.map((e: { name: string }) => e.name).join(', ') }}</td>
              </tr>
              <tr v-if="game.series">
                <th>Series</th>
                <td>{{ game.series.name }}</td>
              </tr>
            </tbody>
          </table>

          <div v-if="authStore.isAuthenticated" class="buttons mt-4">
            <button
              class="button is-success"
              :class="{ 'is-loading': addingToLibrary }"
              :disabled="addingToLibrary"
              @click="addToLibrary"
            >
              Add to Library
            </button>
            <button
              class="button is-warning"
              :class="{ 'is-loading': favoriting }"
              :disabled="favoriting"
              @click="favoriteGame"
            >
              Favorite
            </button>
          </div>

          <div v-if="actionMessage" class="notification mt-3" :class="actionMessageClass">
            <button class="delete" @click="actionMessage = ''"></button>
            {{ actionMessage }}
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'
import { useQuery } from '@vue/apollo-composable'
import { useAuthStore } from '@/stores/auth'
import { apolloClient } from '@/graphql/client'
import { GET_GAME } from '@/graphql/queries/games'
import { ADD_GAME_TO_LIBRARY, FAVORITE_GAME } from '@/graphql/mutations/games'

const route = useRoute()
const authStore = useAuthStore()

const gameId = computed(() => route.params.id as string)

const { result, loading, error } = useQuery(GET_GAME, () => ({
  id: gameId.value,
}))

const game = computed(() => result.value?.game ?? null)

const addingToLibrary = ref(false)
const favoriting = ref(false)
const actionMessage = ref('')
const actionIsError = ref(false)

const actionMessageClass = computed(() =>
  actionIsError.value ? 'is-danger' : 'is-success',
)

async function addToLibrary() {
  addingToLibrary.value = true
  actionMessage.value = ''

  try {
    await apolloClient.mutate({
      mutation: ADD_GAME_TO_LIBRARY,
      variables: { gameId: gameId.value },
    })
    actionMessage.value = `${game.value.name} has been added to your library.`
    actionIsError.value = false
  } catch (err) {
    actionMessage.value = `Failed to add game to library: ${(err as Error).message}`
    actionIsError.value = true
  } finally {
    addingToLibrary.value = false
  }
}

async function favoriteGame() {
  favoriting.value = true
  actionMessage.value = ''

  try {
    await apolloClient.mutate({
      mutation: FAVORITE_GAME,
      variables: { gameId: gameId.value },
    })
    actionMessage.value = `${game.value.name} has been favorited.`
    actionIsError.value = false
  } catch (err) {
    actionMessage.value = `Failed to favorite game: ${(err as Error).message}`
    actionIsError.value = true
  } finally {
    favoriting.value = false
  }
}
</script>
