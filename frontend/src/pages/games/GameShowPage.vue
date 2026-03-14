<template>
  <div>
    <div v-if="loading && !data" class="has-text-centered py-6">
      <p>Loading game...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load game: {{ error.message }}</p>
    </div>

    <div v-if="game" class="game-show">
      <!-- Full-width purple hero -->
      <section class="game-hero">
        <div class="game-hero-inner">
          <div class="game-hero-cover">
            <img v-if="game.coverUrl" :src="game.coverUrl" :alt="game.name" />
            <div v-else class="game-cover-placeholder">
              <span>{{ gameInitials }}</span>
            </div>
          </div>

          <div class="game-hero-info">
            <h1 class="game-title">{{ game.name }}</h1>
            <p class="game-year">{{ releaseYear ?? "\u2014" }}</p>

            <div v-if="game.genres.nodes.length > 0" class="hero-tag-group">
              <h2 class="hero-tag-label">Genres</h2>
              <div class="hero-tag-list">
                <router-link
                  v-for="genre in visibleGenres"
                  :key="'g-' + genre.id"
                  :to="`/genres/${genre.id}`"
                  class="hero-tag"
                >
                  {{ genre.name }}
                </router-link>
                <span v-if="hiddenGenreCount > 0" class="hero-tag hero-tag-more">
                  +{{ hiddenGenreCount }} more
                </span>
              </div>
            </div>

            <div v-if="game.platforms.nodes.length > 0" class="hero-tag-group">
              <h2 class="hero-tag-label">Platforms</h2>
              <div class="hero-tag-list">
                <router-link
                  v-for="platform in visiblePlatforms"
                  :key="'p-' + platform.id"
                  :to="`/platforms/${platform.id}`"
                  class="hero-tag"
                >
                  {{ platform.name }}
                </router-link>
                <span v-if="hiddenPlatformCount > 0" class="hero-tag hero-tag-more">
                  +{{ hiddenPlatformCount }} more
                </span>
              </div>
            </div>

            <div v-if="authStore.isAuthenticated" class="game-hero-actions">
              <button
                v-if="!game.isInLibrary"
                class="hero-btn hero-btn-primary"
                :disabled="addingToLibrary"
                @click="addToLibrary"
              >
                + Add to library
              </button>
              <span v-else class="hero-btn hero-btn-active">In library</span>
              <button
                class="hero-btn"
                :class="{ 'hero-btn-active': game.isFavorited }"
                :disabled="favoriting"
                @click="toggleFavorite"
              >
                {{ game.isFavorited ? "Favorited" : "Favorite" }}
              </button>
            </div>
          </div>
        </div>
      </section>

      <!-- Content below hero -->
      <div class="game-body">
        <div class="columns is-variable is-6">
          <!-- Main column -->
          <div class="column is-8">
            <!-- Rating -->
            <div v-if="game.avgRating" class="game-rating">
              <div class="rating-circle-wrapper">
                <svg class="rating-circle-svg" viewBox="0 0 120 120">
                  <circle
                    class="rating-circle-bg"
                    cx="60"
                    cy="60"
                    r="52"
                    fill="none"
                    stroke-width="5"
                  />
                  <circle
                    cx="60"
                    cy="60"
                    r="52"
                    fill="none"
                    stroke="var(--vglist-theme)"
                    stroke-width="5"
                    :stroke-dasharray="ratingCircumference"
                    :stroke-dashoffset="ratingOffset"
                    stroke-linecap="round"
                    transform="rotate(-90 60 60)"
                  />
                </svg>
                <span class="rating-circle-value">{{ Math.round(game.avgRating) }}</span>
              </div>

              <div class="rating-bar-area">
                <div class="rating-bar-header">
                  <span>Average rating</span>
                  <span>{{ game.avgRating.toFixed(1) }} / 100</span>
                </div>
                <div class="rating-bar-track">
                  <div class="rating-bar-fill" :style="{ width: game.avgRating + '%' }"></div>
                </div>
              </div>
            </div>

            <!-- Details -->
            <h3 class="details-heading">DETAILS</h3>
            <div class="details-grid">
              <div v-if="game.releaseDate" class="detail-card">
                <span class="detail-label">RELEASE DATE</span>
                <span class="detail-value">{{ formatDate(game.releaseDate) }}</span>
              </div>
              <div v-if="game.publishers.nodes.length" class="detail-card">
                <span class="detail-label">PUBLISHER</span>
                <span class="detail-value">
                  <template v-for="(pub, i) in game.publishers.nodes" :key="pub.id">
                    <router-link :to="`/companies/${pub.id}`" class="detail-link">{{
                      pub.name
                    }}</router-link>
                    <span v-if="i < game.publishers.nodes.length - 1">, </span>
                  </template>
                </span>
              </div>
              <div v-if="game.developers.nodes.length" class="detail-card">
                <span class="detail-label">DEVELOPERS</span>
                <span class="detail-value">
                  <template v-for="(dev, i) in game.developers.nodes" :key="dev.id">
                    <router-link :to="`/companies/${dev.id}`" class="detail-link">{{
                      dev.name
                    }}</router-link>
                    <span v-if="i < game.developers.nodes.length - 1">, </span>
                  </template>
                </span>
              </div>
              <div v-if="game.engines.nodes.length" class="detail-card">
                <span class="detail-label">ENGINE</span>
                <span class="detail-value">
                  <template v-for="(eng, i) in game.engines.nodes" :key="eng.id">
                    <router-link :to="`/engines/${eng.id}`" class="detail-link">{{
                      eng.name
                    }}</router-link>
                    <span v-if="i < game.engines.nodes.length - 1">, </span>
                  </template>
                </span>
              </div>
              <div v-if="game.series" class="detail-card">
                <span class="detail-label">SERIES</span>
                <span class="detail-value">
                  <router-link :to="`/series/${game.series.id}`" class="detail-link">{{
                    game.series.name
                  }}</router-link>
                </span>
              </div>
              <div v-if="game.platforms.nodes.length" class="detail-card">
                <span class="detail-label">PLATFORM</span>
                <span class="detail-value">
                  <template v-for="(plat, i) in game.platforms.nodes" :key="plat.id">
                    <router-link :to="`/platforms/${plat.id}`" class="detail-link">{{
                      plat.name
                    }}</router-link>
                    <span v-if="i < game.platforms.nodes.length - 1">, </span>
                  </template>
                </span>
              </div>
            </div>
          </div>

          <!-- Sidebar -->
          <div class="column is-4">
            <div v-if="game.genres.nodes.length" class="sidebar-card">
              <h4 class="sidebar-card-title">Genres</h4>
              <div class="sidebar-tags">
                <router-link
                  v-for="genre in game.genres.nodes"
                  :key="genre.id"
                  :to="`/genres/${genre.id}`"
                  class="sidebar-tag"
                >
                  {{ genre.name }}
                </router-link>
              </div>
            </div>

            <div class="sidebar-card">
              <div class="community-section">
                <div class="community-header">
                  <h4 class="community-title">Owners</h4>
                  <span v-if="game.owners.totalCount > 0" class="community-count">
                    {{ game.owners.totalCount }} total
                  </span>
                </div>
                <div v-if="game.owners.nodes.length > 0" class="avatar-stack">
                  <router-link
                    v-for="owner in game.owners.nodes"
                    :key="owner.id"
                    :to="`/users/${owner.slug}`"
                    class="avatar-circle"
                    :title="owner.username"
                  >
                    <img v-if="owner.avatarUrl" :src="owner.avatarUrl" :alt="owner.username" />
                    <span
                      v-else
                      class="avatar-initials"
                      :style="{ background: avatarColor(owner.username) }"
                    >
                      {{ userInitials(owner.username) }}
                    </span>
                  </router-link>
                  <span
                    v-if="game.owners.totalCount > game.owners.nodes.length"
                    class="avatar-overflow"
                  >
                    +{{ game.owners.totalCount - game.owners.nodes.length }}
                  </span>
                </div>
                <p v-else class="community-empty">No owners yet.</p>
              </div>

              <hr class="community-divider" />

              <div class="community-section">
                <div class="community-header">
                  <h4 class="community-title">Favorited by</h4>
                  <span v-if="game.favoriters.totalCount > 0" class="community-count">
                    {{ game.favoriters.totalCount }} total
                  </span>
                </div>
                <div v-if="game.favoriters.nodes.length > 0" class="avatar-stack">
                  <router-link
                    v-for="fav in game.favoriters.nodes"
                    :key="fav.id"
                    :to="`/users/${fav.slug}`"
                    class="avatar-circle"
                    :title="fav.username"
                  >
                    <img v-if="fav.avatarUrl" :src="fav.avatarUrl" :alt="fav.username" />
                    <span
                      v-else
                      class="avatar-initials"
                      :style="{ background: avatarColor(fav.username) }"
                    >
                      {{ userInitials(fav.username) }}
                    </span>
                  </router-link>
                  <span
                    v-if="game.favoriters.totalCount > game.favoriters.nodes.length"
                    class="avatar-overflow"
                  >
                    +{{ game.favoriters.totalCount - game.favoriters.nodes.length }}
                  </span>
                </div>
                <p v-else class="community-empty">No favorites yet.</p>
              </div>
            </div>

            <div v-if="externalLinks.length" class="sidebar-card">
              <h4 class="sidebar-card-title">External links</h4>
              <ul class="external-links-list">
                <li v-for="link in externalLinks" :key="link.label">
                  <a :href="link.url" target="_blank" rel="noopener noreferrer">{{ link.label }}</a>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      <!-- Action notification -->
      <div v-if="actionMessage" class="notification game-notification" :class="actionMessageClass">
        <button class="delete" @click="actionMessage = ''"></button>
        {{ actionMessage }}
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from "vue";
import { useRoute } from "vue-router";
import { useQuery } from "@/composables/useGraphQL";
import { useAuthStore } from "@/stores/auth";
import { gqlClient } from "@/graphql/client";
import { GET_GAME } from "@/graphql/queries/games";
import { ADD_GAME_TO_LIBRARY, FAVORITE_GAME, UNFAVORITE_GAME } from "@/graphql/mutations/games";
import type { GetGameQuery } from "@/types/graphql";
import { extractGqlError } from "@/utils/graphql-errors";

