<template>
  <div>
    <div v-if="loading && !data" class="has-text-centered py-6">
      <p>Loading game...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load game: {{ error.message }}</p>
    </div>

    <div v-if="game" class="game-show">
      <!-- Hero section with dynamic gradient background derived from cover art -->
      <section class="game-hero" :style="heroStyle">
        <div class="game-hero-inner">
          <div class="game-hero-cover">
            <img v-if="game.coverUrl" :src="game.coverUrl" :alt="game.name" />
            <div v-else class="game-cover-placeholder">
              <span>{{ gameInitials }}</span>
            </div>

            <div v-if="authStore.isAuthenticated" class="hero-cover-actions">
              <button
                v-if="!game.isInLibrary"
                class="hero-btn hero-cover-btn"
                :disabled="addingToLibrary"
                @click="toggleAddForm"
              >
                {{ showAddForm ? "Adding\u2026" : "+ Add to library" }}
              </button>
              <button
                v-else
                class="hero-btn hero-cover-btn hero-btn-active"
                @click="toggleEditForm"
                @mouseenter="inLibraryHovered = true"
                @mouseleave="inLibraryHovered = false"
              >
                {{ showAddForm ? "Editing\u2026" : inLibraryHovered ? "Edit\u2026" : "In library" }}
              </button>
              <button
                class="hero-btn hero-fav-btn"
                :class="{ 'hero-fav-active': game.isFavorited }"
                :disabled="favoriting"
                :aria-label="game.isFavorited ? 'Unfavorite' : 'Favorite'"
                @click="toggleFavorite"
              >
                <span class="hero-fav-wrap">
                  <Heart
                    :size="18"
                    :stroke-width="1.8"
                    :fill="game.isFavorited ? 'currentColor' : 'none'"
                    :class="{ 'hero-fav-pop': game.isFavorited }"
                  />
                  <span v-if="game.isFavorited" class="hero-sparkles" :key="sparkleKey">
                    <span v-for="(style, i) in sparkleStyles" :key="i" class="hero-sparkle" :style="style" />
                  </span>
                </span>
              </button>
            </div>
          </div>

          <div ref="heroInfoRef" class="game-hero-info">
            <h1 class="game-title">{{ game.name }}</h1>
            <p class="game-year">{{ releaseYear ?? "\u2014" }}</p>

            <Transition
              name="hero-swap"
              mode="out-in"
              @before-leave="onHeroBeforeLeave"
              @enter="onHeroEnter"
              @after-enter="onHeroAfterEnter"
            >
              <!-- Show tags when form is closed -->
              <div v-if="!showAddForm" key="tags">
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
              </div>

              <!-- Inline form replaces tags when open -->
              <div v-else key="form">
                <GameLibraryForm
                  ref="libraryFormRef"
                  :game-id="gameId"
                  :game-name="game.name"
                  :game-purchase-id="game.gamePurchaseId ?? null"
                  :game-platforms="game.platforms.nodes"
                  :all-stores="allStores"
                  :stores-loading="storesLoading"
                  :removing-from-library="removingFromLibrary"
                  @cancel="cancelAddForm"
                  @saved="onFormSaved"
                  @request-remove="showRemoveConfirm = true"
                  @error="onFormError"
                />
              </div>
            </Transition>
          </div>
        </div>
      </section>

      <!-- Content below hero -->
      <div class="game-body" :class="{ dimmed: showAddForm }">
        <div class="columns is-variable is-6">
          <GameDetailsSection :game="game" />
          <GameSidebar
            :genres="game.genres.nodes"
            :owners="game.owners"
            :favoriters="game.favoriters"
            :external-links="externalLinks"
          />
        </div>
      </div>

      <!-- Action notification -->
      <div v-if="actionMessage" class="notification game-notification" :class="actionMessageClass">
        <button class="delete" @click="actionMessage = ''"></button>
        {{ actionMessage }}
      </div>

      <!-- Mod/admin actions -->
      <div v-if="authStore.isModerator" class="game-admin-actions mt-5">
        <div class="dropdown is-hoverable">
          <div class="dropdown-trigger">
            <button class="button" aria-haspopup="true" aria-controls="game-admin-menu">
              <span>Admin Actions</span>
              <span class="icon is-small">
                <ChevronDown :size="15" />
              </span>
            </button>
          </div>
          <div id="game-admin-menu" class="dropdown-menu" role="menu">
            <div class="dropdown-content">
              <router-link class="dropdown-item" :to="`/games/${game.id}/edit`">Edit</router-link>
              <a v-if="game.coverUrl" class="dropdown-item has-text-danger" @click="showRemoveCoverConfirm = true">
                Remove cover
              </a>
              <a
                v-if="game.wikidataId"
                class="dropdown-item has-text-danger"
                @click="showWikidataBlocklistConfirm = true"
              >
                Add to Wikidata Blocklist
              </a>
              <a class="dropdown-item has-text-danger" @click="showDeleteGameConfirm = true">Delete game</a>
            </div>
          </div>
        </div>
      </div>

      <!-- Remove from library confirmation modal -->
      <ConfirmDialog
        v-model="showRemoveConfirm"
        title="Remove game?"
        :loading="removingFromLibrary"
        @confirm="confirmRemoveFromLibrary"
      >
        <template #icon>
          <CircleAlert :size="22" :stroke-width="1.8" />
        </template>
        <strong>{{ game.name }}</strong> will be removed from your library. Your rating, status, and notes will be
        deleted.
      </ConfirmDialog>

      <!-- Remove cover confirmation -->
      <ConfirmDialog
        v-model="showRemoveCoverConfirm"
        title="Remove cover?"
        confirm-label="Remove cover"
        loading-label="Removing…"
        :loading="removingCover"
        @confirm="confirmRemoveCover"
      >
        <template #icon>
          <CircleAlert :size="22" :stroke-width="1.8" />
        </template>
        The cover image for <strong>{{ game.name }}</strong> will be removed.
      </ConfirmDialog>

      <!-- Wikidata blocklist confirmation -->
      <ConfirmDialog
        v-model="showWikidataBlocklistConfirm"
        title="Add to Wikidata Blocklist?"
        confirm-label="Add to blocklist"
        loading-label="Adding…"
        :loading="addingToBlocklist"
        @confirm="confirmAddToWikidataBlocklist"
      >
        <template #icon>
          <CircleAlert :size="22" :stroke-width="1.8" />
        </template>
        <strong>{{ game.name }}</strong> (Wikidata ID: Q{{ game.wikidataId }}) will be added to the blocklist and the
        Wikidata ID will be removed from the game.
      </ConfirmDialog>

      <!-- Delete game confirmation -->
      <ConfirmDialog
        v-model="showDeleteGameConfirm"
        title="Delete game?"
        confirm-label="Delete game"
        loading-label="Deleting…"
        :loading="deletingGame"
        @confirm="confirmDeleteGame"
      >
        <template #icon>
          <CircleAlert :size="22" :stroke-width="1.8" />
        </template>
        <strong>{{ game.name }}</strong> will be permanently deleted, including all library entries and favorites. This
        cannot be undone.
      </ConfirmDialog>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useQuery } from "@/composables/useGraphQL";
