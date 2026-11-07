<template>
  <div class="overview">
    <p v-if="overview?.bio" class="overview-bio">{{ overview.bio }}</p>

    <LibraryEmptyState v-if="!overview" :loading="loading" :error="error" :library-empty="false" />

    <template v-else>
      <section v-if="favorites.totalCount > 0" class="overview-section" aria-labelledby="overview-favorites">
        <div class="overview-section-header">
          <Heart :size="14" aria-hidden="true" class="overview-heart" />
          <h2 id="overview-favorites">Favorites</h2>
          <span class="overview-count">{{ favorites.totalCount.toLocaleString() }}</span>
          <router-link
            v-if="moreFavorites > 0"
            :to="{ name: 'userFavorites', params: { slug } }"
            class="overview-section-link"
          >
            See all {{ favorites.totalCount.toLocaleString() }}
          </router-link>
        </div>
        <div class="overview-grid">
          <LibraryGameTile v-for="tile in favoriteTiles" :key="tile.id" :purchase="tile" />
          <router-link
            v-if="moreFavorites > 0"
            :to="{ name: 'userFavorites', params: { slug } }"
            class="overview-more"
            :aria-label="`See all ${favorites.totalCount} favorites`"
          >
            <span class="overview-peek" aria-hidden="true">
              <span v-for="game in peekFavorites" :key="game.id" class="overview-peek-cover">
                <img v-if="game.coverUrl" :src="game.coverUrl" alt="" loading="lazy" />
                <span v-else class="cover-placeholder"></span>
              </span>
            </span>
            <b aria-hidden="true">+{{ moreFavorites.toLocaleString() }}</b>
            <span aria-hidden="true">more</span>
          </router-link>
        </div>
      </section>

      <section v-if="playing.totalCount > 0" class="overview-section" aria-labelledby="overview-playing">
        <div class="overview-section-header">
          <span class="status-dot st-in-progress" aria-hidden="true"></span>
          <h2 id="overview-playing">Playing</h2>
          <span class="overview-count">{{ playing.totalCount.toLocaleString() }}</span>
          <router-link
            v-if="playing.totalCount > playing.nodes.length"
            :to="{ name: 'userLibrary', params: { slug }, query: { status: 'IN_PROGRESS' } }"
            class="overview-section-link"
          >
            See all {{ playing.totalCount.toLocaleString() }}
          </router-link>
        </div>
        <div class="overview-playing">
          <LibraryPlayingCard
            v-for="purchase in playing.nodes"
            :key="purchase.id"
            :purchase="purchase"
            :hide-hours="hideHours"
          />
        </div>
      </section>

      <section v-if="topRated.totalCount > 0" class="overview-section" aria-labelledby="overview-library">
        <div class="overview-section-header">
          <h2 id="overview-library">{{ anyRated ? "Highest rated" : "Library" }}</h2>
          <router-link :to="{ name: 'userLibrary', params: { slug } }" class="overview-section-link">
            View library ({{ topRated.totalCount.toLocaleString() }})
          </router-link>
        </div>
        <div class="overview-grid">
          <LibraryGameTile
            v-for="purchase in topRated.nodes"
            :key="purchase.id"
            :purchase="purchase"
            :hide-hours="hideHours"
          />
        </div>
      </section>

      <LibraryEmptyState
        v-if="topRated.totalCount === 0 && favorites.totalCount === 0"
        :loading="false"
        :error="null"
        :library-empty="true"
      />
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useRoute } from "vue-router";
import { Heart } from "@lucide/vue";
import { useQuery } from "@/composables/useGraphQL";
import { useUserProfile } from "@/composables/useUserProfile";
import { GET_USER_OVERVIEW } from "@/graphql/queries/users";
import type { GetUserOverviewQuery, LibraryGamePurchaseFieldsFragment } from "@/types/graphql";
import LibraryEmptyState from "@/components/library/LibraryEmptyState.vue";
import LibraryGameTile from "@/components/library/LibraryGameTile.vue";
import LibraryPlayingCard from "@/components/library/LibraryPlayingCard.vue";

// Five favorites and a "+N more" tile fill one row of six; the next three
// favorites peek out of that tile.
const FAVORITES_SHOWN = 5;
const FAVORITES_PEEKED = 3;
const PLAYING_COUNT = 3;
// Two rows of six.
const TOP_RATED_COUNT = 12;

const route = useRoute("user");
const { user } = useUserProfile();