const route = useRoute();
const authStore = useAuthStore();

const gameId = computed(() => route.params.id as string);

const { data, loading, error, refetch } = useQuery<GetGameQuery>(GET_GAME, {
  variables: () => ({ id: gameId.value })
});

const game = computed(() => data.value?.game ?? null);

const gameInitials = computed(() => {
  if (!game.value) return "";
  return game.value.name
    .split(/[\s:]+/)
    .filter((w) => w.length > 0)
    .slice(0, 3)
    .map((w) => w[0].toUpperCase())
    .join("");
});

const releaseYear = computed(() => {
  if (!game.value?.releaseDate) return null;
  return new Date(game.value.releaseDate).getFullYear();
});

const HERO_TAG_LIMIT = 3;

const visibleGenres = computed(() => game.value?.genres.nodes.slice(0, HERO_TAG_LIMIT) ?? []);
const hiddenGenreCount = computed(() =>
  Math.max(0, (game.value?.genres.nodes.length ?? 0) - HERO_TAG_LIMIT)
);

const visiblePlatforms = computed(() => game.value?.platforms.nodes.slice(0, HERO_TAG_LIMIT) ?? []);
const hiddenPlatformCount = computed(() =>
  Math.max(0, (game.value?.platforms.nodes.length ?? 0) - HERO_TAG_LIMIT)
);