import { useAuthStore } from "@/stores/auth";
import { useImageColors } from "@/composables/useImageColors";
import { gqlClient } from "@/graphql/client";
import { GET_GAME } from "@/graphql/queries/games";
import { GET_STORES } from "@/graphql/queries/resources";
import {
  REMOVE_GAME_FROM_LIBRARY,
  FAVORITE_GAME,
  UNFAVORITE_GAME,
  DELETE_GAME,
  REMOVE_GAME_COVER
} from "@/graphql/mutations/games";
import { ADD_TO_WIKIDATA_BLOCKLIST } from "@/graphql/mutations/admin";
import type { GetGameQuery, GetStoresQuery } from "@/types/graphql";
import { Heart, CircleAlert, ChevronDown } from "lucide-vue-next";
import { extractGqlError } from "@/utils/graphql-errors";
import { useSnackbar } from "@/composables/useSnackbar";
import ConfirmDialog from "@/components/ConfirmDialog.vue";
// eslint-disable-next-line typescript/consistent-type-imports -- used in template, not just as a type
import GameLibraryForm from "@/components/game/GameLibraryForm.vue";
import GameDetailsSection from "@/components/game/GameDetailsSection.vue";
import GameSidebar from "@/components/game/GameSidebar.vue";

const route = useRoute("game");
const router = useRouter();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const gameId = computed(() => route.params.id);

const { data, loading, error, refetch } = useQuery<GetGameQuery>(GET_GAME, {
  variables: () => ({ id: gameId.value })
});

const game = computed(() => data.value?.game ?? null);

