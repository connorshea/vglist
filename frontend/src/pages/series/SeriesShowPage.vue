<template>
  <section class="section">
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading series...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load series: {{ error.message }}</p>
    </div>

    <div v-if="data?.series">
      <h1 class="title">{{ data.series.name }}</h1>

      <p v-if="data.series.wikidataId" class="subtitle is-6">
        <a :href="`https://www.wikidata.org/wiki/Q${data.series.wikidataId}`" target="_blank" rel="noopener noreferrer"
          >Wikidata</a
        >
      </p>

      <h2 class="title is-4 mt-5">Games</h2>

      <div class="columns is-multiline">
        <div v-for="game in data.series.games.nodes" :key="game.id" class="column is-3">
          <GameCard :id="game.id" :name="game.name" :cover-url="game.coverUrl ?? null" />
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { useRoute } from "vue-router";
import { useQuery } from "@/composables/useGraphQL";
import { GET_SERIES } from "@/graphql/queries/resources";
import type { GetSeriesQuery } from "@/types/graphql";
import GameCard from "@/components/GameCard.vue";

const route = useRoute("series");

const { data, loading, error } = useQuery<GetSeriesQuery>(GET_SERIES, {
  variables: { id: route.params.id }
});
</script>
