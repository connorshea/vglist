<template>
  <section class="section">
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading series...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load series: {{ error.message }}</p>
    </div>

    <div v-if="data">
      <h1 class="title">{{ data.series.name }}</h1>

      <p v-if="data.series.wikidataId" class="subtitle is-6">
        Wikidata ID: {{ data.series.wikidataId }}
      </p>

      <h2 class="title is-4 mt-5">Games</h2>

      <div class="columns is-multiline">
        <div
          v-for="game in data.series.games.nodes"
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
import { GET_SERIES } from '@/graphql/queries/resources'
import type { GetSeriesData } from '@/types/graphql'

const route = useRoute()

const { data, loading, error } = useQuery<GetSeriesData>(GET_SERIES, {
  variables: { id: route.params.id },
})
</script>