// Redirect to 404 when the game is not found or the query fails.
watch([data, error, loading], () => {
  if (!loading.value && (error.value || (data.value && !game.value))) {
    router.replace({ name: "notFound" });
  }
});

// Extract dominant colors from the cover image for the hero background gradient.
const coverUrl = computed(() => game.value?.coverUrl ?? null);
const { gradient: heroGradient } = useImageColors(coverUrl);
const heroStyle = computed(() => (heroGradient.value ? { background: heroGradient.value } : undefined));

// Fetch all stores for the form
const { data: storesData, loading: storesLoading } = useQuery<GetStoresQuery>(GET_STORES, {
  variables: { first: 100 }
});
const allStores = computed(() => storesData.value?.stores?.nodes ?? []);

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
const hiddenGenreCount = computed(() => Math.max(0, (game.value?.genres.nodes.length ?? 0) - HERO_TAG_LIMIT));

const visiblePlatforms = computed(() => game.value?.platforms.nodes.slice(0, HERO_TAG_LIMIT) ?? []);
const hiddenPlatformCount = computed(() => Math.max(0, (game.value?.platforms.nodes.length ?? 0) - HERO_TAG_LIMIT));

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
    links.push({ label: "MobyGames", url: `https://www.mobygames.com/game/${g.mobygamesId}` });
  }
  if (g.giantbombId) {
    links.push({ label: "GiantBomb", url: `https://www.giantbomb.com/game/${g.giantbombId}/` });
  }
  if (g.igdbId) {
    links.push({ label: "IGDB", url: `https://www.igdb.com/games/${g.igdbId}` });
  }
  if (g.steamAppIds && g.steamAppIds.length > 0) {
    links.push({ label: "Steam", url: `https://store.steampowered.com/app/${g.steamAppIds[0]}` });
  }
  if (g.pcgamingwikiId) {
    links.push({ label: "PCGamingWiki", url: `https://www.pcgamingwiki.com/wiki/${g.pcgamingwikiId}` });
  }
  if (g.epicGamesStoreId) {
    links.push({ label: "Epic Games Store", url: `https://store.epicgames.com/p/${g.epicGamesStoreId}` });
  }
  if (g.gogId) {
    links.push({ label: "GOG", url: `https://www.gog.com/game/${g.gogId}` });
  }

  return links;
});

// ── Form visibility ──
const showAddForm = ref(false);
const addingToLibrary = ref(false);
const inLibraryHovered = ref(false);
const showRemoveConfirm = ref(false);
const libraryFormRef = ref<InstanceType<typeof GameLibraryForm> | null>(null);

// ── Hero height animation (smooth expand/collapse) ──
const heroInfoRef = ref<HTMLElement | null>(null);
let savedInfoHeight = 0;

function onHeroBeforeLeave() {
  const el = heroInfoRef.value;
  if (el) {
    savedInfoHeight = el.getBoundingClientRect().height;
    el.style.height = `${savedInfoHeight}px`;
    el.style.overflow = "hidden";
  }
}

function onHeroEnter() {
  const el = heroInfoRef.value;
  if (!el) return;

  nextTick(() => {
    el.style.height = "auto";
    const newHeight = el.getBoundingClientRect().height;
    el.style.height = `${savedInfoHeight}px`;
    void el.offsetHeight; // force reflow
    el.style.transition = "height 0.35s ease";
    el.style.height = `${newHeight}px`;
  });
}

function onHeroAfterEnter() {
  const el = heroInfoRef.value;
  if (el) {
    el.style.height = "";
    el.style.overflow = "";
    el.style.transition = "";
  }
}

function toggleAddForm() {
  showAddForm.value = !showAddForm.value;
}

function toggleEditForm() {
  showAddForm.value = !showAddForm.value;
}

function cancelAddForm() {
  showAddForm.value = false;
}

function onFormSaved(message: string) {
  showAddForm.value = false;
  showSnackbar(message);
  refetch();
}

function onFormError(message: string) {
  actionMessage.value = message;
  actionIsError.value = true;
}

// ── Remove from library ──
const removingFromLibrary = ref(false);

