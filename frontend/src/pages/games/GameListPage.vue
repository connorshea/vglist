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
        <GameCard :id="game.id" :name="game.name" :cover-url="game.coverUrl">
          <p class="subtitle is-6" v-if="game.releaseDate">
            {{ game.releaseDate }}
          </p>
          <p v-if="game.developers.nodes.length" class="is-size-7 has-text-grey">
            {{ game.developers.nodes.map((d: { name: string }) => d.name).join(", ") }}
          </p>
        </GameCard>
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
import GameCard from "@/components/GameCard.vue";

const PAGE_SIZE = 20;
const currentPage = ref(1);
const pageCursors = ref<(string | null)[]>([null]);

const { data, loading, error } = useQuery<GetGamesQuery>(GET_GAMES, {
  variables: () => ({
    first: PAGE_SIZE,
    after: pageCursors.value[currentPage.value - 1]
  })
});

const hasNextPage = computed(() => data.value?.games.pageInfo.hasNextPage ?? false);

watch(data, (val) => {
  if (val?.games.pageInfo.endCursor) {
    pageCursors.value[currentPage.value] = val.games.pageInfo.endCursor;
  }
});

function nextPage() {
  if (hasNextPage.value) currentPage.value++;
}

function prevPage() {
  if (currentPage.value > 1) currentPage.value--;
}
</script>
