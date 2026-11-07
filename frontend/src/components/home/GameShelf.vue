<template>
  <section v-if="!loaded || games.length > 0" class="game-shelf" :aria-labelledby="headingId">
    <div class="game-shelf-head">
      <h2 :id="headingId" class="game-shelf-title">{{ sort.label }}</h2>
      <router-link :to="seeAllLink" class="game-shelf-more">
        See all<span class="is-sr-only"> {{ sort.label.toLowerCase() }}</span>
        <ArrowRight :size="14" aria-hidden="true" />
      </router-link>
    </div>
    <ul v-if="loaded" class="game-shelf-grid">
      <li v-for="game in games" :key="game.id">
        <GameTile
          :id="game.id"
          :name="game.name"
          :cover-url="game.coverUrl ?? null"
          :meta="tileMeta(game)"
          :rating="game.avgRating"
          :in-library="game.isInLibrary"
          :completion-status="game.libraryCompletionStatus"
        />
      </li>
    </ul>
    <ul v-else class="game-shelf-grid" aria-hidden="true">
      <li v-for="n in SHELF_SIZE" :key="n" class="game-shelf-placeholder"></li>
    </ul>
  </section>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { ArrowRight } from "@lucide/vue";
import { useQuery } from "@/composables/useGraphQL";
import { GET_GAMES_INDEX } from "@/graphql/queries/games-index";
import type { GetGamesIndexQuery } from "@/types/graphql";
import GameTile from "@/components/games-index/GameTile.vue";
import {
  DEFAULT_GAME_SORT,
  EMPTY_FILTERS,
  filterVariables,
  tileMeta,
  type GameSortOption
} from "@/components/games-index/format";

// One row of games on the home page: the first few games under one of the
// games index's sorts, with a link to the rest of them there.

const SHELF_SIZE = 6;

const props = defineProps<{ sort: GameSortOption }>();

const headingId = computed(() => `shelf-${props.sort.slug}`);

const seeAllLink = computed(() => ({
  path: "/games",
  query: props.sort === DEFAULT_GAME_SORT ? {} : { sort: props.sort.slug }
}));

// Uses the games index's own query, so the home page sends nothing the index
// doesn't already.
const { data, error } = useQuery<GetGamesIndexQuery>(GET_GAMES_INDEX, {
  variables: () => ({
    first: SHELF_SIZE,
    after: null,
    sortBy: props.sort.value,
    ...filterVariables(EMPTY_FILTERS),
    withCount: false
  })
});

const games = computed(() => data.value?.games?.nodes ?? []);
// A shelf that failed to load is left out rather than shown broken.
const loaded = computed(() => data.value !== null || error.value !== null);
</script>

<style scoped>
.game-shelf-head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 1.25rem;
}

.game-shelf-title {
  margin: 0;
  font-size: 1.375rem;
  font-weight: 700;
  letter-spacing: -0.2px;
  color: var(--color-text-primary);
}

.game-shelf-more {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 0.875rem;
  font-weight: 500;
  border-radius: 4px;
  /* Taller tap target without shifting the heading row. */
  padding: 10px 0;
  margin: -10px 0;
}

.game-shelf-more:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.game-shelf-grid {
  display: grid;
  grid-template-columns: repeat(6, minmax(0, 1fr));
  gap: 20px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.game-shelf-placeholder {
  aspect-ratio: 3 / 4;
  border-radius: 10px;
  background: var(--color-bg-subtle);
}

@media (max-width: 1023px) {
  .game-shelf-grid {
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }

  .game-shelf-grid > li:nth-child(n + 5) {
    display: none;
  }
}

/* On a phone the row scrolls sideways instead of wrapping. */
@media (max-width: 768px) {
  .game-shelf-grid {
    display: flex;
    gap: 12px;
    overflow-x: auto;
    margin: 0 -1.5rem;
    padding: 0 1.5rem 4px;
    scroll-padding-inline: 1.5rem;
    scroll-snap-type: x proximity;
  }

  .game-shelf-grid > li,
  .game-shelf-grid > li:nth-child(n + 5) {
    display: block;
    flex: 0 0 112px;
    min-width: 0;
    scroll-snap-align: start;
  }
}
</style>
