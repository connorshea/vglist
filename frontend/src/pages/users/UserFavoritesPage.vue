<template>
  <div class="favorites">
    <p class="is-sr-only" role="status">{{ showSkeleton ? "Loading favorites…" : "" }}</p>

    <UserFavoritesSkeleton v-if="showSkeleton" />

    <div v-else class="favorites-grid">
      <LibraryGameTile v-for="tile in tiles" :key="tile.id" :purchase="tile" />
    </div>

    <div v-if="!tiles.length && !showSkeleton" class="favorites-empty" role="status">
      <p v-if="error">Couldn't load favorites: {{ error.message }}</p>
      <p v-else>No favorite games yet.</p>
    </div>

    <div v-if="hasNextPage" class="favorites-more">
      <button type="button" class="favorites-more-button" :disabled="loading" @click="loadMore">
        {{ loading ? "Loading…" : "Load more" }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useRoute } from "vue-router";
import { useQuery } from "@/composables/useGraphQL";
import { GET_USER_FAVORITES } from "@/graphql/queries/users";
import type { GetUserFavoritesQuery, LibraryGamePurchaseFieldsFragment } from "@/types/graphql";
import LibraryGameTile from "@/components/library/LibraryGameTile.vue";
import UserFavoritesSkeleton from "@/components/users/UserFavoritesSkeleton.vue";

const PAGE_SIZE = 48;

const route = useRoute("userFavorites");

const variables = computed(() => ({ slug: route.params.slug, first: PAGE_SIZE }));

const { data, loading, error, fetchMore } = useQuery<GetUserFavoritesQuery>(GET_USER_FAVORITES, {
  variables: () => variables.value
});

// Only on the first load; "Load more" keeps the grid up.
const showSkeleton = computed(() => loading.value && !data.value);

const connection = computed(() => data.value?.user?.favoritedGames ?? null);
const hasNextPage = computed(() => connection.value?.pageInfo.hasNextPage ?? false);

// Favorites aren't library entries, so their tiles have no status or rating.
const tiles = computed<LibraryGamePurchaseFieldsFragment[]>(() =>
  (connection.value?.nodes ?? []).map((game) => ({
    id: game.id,
    game,
    hoursPlayed: null,
    completionStatus: null,
    rating: null
  }))
);

async function loadMore() {
  const cursor = connection.value?.pageInfo.endCursor;
  if (!hasNextPage.value || loading.value || !cursor) {
    return;
  }

  await fetchMore({ ...variables.value, after: cursor }, (prev, next) => {
    if (!prev.user || !next.user) {
      return next;
    }
    return {
      ...next,
      user: {
        ...next.user,
        favoritedGames: {
          ...next.user.favoritedGames,
          nodes: [...prev.user.favoritedGames.nodes, ...next.user.favoritedGames.nodes]
        }
      }
    };
  });
}
</script>

<style scoped>
.favorites {
  padding-top: 24px;
}

.favorites-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
  gap: 10px;
}

.favorites-empty {
  padding: 48px 16px;
  color: var(--color-text-secondary);
  text-align: center;
}

.favorites-more {
  display: flex;
  justify-content: center;
  margin-top: 24px;
}

.favorites-more-button {
  padding: 7px 20px;
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius-button);
  background: transparent;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 0.85rem;
  font-weight: 500;
  cursor: pointer;
}

.favorites-more-button:hover {
  border-color: var(--color-accent);
  color: var(--color-accent);
}

.favorites-more-button:disabled {
  opacity: 0.6;
  cursor: default;
}

.favorites-more-button:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

@media (max-width: 768px) {
  .favorites {
    padding-top: 16px;
  }

  .favorites-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 8px;
  }
}
</style>
