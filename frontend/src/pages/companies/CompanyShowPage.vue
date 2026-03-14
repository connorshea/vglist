<template>
  <section class="section">
    <div v-if="loading && !result" class="has-text-centered">
      <p>Loading company...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load company: {{ error.message }}</p>
    </div>

    <div v-if="result">
      <h1 class="title">{{ result.company.name }}</h1>

      <p v-if="result.company.wikidataId" class="subtitle is-6">
        Wikidata ID: {{ result.company.wikidataId }}
      </p>

      <div v-if="result.company.developedGames.nodes.length">
        <h2 class="title is-4 mt-5">Developed Games</h2>

        <div class="columns is-multiline">
          <div
            v-for="game in result.company.developedGames.nodes"
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

      <div v-if="result.company.publishedGames.nodes.length">
        <h2 class="title is-4 mt-5">Published Games</h2>

        <div class="columns is-multiline">
          <div
            v-for="game in result.company.publishedGames.nodes"
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
import { useQuery } from '@vue/apollo-composable'
import { GET_COMPANY } from '@/graphql/queries/resources'

const route = useRoute()

const { result, loading, error } = useQuery(GET_COMPANY, {
  id: route.params.id,
})
</script>