async function confirmRemoveFromLibrary() {
  const purchaseId = game.value?.gamePurchaseId;
  if (!purchaseId) return;

  removingFromLibrary.value = true;
  actionMessage.value = "";

  try {
    await gqlClient.request(REMOVE_GAME_FROM_LIBRARY, { gamePurchaseId: purchaseId });
    showSnackbar(`${game.value?.name ?? "Game"} has been removed from your library.`);
    actionMessage.value = "";
    actionIsError.value = false;
    showAddForm.value = false;
    showRemoveConfirm.value = false;
    localStorage.removeItem(`vglist-review-draft-${gameId.value}`);
    refetch();
  } catch (err) {
    actionMessage.value = `Failed to remove game from library: ${extractGqlError(err)}`;
    actionIsError.value = true;
    showRemoveConfirm.value = false;
  } finally {
    removingFromLibrary.value = false;
  }
}

// ── Favorite ──
const favoriting = ref(false);
const sparkleKey = ref(0);

function generateSparkleStyles(): Record<string, string>[] {
  return Array.from({ length: 6 }, (_, i) => {
    const angle = i * 60;
    const rad = (angle * Math.PI) / 180;
    const dist = 16 + Math.random() * 6;
    const x = Math.cos(rad) * dist;
    const y = Math.sin(rad) * dist;
    const size = 3 + Math.random() * 2;
    const delay = Math.random() * 0.1;
    return {
      "--sx": `${x}px`,
      "--sy": `${y}px`,
      width: `${size}px`,
      height: `${size}px`,
      animationDelay: `${delay}s`
    };
  });
}

const sparkleStyles = computed(() => {
  // Re-generate styles whenever sparkleKey changes (i.e. on each favorite action).
  void sparkleKey.value;
  return generateSparkleStyles();
});

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
      showSnackbar(`${game.value?.name ?? "Game"} has been unfavorited.`);
    } else {
      await gqlClient.request(FAVORITE_GAME, { gameId: gameId.value });
      sparkleKey.value++;
      showSnackbar(`${game.value?.name ?? "Game"} has been favorited.`);
    }
    actionMessage.value = "";
    actionIsError.value = false;
    refetch();
  } catch (err) {
    actionMessage.value = `Failed to ${currentlyFavorited ? "unfavorite" : "favorite"} game: ${extractGqlError(err)}`;
    actionIsError.value = true;
  } finally {
    favoriting.value = false;
  }
}

// ── Action notifications ──
const actionMessage = ref("");
const actionIsError = ref(false);
const actionMessageClass = computed(() => (actionIsError.value ? "is-danger" : "is-success"));

// ── Admin actions ──
const showRemoveCoverConfirm = ref(false);
const removingCover = ref(false);
const showWikidataBlocklistConfirm = ref(false);
const addingToBlocklist = ref(false);
const showDeleteGameConfirm = ref(false);
const deletingGame = ref(false);

async function confirmRemoveCover() {
  removingCover.value = true;
  try {
    await gqlClient.request(REMOVE_GAME_COVER, { gameId: gameId.value });
    showSnackbar("Cover removed.");
    showRemoveCoverConfirm.value = false;
    refetch();
  } catch (err) {
    showSnackbar(`Failed to remove cover: ${extractGqlError(err)}`, "error");
  } finally {
    removingCover.value = false;
  }
}

async function confirmAddToWikidataBlocklist() {
  if (!game.value?.wikidataId) return;
  addingToBlocklist.value = true;
  try {
    await gqlClient.request(ADD_TO_WIKIDATA_BLOCKLIST, {
      name: game.value.name,
      wikidataId: game.value.wikidataId
    });
    showSnackbar(`${game.value.name} added to Wikidata blocklist.`);
    showWikidataBlocklistConfirm.value = false;
    refetch();
  } catch (err) {
    showSnackbar(`Failed to add to blocklist: ${extractGqlError(err)}`, "error");
  } finally {
    addingToBlocklist.value = false;
  }
}

async function confirmDeleteGame() {
  deletingGame.value = true;
  try {
    await gqlClient.request(DELETE_GAME, { gameId: gameId.value });
    showSnackbar(`${game.value?.name ?? "Game"} has been deleted.`);
    showDeleteGameConfirm.value = false;
    router.replace({ name: "games" });
  } catch (err) {
    showSnackbar(`Failed to delete game: ${extractGqlError(err)}`, "error");
    deletingGame.value = false;
  }
}
</script>

<style scoped>
/* ── Page-level custom properties (reference global tokens) ── */
.game-show {
  --game-border: var(--color-border);
  --game-border-light: var(--color-bg-subtle);
  --game-text-muted: var(--color-text-secondary);
  --game-text-label: var(--color-text-tertiary);
  --game-track-bg: var(--color-border);
}

