<template>
  <section class="section">
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading platform...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load platform: {{ error.message }}</p>
    </div>

    <div v-if="data">
      <h1 class="title">{{ data.platform.name }}</h1>

      <p v-if="data.platform.wikidataId" class="subtitle is-6">
        Wikidata ID: {{ data.platform.wikidataId }}
      </p>

      <h2 class="title is-4 mt-5">Games</h2>

      <div class="columns is-multiline">
        <div v-for="game in data.platform.games.nodes" :key="game.id" class="column is-3">
          <GameCard :id="game.id" :name="game.name" :cover-url="game.coverUrl" />
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { useRoute } from "vue-router";
import { useQuery } from "@/composables/useGraphQL";
import { GET_PLATFORM } from "@/graphql/queries/resources";
import type { GetPlatformQuery } from "@/types/graphql";
import GameCard from "@/components/GameCard.vue";

const route = useRoute();

const { data, loading, error } = useQuery<GetPlatformQuery>(GET_PLATFORM, {
  variables: { id: route.params.id }
});
</script>