const CIRCLE_RADIUS = 52;
const ratingCircumference = 2 * Math.PI * CIRCLE_RADIUS;

const ratingOffset = computed(() => {
  if (!game.value?.avgRating) return ratingCircumference;
  const pct = game.value.avgRating / 100;
  return ratingCircumference * (1 - pct);
});

function formatDate(dateStr: string): string {
  const d = new Date(dateStr);
  return d.toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" });
}

function userInitials(username: string): string {
  return username.slice(0, 2).toUpperCase();
}

const AVATAR_COLORS = [
  "#6c5ce7",
  "#00b894",
  "#e17055",
  "#0984e3",
  "#e84393",
  "#00a862",
  "#d63031",
  "#fdcb6e"
];

function avatarColor(username: string): string {
  let hash = 0;
  for (const ch of username) {
    hash = ((hash << 5) - hash + ch.charCodeAt(0)) | 0;
  }
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

interface ExternalLink {
  label: string;
  url: string;
}

const externalLinks = computed<ExternalLink[]>(() => {
  if (!game.value) return [];
  const links: ExternalLink[] = [];
  const g = game.value;

  if (g.wikidataId) {
    links.push({ label: "Wikidata", url: `https://www.wikidata.org/wiki/Q${g.wikidataId}` });
  }
  if (g.mobygamesId) {
    links.push({
      label: "MobyGames",
      url: `https://www.mobygames.com/game/${g.mobygamesId}`
    });
  }
  if (g.giantbombId) {
    links.push({
      label: "GiantBomb",
      url: `https://www.giantbomb.com/game/${g.giantbombId}/`
    });
  }
  if (g.igdbId) {
    links.push({ label: "IGDB", url: `https://www.igdb.com/games/${g.igdbId}` });
  }
  if (g.steamAppIds && g.steamAppIds.length > 0) {
    links.push({
      label: "Steam",
      url: `https://store.steampowered.com/app/${g.steamAppIds[0]}`
    });
  }
  if (g.pcgamingwikiId) {
    links.push({
      label: "PCGamingWiki",
      url: `https://www.pcgamingwiki.com/wiki/${g.pcgamingwikiId}`
    });
  }
  if (g.epicGamesStoreId) {
    links.push({
      label: "Epic Games Store",
      url: `https://store.epicgames.com/p/${g.epicGamesStoreId}`
    });
  }
  if (g.gogId) {
    links.push({ label: "GOG", url: `https://www.gog.com/game/${g.gogId}` });
  }

  return links;
});

// Action state
const addingToLibrary = ref(false);
const favoriting = ref(false);
const actionMessage = ref("");
const actionIsError = ref(false);

const actionMessageClass = computed(() => (actionIsError.value ? "is-danger" : "is-success"));

async function addToLibrary() {
  if (!authStore.isAuthenticated) {
    actionMessage.value = "You must be signed in to add games to your library.";
    actionIsError.value = true;
    return;
  }

  addingToLibrary.value = true;
  actionMessage.value = "";

  try {
    await gqlClient.request(ADD_GAME_TO_LIBRARY, { gameId: gameId.value });
    actionMessage.value = `${game.value?.name ?? "Game"} has been added to your library.`;
    actionIsError.value = false;
    refetch();
  } catch (err) {
    actionMessage.value = `Failed to add game to library: ${extractGqlError(err)}`;
    actionIsError.value = true;
  } finally {
    addingToLibrary.value = false;
  }
}

async function toggleFavorite() {
  if (!authStore.isAuthenticated) {
    actionMessage.value = "You must be signed in to favorite games.";
    actionIsError.value = true;
    return;
  }

  const currentlyFavorited = game.value?.isFavorited;
  favoriting.value = true;
  actionMessage.value = "";

  try {
    if (currentlyFavorited) {
      await gqlClient.request(UNFAVORITE_GAME, { gameId: gameId.value });
      actionMessage.value = `${game.value?.name ?? "Game"} has been unfavorited.`;
    } else {
      await gqlClient.request(FAVORITE_GAME, { gameId: gameId.value });
      actionMessage.value = `${game.value?.name ?? "Game"} has been favorited.`;
    }
    actionIsError.value = false;
    // Re-fetch to update isFavorited and favoriters list
    refetch();
  } catch (err) {
    actionMessage.value = `Failed to ${currentlyFavorited ? "unfavorite" : "favorite"} game: ${extractGqlError(err)}`;
    actionIsError.value = true;
  } finally {
    favoriting.value = false;
  }
}
</script>

<style scoped>
/* ── Dark mode custom properties ── */
.game-show {
  --game-border: hsl(0, 0%, 85%);
  --game-border-light: hsl(0, 0%, 92%);
  --game-text-muted: hsl(0, 0%, 45%);
  --game-text-label: hsl(0, 0%, 55%);
  --game-track-bg: hsl(0, 0%, 85%);
}

@media (prefers-color-scheme: dark) {
  .game-show {
    --game-border: hsl(217, 20%, 38%);
    --game-border-light: hsl(217, 20%, 34%);
    --game-text-muted: hsl(217, 10%, 65%);
    --game-text-label: hsl(217, 10%, 60%);
    --game-track-bg: hsl(217, 20%, 35%);
    --game-link-color: hsl(240, 70%, 75%);
  }

  .detail-link,
  .sidebar-tag {
    color: var(--game-link-color);
  }

  .sidebar-tag {
    border-color: var(--game-link-color);
  }

  .sidebar-tag:hover {
    background: hsla(240, 60%, 65%, 0.2);
  }

  .rating-circle-value {
    color: var(--game-link-color);
  }

  .details-heading {
    color: var(--game-link-color);
  }
}

/* ── Hero: full-width breakout ── */
.game-hero {
  width: 100vw;
  position: relative;
  left: 50%;
  right: 50%;
  margin-left: -50vw;
  margin-right: -50vw;
  margin-top: -3rem;
  background: var(--vglist-theme);
  padding: 3rem 0;
}

.game-hero-inner {
  max-width: 1152px;
  margin: 0 auto;
  padding: 0 1.5rem;
  display: flex;
  gap: 2rem;
  align-items: flex-start;
}

/* Cover image */
.game-hero-cover img {
  width: 240px;
  border-radius: 12px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
  display: block;
}

.game-cover-placeholder {
  width: 240px;
  height: 320px;
  border-radius: 12px;
  background: linear-gradient(135deg, #e879a0 0%, #c266d6 50%, #7c5ce7 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
  user-select: none;
}

.game-cover-placeholder span {
  font-size: 3rem;
  font-weight: 700;
  color: #fff;
  letter-spacing: 0.05em;
}

/* Hero info */
.game-hero-info {
  flex: 1;
  padding-top: 0.75rem;
}

.game-title {
  font-size: 2.5rem;
  font-weight: 700;
  color: #fff;
  line-height: 1.15;
  margin-bottom: 0.25rem;
}

.game-year {
  font-size: 1.25rem;
  color: rgba(255, 255, 255, 0.65);
  margin-bottom: 1.25rem;
}

.hero-tag-group {
  margin-bottom: 1rem;
}

.hero-tag-label {
  font-size: 0.7rem;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.55);
  text-transform: uppercase;
  letter-spacing: 0.08em;
  margin-bottom: 0.4rem;
}

.hero-tag-list {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.hero-tag {
  display: inline-block;
  padding: 0.35rem 1rem;
  border: 1.5px solid rgba(255, 255, 255, 0.55);
  border-radius: 20px;
  color: #fff;
  font-size: 0.85rem;
  font-weight: 500;
  text-decoration: none;
  transition:
    background 0.15s,
    border-color 0.15s;
}

a.hero-tag:hover {
  background: rgba(255, 255, 255, 0.15);
  border-color: #fff;
}

.hero-tag-more {
  color: rgba(255, 255, 255, 0.65);
  border-style: dashed;
  cursor: default;
}

.game-hero-actions {
  display: flex;
  gap: 0.75rem;
}

.hero-btn {
  padding: 0.6rem 1.5rem;
  border-radius: 20px;
  border: 1.5px solid rgba(255, 255, 255, 0.7);
  background: transparent;
  color: #fff;
  font-size: 0.95rem;
  font-weight: 500;
  cursor: pointer;
  transition:
    background 0.15s,
    border-color 0.15s;
}

.hero-btn:hover {
  background: rgba(255, 255, 255, 0.15);
  border-color: #fff;
}

.hero-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.hero-btn-primary {
  background: #fff;
  color: var(--vglist-theme);
  border-color: #fff;
}

.hero-btn-primary:hover {
  background: rgba(255, 255, 255, 0.9);
}

.hero-btn-active {
  background: rgba(255, 255, 255, 0.2);
  border-color: rgba(255, 255, 255, 0.8);
}

/* ── Body content ── */
.game-body {
  margin-top: 2rem;
}

/* ── Rating section ── */
.game-rating {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  margin-bottom: 2.5rem;
}

.rating-circle-wrapper {
  position: relative;
  width: 80px;
  height: 80px;
  flex-shrink: 0;
}

.rating-circle-svg {
  width: 100%;
  height: 100%;
}

.rating-circle-value {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--vglist-theme);
}

.rating-bar-area {
  flex: 1;
}

.rating-circle-bg {
  stroke: var(--game-track-bg);
}

.rating-bar-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.5rem;
  font-size: 0.9rem;
  color: var(--game-text-muted);
}