@media (prefers-color-scheme: dark) {
  .game-show {
    --game-border: var(--s-300);
    --game-border-light: var(--s-300);
    --game-text-muted: var(--s-200);
    --game-text-label: var(--s-200);
    --game-track-bg: var(--s-300);
    --game-link-color: var(--p-300);
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
  background: #4b46af;
  padding: 3rem 0;
  transition: background 0.6s ease;
}

@media (prefers-color-scheme: dark) {
  .game-hero {
    background: #3a3690;
  }
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
.game-hero-cover {
  flex-shrink: 0;
}

.game-hero-cover img {
  width: 240px;
  border-radius: var(--radius-lg);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
  display: block;
}

.game-cover-placeholder {
  width: 240px;
  height: 320px;
  border-radius: var(--radius-lg);
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

/* Buttons below cover */
.hero-cover-actions {
  display: flex;
  gap: 0.5rem;
  margin-top: 0.75rem;
}

.hero-cover-btn {
  flex: 1;
  font-size: 0.85rem;
  padding: 0.5rem 0;
  text-align: center;
}

.hero-fav-btn {
  flex: 0 0 auto;
  padding: 0.6rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.hero-fav-active {
  color: #ff4d6a;
  border-color: rgba(255, 75, 106, 0.5);
  background: rgba(255, 75, 106, 0.15);
}

.hero-fav-active:hover {
  color: #ff6b83;
  border-color: rgba(255, 107, 131, 0.6);
  background: rgba(255, 75, 106, 0.25);
}

.hero-fav-wrap {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
}

.hero-fav-pop {
  animation: fav-pop 0.35s ease;
}

@keyframes fav-pop {
  0% {
    transform: scale(1);
  }
  40% {
    transform: scale(1.35);
  }
  100% {
    transform: scale(1);
  }
}

.hero-sparkles {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.hero-sparkle {
  position: absolute;
  top: 50%;
  left: 50%;
  border-radius: 50%;
  background: #ff4d6a;
  opacity: 0;
  animation: sparkle-burst 0.5s ease-out forwards;
}

@keyframes sparkle-burst {
  0% {
    transform: translate(-50%, -50%) translate(0, 0) scale(1);
    opacity: 1;
  }
  60% {
    opacity: 1;
  }
  100% {
    transform: translate(-50%, -50%) translate(var(--sx), var(--sy)) scale(0);
    opacity: 0;
  }
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
  border-radius: var(--radius-pill);
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

.hero-btn {
  padding: 0.6rem 1.5rem;
  border-radius: var(--radius-pill);
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

.hero-btn-active {
  background: rgba(255, 255, 255, 0.2);
  border-color: rgba(255, 255, 255, 0.8);
}

/* GitHub-style overrides for the cover action buttons */
.hero-btn.hero-cover-btn {
  border-radius: 6px;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.18) 0%, rgba(255, 255, 255, 0.04) 100%);
  border: 1px solid rgba(255, 255, 255, 0.4);
  box-shadow:
    0 1px 0 rgba(0, 0, 0, 0.12),
    inset 0 1px 0 rgba(255, 255, 255, 0.15);
  text-shadow: 0 1px 0 rgba(0, 0, 0, 0.1);
}

.hero-btn.hero-cover-btn:hover {
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.25) 0%, rgba(255, 255, 255, 0.1) 100%);
  border-color: rgba(255, 255, 255, 0.6);
  box-shadow:
    0 1px 3px rgba(0, 0, 0, 0.15),
    inset 0 1px 0 rgba(255, 255, 255, 0.2);
}

.hero-btn.hero-cover-btn:active {
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.04) 0%, rgba(255, 255, 255, 0.12) 100%);
  box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.15);
}

.hero-btn.hero-fav-btn {
  border-radius: 6px;
}

/* ── Hero swap transition ── */
.hero-swap-enter-active {
  transition:
    opacity 0.3s ease,
    transform 0.3s ease;
}

.hero-swap-leave-active {
  transition:
    opacity 0.15s ease,
    transform 0.15s ease;
}

.hero-swap-enter-from {
  opacity: 0;
  transform: translateY(16px);
}

.hero-swap-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

/* Dimmed body when form is open */
.game-body.dimmed {
  opacity: 0.3;
  pointer-events: none;
  transition: opacity 0.3s;
}

.game-body {
  margin-top: 2rem;
  transition: opacity 0.3s;
}

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
}
</style>
