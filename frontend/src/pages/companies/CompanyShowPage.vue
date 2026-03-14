<template>
  <section class="section">
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading company...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load company: {{ error.message }}</p>
    </div>

    <div v-if="data">
      <h1 class="title">{{ data.company.name }}</h1>

      <p v-if="data.company.wikidataId" class="subtitle is-6">
        Wikidata ID: {{ data.company.wikidataId }}
      </p>

      <div v-if="data.company.developedGames.nodes.length">
        <h2 class="title is-4 mt-5">Developed Games</h2>

        <div class="columns is-multiline">
          <div
            v-for="game in data.company.developedGames.nodes"
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

      <div v-if="data.company.publishedGames.nodes.length">
        <h2 class="title is-4 mt-5">Published Games</h2>

        <div class="columns is-multiline">
          <div
            v-for="game in data.company.publishedGames.nodes"
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
    </div>
  </section>
</template>

<script setup lang="ts">
import { useRoute } from 'vue-router'
import { useQuery } from '@/composables/useGraphQL'
import { GET_COMPANY } from '@/graphql/queries/resources'
import type { GetCompanyData } from '@/types/graphql'

const route = useRoute()

const { data, loading, error } = useQuery<GetCompanyData>(GET_COMPANY, {
  variables: { id: route.params.id },
})
</script>
