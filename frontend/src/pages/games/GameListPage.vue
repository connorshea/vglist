<template>
  <section class="section">
    <h1 class="title">Games</h1>

    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading games...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load games: {{ error.message }}</p>
    </div>

    <div v-if="data" class="columns is-multiline">
      <div v-for="game in data.games.nodes" :key="game.id" class="column is-3">
        <div class="card game-list-card">
          <div class="card-image" v-if="game.coverUrl">
            <figure class="image is-3by4">
              <img :src="game.coverUrl" :alt="game.name" />
            </figure>
          </div>
          <div class="card-image" v-else>
            <div class="game-cover-placeholder">
              <span>{{ gameInitials(game.name) }}</span>
            </div>
          </div>
          <div class="card-content">
            <p class="title is-5">
              <router-link :to="`/games/${game.id}`">{{ game.name }}</router-link>
            </p>
            <p class="subtitle is-6" v-if="game.releaseDate">
              {{ game.releaseDate }}
            </p>
            <p v-if="game.developers.nodes.length" class="is-size-7 has-text-grey">
              {{ game.developers.nodes.map((d: { name: string }) => d.name).join(", ") }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <PaginationNav
      v-if="data && (currentPage > 1 || hasNextPage)"
      :current-page="currentPage"
      :has-next-page="hasNextPage"
      :loading="loading"
      @prev="prevPage"
      @next="nextPage"
    />
  </section>
</template>

<script setup lang="ts">
import { ref, watch, computed } from "vue";
import { useQuery } from "@/composables/useGraphQL";
import { GET_GAMES } from "@/graphql/queries/games";
import type { GetGamesQuery } from "@/types/graphql";
import PaginationNav from "@/components/PaginationNav.vue";

const PAGE_SIZE = 20;
const currentPage = ref(1);
const pageCursors = ref<(string | null)[]>([null]);

const { data, loading, error } = useQuery<GetGamesQuery>(GET_GAMES, {
  variables: () => ({
    first: PAGE_SIZE,
    after: pageCursors.value[currentPage.value - 1],
  }),
});

const hasNextPage = computed(() => data.value?.games.pageInfo.hasNextPage ?? false);

watch(data, (val) => {
  if (val?.games.pageInfo.endCursor) {
    pageCursors.value[currentPage.value] = val.games.pageInfo.endCursor;
  }
});

function gameInitials(name: string): string {
  return name
    .split(/[\s:]+/)
    .filter((w) => w.length > 0)
    .slice(0, 3)
    .map((w) => w[0].toUpperCase())
    .join("");
}

function nextPage() {
  if (hasNextPage.value) currentPage.value++;
}

function prevPage() {
  if (currentPage.value > 1) currentPage.value--;
}
</script>

<style scoped>
.game-list-card {
  height: 100%;
  overflow: hidden;
  border-radius: 6px;
}

.game-cover-placeholder {
  aspect-ratio: 3 / 4;
  background: linear-gradient(135deg, #e879a0 0%, #c266d6 50%, #7c5ce7 100%);
  display: flex;
  align-items: center;
  justify-content: center;
}

.game-cover-placeholder span {
  font-size: 2.5rem;
  font-weight: 700;
  color: #fff;
  letter-spacing: 0.05em;
}
</style>
