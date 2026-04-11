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
          <div class="card">
            <div v-if="game.coverUrl" class="card-image">
              <figure class="image is-3by4">
                <img :src="game.coverUrl" :alt="game.name" />
              </figure>
            </div>
            <div v-else class="card-image">
              <div class="game-cover-placeholder">
                <span>{{ gameInitials(game.name) }}</span>
              </div>
            </div>
            <div class="card-content p-3">
              <p class="has-text-centered">{{ game.name }}</p>
            </div>
          </div>
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

function gameInitials(name: string): string {
  return name
    .split(/[\s:]+/)
    .filter((w) => w.length > 0)
    .slice(0, 3)
    .map((w) => w[0].toUpperCase())
    .join("");
}
</script>

<style scoped>
.game-cover-placeholder {
  aspect-ratio: 3 / 4;
  background: linear-gradient(135deg, #e879a0 0%, #c266d6 50%, #7c5ce7 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  user-select: none;
  cursor: default;
}

.game-cover-placeholder span {
  font-size: 2.5rem;
  font-weight: 700;
  color: #fff;
  letter-spacing: 0.05em;
}
</style>
