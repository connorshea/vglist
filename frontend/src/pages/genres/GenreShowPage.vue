<template>
  <section class="section">
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading genre...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load genre: {{ error.message }}</p>
    </div>

    <div v-if="data">
      <h1 class="title">{{ data.genre.name }}</h1>

      <p v-if="data.genre.wikidataId" class="subtitle is-6">
        Wikidata ID: {{ data.genre.wikidataId }}
      </p>

      <h2 class="title is-4 mt-5">Games</h2>

      <div class="columns is-multiline">
        <div
          v-for="game in data.genre.games.nodes"
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
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { useRoute } from 'vue-router'
import { useQuery } from '@/composables/useGraphQL'
import { GET_GENRE } from '@/graphql/queries/resources'
import type { GetGenreQuery } from '@/types/graphql'

const route = useRoute()

const { data, loading, error } = useQuery<GetGenreQuery>(GET_GENRE, {
  variables: { id: route.params.id },
})
</script>