const slug = computed(() => route.params.slug);
const hideHours = computed(() => user.value?.hideDaysPlayed ?? false);

const { data, loading, error } = useQuery<GetUserOverviewQuery>(GET_USER_OVERVIEW, {
  variables: () => ({
    slug: slug.value,
    favoritesCount: FAVORITES_SHOWN + FAVORITES_PEEKED,
    playingCount: PLAYING_COUNT,
    topRatedCount: TOP_RATED_COUNT
  })
});

const overview = computed(() => data.value?.user ?? null);
const favorites = computed(() => overview.value?.favoritedGames ?? { totalCount: 0, nodes: [] });
const playing = computed(() => overview.value?.playing ?? { totalCount: 0, nodes: [] });
const topRated = computed(() => overview.value?.topRated ?? { totalCount: 0, nodes: [] });

// When every favorite fits, the row shows them all rather than a "+1 more".
const favoritesShown = computed(() =>
  favorites.value.totalCount <= FAVORITES_SHOWN + 1 ? FAVORITES_SHOWN + 1 : FAVORITES_SHOWN
);
const moreFavorites = computed(() => Math.max(0, favorites.value.totalCount - favoritesShown.value));
const peekFavorites = computed(() => favorites.value.nodes.slice(favoritesShown.value));

// Favorites aren't library entries, so their tiles have no status or rating.
const favoriteTiles = computed<LibraryGamePurchaseFieldsFragment[]>(() =>
  favorites.value.nodes.slice(0, favoritesShown.value).map((game) => ({
    id: game.id,
    game,
    hoursPlayed: null,
    completionStatus: null,
    rating: null
  }))
);

const anyRated = computed(() => topRated.value.nodes.some((purchase) => purchase.rating !== null));
</script>

<style scoped>
.overview {
  padding-top: 24px;
}

.overview-bio {
  max-width: 70ch;
  margin: 0 0 28px;
  color: var(--color-text-secondary);
  font-size: 0.9rem;
  line-height: 1.6;
  white-space: pre-line;
}

.overview-section {
  margin-bottom: 36px;
}

.overview-section-header {
  display: flex;
  gap: 8px;
  align-items: center;
  margin-bottom: 12px;
}

.overview-section-header h2 {
  margin: 0;
  color: var(--color-text-primary);
  font-size: 0.95rem;
  font-weight: 600;
}

.overview-heart {
  color: var(--r-500);
}

.overview-count {
  color: var(--color-text-tertiary);
  font-size: 0.75rem;
}

.overview-section-link {
  margin-left: auto;
  color: var(--color-accent);
  font-size: 0.75rem;
  font-weight: 500;
}

.overview-section-link:hover {
  text-decoration: underline;
}

.overview-section-link:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
  border-radius: var(--radius-sm);
}

/* Six across on a wide screen, so the grids line up with the library's. */
.overview-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
  gap: 10px;
}

.overview-playing {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 12px;
}

/* ── "+N more" favorites tile ── */
.overview-more {
  display: flex;
  flex-direction: column;
  gap: 2px;
  align-items: center;
  justify-content: center;
  aspect-ratio: 3 / 4;
  border: 1.5px dashed var(--color-border);
  border-radius: 10px;
  color: var(--color-text-secondary);
  font-size: 0.75rem;
  transition: border-color var(--transition-fast);
}

.overview-more:hover {
  border-color: var(--color-accent);
  color: var(--color-accent);
}

.overview-more:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.overview-more b {
  color: var(--color-text-primary);
  font-size: 1.25rem;
  font-weight: 700;
}

.overview-peek {
  display: flex;
  margin-bottom: 10px;
}

.overview-peek-cover {
  width: 34px;
  aspect-ratio: 3 / 4;
  overflow: hidden;
  border: 2px solid var(--color-surface);
  border-radius: 5px;
  background: var(--color-bg-subtle);
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.2);
}

.overview-peek-cover + .overview-peek-cover {
  margin-left: -12px;
}

.overview-peek-cover:nth-child(1) {
  transform: rotate(-6deg);
}

.overview-peek-cover:nth-child(3) {
  transform: rotate(6deg);
}

.overview-peek-cover img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

@media (max-width: 768px) {
  .overview {
    padding-top: 16px;
  }

  .overview-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 8px;
  }
}

@media (prefers-reduced-motion: reduce) {
  .overview-more {
    transition: none;
  }
}
</style>