.rating-bar-track {
  height: 10px;
  background: var(--game-track-bg);
  border-radius: 5px;
  overflow: hidden;
}

.rating-bar-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--vglist-theme), hsl(240, 50%, 65%));
  border-radius: 5px;
  transition: width 0.4s ease;
}

/* ── Details ── */
.details-heading {
  font-size: 0.8rem;
  font-weight: 600;
  letter-spacing: 0.1em;
  color: var(--vglist-theme);
  margin-bottom: 1rem;
}

.details-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.detail-card {
  border: 1px solid var(--game-border);
  border-radius: 8px;
  padding: 1rem 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}

.detail-label {
  font-size: 0.7rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  color: var(--game-text-label);
  text-transform: uppercase;
}

.detail-value {
  font-size: 1rem;
  font-weight: 500;
  line-height: 1.4;
}

.detail-link {
  color: var(--vglist-theme);
  text-decoration: none;
}

.detail-link:hover {
  text-decoration: underline;
}

/* ── Sidebar ── */
.sidebar-card {
  border: 1px solid var(--game-border);
  border-radius: 8px;
  padding: 1.25rem;
  margin-bottom: 1rem;
}

.sidebar-card-title {
  font-size: 1.1rem;
  font-weight: 600;
  margin-bottom: 0.75rem;
}

