<template>
  <section class="section">
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading genre...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load genre: {{ error.message }}</p>
    </div>

    <div v-if="data?.genre">
      <h1 class="title">{{ data.genre.name }}</h1>

      <p v-if="data.genre.wikidataId" class="subtitle is-6">
        <a :href="`https://www.wikidata.org/wiki/Q${data.genre.wikidataId}`" target="_blank" rel="noopener noreferrer"
          >Wikidata</a
        >
      </p>

      <h2 class="title is-4 mt-5">Games</h2>

      <div class="columns is-multiline">
        <div v-for="game in data.genre.games.nodes" :key="game.id" class="column is-3">
          <GameCard :id="game.id" :name="game.name" :cover-url="game.coverUrl ?? null" />
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useQuery } from "@/composables/useGraphQL";
import { GET_GENRE } from "@/graphql/queries/resources";
import type { GetGenreQuery } from "@/types/graphql";
import GameCard from "@/components/GameCard.vue";

const route = useRoute("genre");
const router = useRouter();

const { data, loading, error } = useQuery<GetGenreQuery>(GET_GENRE, {
  variables: { id: route.params.id }
});

watch([data, error, loading], () => {
  if (!loading.value && (error.value || (data.value && !data.value.genre))) {
    router.replace({ name: "notFound" });
  }
});
</script>
