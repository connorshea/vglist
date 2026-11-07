<template>
  <section v-if="games.length > 0" class="game-card series-shelf" aria-labelledby="game-series-heading">
    <div class="game-card-head">
      <h2 id="game-series-heading" class="game-card-label">More from this series</h2>
      <router-link v-if="totalCount > games.length" :to="seriesLink" class="series-shelf-more">
        See all {{ totalCount + 1 }}<span class="is-sr-only">{{ ` ${series.name} games` }}</span>
      </router-link>
    </div>
    <p class="series-shelf-name">
      <router-link :to="seriesLink">{{ series.name }}</router-link>
    </p>
    <ul class="series-shelf-grid">
      <li v-for="game in games" :key="game.id">
        <GameTile :id="game.id" :name="game.name" :cover-url="game.coverUrl" :meta="releaseYear(game.releaseDate)" />
      </li>
    </ul>
  </section>
</template>

<script setup lang="ts">
import { computed } from "vue";
import type { GetGameQuery } from "@/types/graphql";
import GameTile from "@/components/games-index/GameTile.vue";
import { releaseYear } from "@/components/games-index/format";

type Game = NonNullable<GetGameQuery["game"]>;

const props = defineProps<{
  series: NonNullable<Game["series"]>;
  games: Game["moreFromSeries"]["nodes"];
  // How many other games are in the series, of which `games` is the first few.
  totalCount: number;
}>();

const seriesLink = computed(() => `/series/${props.series.id}`);
</script>

<style scoped>
.series-shelf-more {
  font-size: 0.8125rem;
  font-weight: 500;
  border-radius: 4px;
}

.series-shelf-more:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.series-shelf-name {
  margin-bottom: 14px;
  font-size: 1rem;
  font-weight: 700;
}

.series-shelf-name a {
  color: var(--color-text-primary);
  border-radius: 4px;
}

.series-shelf-name a:hover {
  color: var(--color-accent);
}

.series-shelf-name a:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.series-shelf-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
  margin: 0;
  padding: 0;
  list-style: none;
}
</style>