.sidebar-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.sidebar-tag {
  display: inline-block;
  padding: 0.35rem 0.85rem;
  border: 1.5px solid var(--vglist-theme);
  border-radius: 20px;
  color: var(--vglist-theme);
  font-size: 0.85rem;
  font-weight: 500;
  text-decoration: none;
  transition: background 0.15s;
}

.sidebar-tag:hover {
  background: hsla(240, 60%, 65%, 0.1);
}

/* Community card (owners/favoriters) */
.community-section {
  padding: 0.25rem 0;
}

.community-header {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 0.6rem;
}

.community-title {
  font-size: 1rem;
  font-weight: 600;
}

.community-count {
  font-size: 0.85rem;
  color: rgba(0, 0, 0, 0.45);
}

.community-divider {
  border: none;
  border-top: 1px solid var(--game-border-light);
  margin: 0.75rem 0;
}

.community-empty {
  font-size: 0.85rem;
  color: rgba(0, 0, 0, 0.4);
}

.avatar-stack {
  display: flex;
  align-items: center;
}

.avatar-circle {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: 2px solid #fff;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  text-decoration: none;
  transition: transform 0.15s;
}

.avatar-circle:not(:first-child) {
  margin-left: -10px;
}

.avatar-circle:hover {
  transform: scale(1.15);
  z-index: 1;
}

