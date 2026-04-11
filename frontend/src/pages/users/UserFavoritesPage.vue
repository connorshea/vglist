<template>
  <section class="section">
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>{{ error.message }}</p>
    </div>

    <div v-if="user">
      <h1 class="title">
        <router-link :to="`/users/${route.params.slug}`">{{ user.username }}</router-link>
        &rsaquo; Favorite Games
      </h1>

      <p v-if="!favoritedGames.length" class="has-text-centered has-text-grey py-6">No favorite games yet.</p>

      <div class="columns is-multiline">
        <div v-for="game in favoritedGames" :key="game.id" class="column is-2">
          <GameCard :id="game.id" :name="game.name" :cover-url="game.coverUrl ?? null" />
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useQuery } from "@/composables/useGraphQL";
import { GET_USER } from "@/graphql/queries/users";
import type { GetUserQuery } from "@/types/graphql";
import GameCard from "@/components/GameCard.vue";

const route = useRoute("userFavorites");
const router = useRouter();

const { data, loading, error } = useQuery<GetUserQuery>(GET_USER, {
  variables: () => ({ slug: route.params.slug })
});

watch([data, error, loading], () => {
  if (!loading.value && (error.value || (data.value && !data.value.user))) {
    router.replace({ name: "notFound" });
  }
});

const user = computed(() => data.value?.user ?? null);
const favoritedGames = computed(() => user.value?.favoritedGames?.nodes ?? []);
</script>
