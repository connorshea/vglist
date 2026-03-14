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
        <a
          :href="`https://www.wikidata.org/wiki/Q${data.company.wikidataId}`"
          target="_blank"
          rel="noopener noreferrer"
          >Wikidata</a
        >
      </p>

      <div v-if="data.company.developedGames.nodes.length">
        <h2 class="title is-4 mt-5">Developed Games</h2>

        <div class="columns is-multiline">
          <div v-for="game in data.company.developedGames.nodes" :key="game.id" class="column is-3">
            <GameCard :id="game.id" :name="game.name" :cover-url="game.coverUrl" />
          </div>
        </div>
      </div>

      <div v-if="data.company.publishedGames.nodes.length">
        <h2 class="title is-4 mt-5">Published Games</h2>

        <div class="columns is-multiline">
          <div v-for="game in data.company.publishedGames.nodes" :key="game.id" class="column is-3">
            <GameCard :id="game.id" :name="game.name" :cover-url="game.coverUrl" />
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { useRoute } from "vue-router";
import { useQuery } from "@/composables/useGraphQL";
import { GET_COMPANY } from "@/graphql/queries/resources";
import type { GetCompanyQuery } from "@/types/graphql";
import GameCard from "@/components/GameCard.vue";

const route = useRoute();

const { data, loading, error } = useQuery<GetCompanyQuery>(GET_COMPANY, {
  variables: { id: route.params.id }
});
</script>