.avatar-circle img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar-initials {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.75rem;
  font-weight: 700;
  color: #fff;
}

.avatar-overflow {
  margin-left: 0.5rem;
  font-size: 0.85rem;
  color: rgba(0, 0, 0, 0.45);
  font-weight: 500;
}

/* External links */
.external-links-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.external-links-list li {
  padding: 0.6rem 0;
  border-bottom: 1px solid var(--game-border-light);
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.external-links-list li:last-child {
  border-bottom: none;
  padding-bottom: 0;
}

.external-links-list li::before {
  content: "\25CF";
  color: var(--vglist-theme);
  font-size: 0.6rem;
  flex-shrink: 0;
}

.external-links-list a {
  color: inherit;
  text-decoration: none;
  font-size: 0.95rem;
}

.external-links-list a:hover {
  text-decoration: underline;
}

/* Notification */
.game-notification {
  margin-top: 1.5rem;
}

/* ── Responsive ── */
@media (max-width: 768px) {
  .game-hero-inner {
    flex-direction: column;
    align-items: center;
    text-align: center;
  }

  .game-hero-cover img,
  .game-cover-placeholder {
    width: 180px;
  }

  .game-cover-placeholder {
    height: 240px;
  }

  .game-title {
    font-size: 1.75rem;
  }

  .hero-tag-list {
    justify-content: center;
  }

  .game-hero-actions {
    justify-content: center;
  }

  .details-grid {
    grid-template-columns: 1fr;
  }
}
</style>
