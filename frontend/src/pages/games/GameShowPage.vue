<template>
  <div>
    <!-- Skeleton in the shape of the page while the game loads -->
    <div v-if="showSkeleton" class="game-show game-skeleton" aria-busy="true">
      <p class="is-sr-only" role="status">Loading game…</p>
      <section class="game-hero" aria-hidden="true">
        <div class="game-hero-inner">
          <div class="game-hero-cover">
            <div class="skel skel-cover"></div>
            <div v-if="authStore.isAuthenticated" class="hero-actions">
              <div class="skel skel-btn skel-btn-primary"></div>
              <div class="skel skel-btn"></div>
            </div>
          </div>

          <div class="hero-split">
            <div class="game-hero-info">
              <div class="skel skel-title"></div>
              <div class="skel skel-meta"></div>
              <div v-for="group in 2" :key="group" class="hero-tag-group">
                <div class="skel skel-tag-label"></div>
                <div class="hero-tags">
                  <div v-for="tag in 3" :key="tag" class="skel skel-tag" :style="{ width: `${56 + tag * 14}px` }"></div>
                </div>
              </div>
            </div>

            <div class="skel-panel">
              <div class="skel-panel-rating">
                <div class="skel skel-ring"></div>
                <div class="skel-panel-rating-text">
                  <div class="skel skel-line" style="width: 70%"></div>
                  <div class="skel skel-line skel-line-sm" style="width: 45%"></div>
                </div>
              </div>
              <div class="skel-panel-rule"></div>
              <div v-for="row in 2" :key="row" class="skel-panel-row">
                <div class="skel skel-tag-label"></div>
                <div class="skel-avatars">
                  <div v-for="avatar in 5" :key="avatar" class="skel skel-avatar"></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <div class="game-body" aria-hidden="true">
        <div class="game-body-main">
          <div class="game-card">
            <div class="skel skel-card-title"></div>
            <div v-for="review in 3" :key="review" class="skel-review">
              <div class="skel skel-review-avatar"></div>
              <div>
                <div class="skel skel-line" style="width: 40%"></div>
                <div class="skel skel-line" style="width: 95%"></div>
                <div class="skel skel-line" style="width: 70%"></div>
              </div>
            </div>
          </div>
        </div>
        <aside class="game-body-side">
          <div class="game-card skel-details">
            <div class="skel skel-tag-label"></div>
            <div class="skel-details-list">
              <template v-for="row in 6" :key="row">
                <div class="skel skel-line" style="width: 72px"></div>
                <div class="skel skel-line" :style="{ width: `${50 + ((row * 17) % 40)}%` }"></div>
              </template>
            </div>
          </div>
        </aside>
      </div>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load game: {{ error.message }}</p>
    </div>

    <div v-if="game && !showSkeleton" class="game-show">
      <!-- Hero section with dynamic gradient background derived from cover art -->
      <section class="game-hero" :style="heroStyle">
        <div class="game-hero-inner">
          <div class="game-hero-cover">
            <!-- Covers keep their own shape (square, 16:9, …) in a fixed-width column. -->
            <img v-if="game.coverUrl" :src="game.coverUrl" :alt="`Cover for ${game.name}`" />
            <div v-else class="game-cover-placeholder" aria-hidden="true">
              <span>{{ gameInitials }}</span>
            </div>

            <div v-if="authStore.isAuthenticated" class="hero-actions">
              <button
                ref="libraryButtonRef"
                class="hero-btn primary"
                :aria-haspopup="isPhone ? 'dialog' : undefined"
                :disabled="addingToLibrary"
                :aria-expanded="showAddForm"
                @click="toggleLibraryForm"
                @mouseenter="inLibraryHovered = true"
                @mouseleave="inLibraryHovered = false"
              >
                <Check v-if="game.isInLibrary" :size="18" aria-hidden="true" />
                <Plus v-else :size="18" aria-hidden="true" />
                {{ libraryButtonLabel }}
              </button>
              <button
                class="hero-btn icon"
                :class="{ on: game.isFavorited }"
                :disabled="favoriting"
                :aria-label="game.isFavorited ? 'Unfavorite' : 'Favorite'"
                :aria-pressed="Boolean(game.isFavorited)"
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

              <!-- Mod/admin actions -->
              <div
                v-if="authStore.isModerator"
                ref="adminMenuRef"
                class="hero-admin"
                @keydown.esc="closeAdminMenu(true)"
              >
                <button
                  ref="adminButtonRef"
                  class="hero-btn icon"
                  aria-label="Admin actions"
                  aria-haspopup="menu"
                  aria-controls="game-admin-menu"
                  :aria-expanded="adminMenuOpen"
                  :disabled="showAddForm"
                  @click="toggleAdminMenu"
                >
                  <Ellipsis :size="18" aria-hidden="true" />
                </button>
                <div v-if="adminMenuOpen" id="game-admin-menu" class="hero-admin-menu" role="menu">
                  <router-link class="hero-admin-item" role="menuitem" :to="`/games/${game.id}/edit`">Edit</router-link>
                  <button
                    v-if="game.coverUrl"
                    class="hero-admin-item danger"
                    role="menuitem"
                    @click="openAdminDialog('removeCover')"
                  >
                    Remove cover
                  </button>
                  <button
                    v-if="game.wikidataId"
                    class="hero-admin-item danger"
                    role="menuitem"
                    @click="openAdminDialog('wikidataBlocklist')"
                  >
                    Add to Wikidata Blocklist
                  </button>
                  <button
                    v-if="authStore.isAdmin"
                    class="hero-admin-item danger"
                    role="menuitem"
                    @click="openAdminDialog('mergeGame')"
                  >
                    Merge into another game…
                  </button>
                  <button class="hero-admin-item danger" role="menuitem" @click="openAdminDialog('deleteGame')">
                    Delete game
                  </button>
                </div>
              </div>
            </div>
          </div>

          <div class="hero-split" :class="{ 'form-open': showAddForm && !isPhone }">
            <div ref="heroInfoRef" class="game-hero-info">
              <h1 class="game-title" :class="{ 'is-long': game.name.length > LONG_TITLE_LENGTH }">{{ game.name }}</h1>
              <p v-if="releaseYear || game.developers.nodes.length || game.series" class="hero-meta">
                <span v-if="releaseYear">{{ releaseYear }}</span>
                <template v-if="game.developers.nodes.length">
                  <span v-if="releaseYear" class="dot" aria-hidden="true"></span>
                  <span>by <LinkedNames :items="game.developers.nodes.slice(0, 2)" base="/companies" /></span>
                </template>
                <template v-if="game.series">
                  <span v-if="releaseYear || game.developers.nodes.length" class="dot" aria-hidden="true"></span>
                  <span
                    ><router-link :to="`/series/${game.series.id}`">{{ game.series.name }}</router-link> series</span
                  >
                </template>
              </p>

              <Transition
                name="hero-swap"
                mode="out-in"
                @before-leave="onHeroBeforeLeave"
                @enter="onHeroEnter"
                @after-enter="onHeroAfterEnter"
              >
                <!-- Show tags when form is closed -->
                <div v-if="!showAddForm || isPhone" key="tags">
                  <div v-if="game.genres.nodes.length > 0" class="hero-tag-group">
                    <h2 class="hero-tag-label">Genres</h2>
                    <div class="hero-tags">
                      <router-link
                        v-for="genre in visibleGenres"
                        :key="'g-' + genre.id"
                        :to="`/genres/${genre.id}`"
                        class="hero-tag"
                      >
                        {{ genre.name }}
                      </router-link>
                      <a
                        v-if="hiddenGenreCount > 0"
                        class="hero-tag-more"
                        href="#game-details"
                        @click="scrollToDetails"
                      >
                        +{{ hiddenGenreCount }} more
                      </a>
                    </div>
                  </div>

                  <div v-if="game.platforms.nodes.length > 0" class="hero-tag-group">
                    <h2 class="hero-tag-label">Platforms</h2>
                    <div class="hero-tags">
                      <router-link
                        v-for="platform in visiblePlatforms"
                        :key="'p-' + platform.id"
                        :to="`/platforms/${platform.id}`"
                        class="hero-tag"
                      >
                        {{ platform.name }}
                      </router-link>
                      <a
                        v-if="hiddenPlatformCount > 0"
                        class="hero-tag-more"
                        href="#game-details"
                        @click="scrollToDetails"
                      >
                        +{{ hiddenPlatformCount }} more
                      </a>
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

            <GameHeroPanel
              v-if="!showAddForm || isPhone"
              :avg-rating="game.avgRating ?? null"
              :rating-count="game.ratingCount"
              :entry="myEntry"
              :owners="game.owners"
              :favoriters="game.favoriters"
              :external-links="externalLinks"
              @edit-entry="toggleLibraryForm"
            />
          </div>
        </div>
      </section>

      <!-- Content below hero -->
      <div class="game-body" :class="{ dimmed: showAddForm && !isPhone }">
        <div class="game-body-main">
          <GameReviewsCard
            :reviews="reviews"
            :total-count="reviewsTotal"
            :sort="reviewSort"
            :loading="reviewsLoading"
            @update:sort="changeReviewSort"
            @load-more="reviewLimit += REVIEW_PAGE_SIZE"
          />
          <GameActivityCard v-if="activity.length" :events="activity" />
        </div>
        <aside class="game-body-side">
          <GameDetailsCard id="game-details" :game="game" />
          <GameSeriesShelf v-if="game.series" :series="game.series" :games="game.moreFromSeries.nodes" />
        </aside>
      </div>

      <!-- Action notification -->
      <div v-if="actionMessage" class="notification game-notification" :class="actionMessageClass">
        <button class="delete" @click="actionMessage = ''"></button>
        {{ actionMessage }}
      </div>

      <!-- On phones the library form opens in a bottom sheet instead of the hero -->
      <GameLibrarySheet
        v-if="showAddForm && isPhone"
        :title="game.isInLibrary ? 'Edit library entry' : 'Add to library'"
        :game-name="game.name"
        :cover-url="game.coverUrl ?? null"
        @close="cancelAddForm"
      >
        <GameLibraryForm
          variant="sheet"
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
      </GameLibrarySheet>

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

      <!-- Merge game (admins only) -->
      <MergeGameDialog
        v-if="authStore.isAdmin"
        v-model="showMergeGameDialog"
        :game="{ id: game.id, name: game.name, coverUrl: game.coverUrl ?? null }"
        @merged="onGameMerged"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { notFoundLocation } from "@/utils/not-found";
import { useQuery } from "@/composables/useGraphQL";
import { useAuthStore } from "@/stores/auth";
import { useImageColors } from "@/composables/useImageColors";
import { usePageTitle } from "@/composables/usePageTitle";
import { gqlClient } from "@/graphql/client";
import { GET_GAME, GET_GAME_ACTIVITY, GET_GAME_PURCHASE, GET_GAME_REVIEWS } from "@/graphql/queries/games";
import { GET_STORES } from "@/graphql/queries/resources";
import {
  REMOVE_GAME_FROM_LIBRARY,
  FAVORITE_GAME,
  UNFAVORITE_GAME,
  DELETE_GAME,
  REMOVE_GAME_COVER
} from "@/graphql/mutations/games";
import { ADD_TO_WIKIDATA_BLOCKLIST } from "@/graphql/mutations/admin";
import type {
  GameReviewSort,
  GetGameActivityQuery,
  GetGamePurchaseQuery,
  GetGameQuery,
  GetGameReviewsQuery,
  GetStoresQuery
} from "@/types/graphql";
import { Check, CircleAlert, Ellipsis, Heart, Plus } from "@lucide/vue";
import { extractGqlError } from "@/utils/graphql-errors";
import { useSnackbar } from "@/composables/useSnackbar";
import ConfirmDialog from "@/components/ConfirmDialog.vue";
import MergeGameDialog from "@/components/game/MergeGameDialog.vue";
import GameLibraryForm from "@/components/game/GameLibraryForm.vue";
import GameLibrarySheet from "@/components/game/GameLibrarySheet.vue";
import GameActivityCard from "@/components/game/GameActivityCard.vue";
import GameDetailsCard from "@/components/game/GameDetailsCard.vue";
import GameHeroPanel, { type HeroPanelEntry } from "@/components/game/GameHeroPanel.vue";
import LinkedNames from "@/components/game/LinkedNames.vue";
import GameReviewsCard from "@/components/game/GameReviewsCard.vue";
import GameSeriesShelf from "@/components/game/GameSeriesShelf.vue";
import { gameInitials as initialsFor } from "@/utils/library";
import "@/assets/stylesheets/game-page.scss";

const route = useRoute("game");
const router = useRouter();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const gameId = computed(() => route.params.id);

const { data, loading, error, refetch } = useQuery<GetGameQuery>(GET_GAME, {
  variables: () => ({ id: gameId.value })
});

const game = computed(() => data.value?.game ?? null);

// Show the skeleton on first load, and when moving to another game's page
// (vue-router reuses this component, so the previous game is still in `data`).
// Refetches of the same game keep the page in place.
// Compared as numbers: the server reads "/games/0123" or "/games/123-foo" as
// game 123, and those must not count as a different game on every refetch.
const isCurrentGame = (id: string) => Number.parseInt(id, 10) === Number.parseInt(gameId.value, 10);
const showSkeleton = computed(() => loading.value && (!game.value || !isCurrentGame(game.value.id)));

usePageTitle(() => game.value?.name);

// Redirect to 404 when the game is not found or the query fails.
watch([data, error, loading], () => {
  if (!loading.value && (error.value || (data.value && !game.value))) {
    router.replace(notFoundLocation(route));
  }
});

// Extract dominant colors from the cover image for the hero background gradient.
const coverUrl = computed(() => game.value?.coverUrl ?? null);
const { gradient: heroGradient } = useImageColors(coverUrl, { resetKey: () => game.value?.id });
const heroStyle = computed(() => (heroGradient.value ? { background: heroGradient.value } : undefined));

// Fetch all stores for the form
const { data: storesData, loading: storesLoading } = useQuery<GetStoresQuery>(GET_STORES, {
  variables: { first: 100 }
});
const allStores = computed(() => storesData.value?.stores?.nodes ?? []);

const gameInitials = computed(() => (game.value ? initialsFor(game.value.name) : ""));

const releaseYear = computed(() => {
  if (!game.value?.releaseDate) return null;
  return new Date(game.value.releaseDate).getFullYear();
});

// Titles longer than this drop a size so they don't take over the hero.
const LONG_TITLE_LENGTH = 28;

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

// The signed-in user's library entry, for the "You:" row in the hero panel.
const { data: purchaseData, refetch: refetchPurchase } = useQuery<GetGamePurchaseQuery>(GET_GAME_PURCHASE, {
  variables: () => ({ id: game.value?.gamePurchaseId ?? "" }),
  enabled: () => Boolean(game.value?.gamePurchaseId)
});

const myEntry = computed<HeroPanelEntry | null>(() => {
  if (!game.value?.gamePurchaseId) return null;
  const purchase = purchaseData.value?.gamePurchase;
  if (!purchase || purchase.id !== game.value.gamePurchaseId) {
    return { completionStatus: null, rating: null, hoursPlayed: null };
  }
  return purchase;
});

// ── Reviews and recent activity ──
const REVIEW_PAGE_SIZE = 5;
const reviewSort = ref<GameReviewSort>("RECENT");
const reviewLimit = ref(REVIEW_PAGE_SIZE);

const {
  data: reviewsData,
  loading: reviewsLoading,
  refetch: refetchReviews
} = useQuery<GetGameReviewsQuery>(GET_GAME_REVIEWS, {
  variables: () => ({ id: gameId.value, sortBy: reviewSort.value, first: reviewLimit.value })
});
const reviews = computed(() => reviewsData.value?.game?.reviews.nodes ?? []);
const reviewsTotal = computed(() => reviewsData.value?.game?.reviews.totalCount ?? 0);

function changeReviewSort(sort: GameReviewSort) {
  reviewSort.value = sort;
  reviewLimit.value = REVIEW_PAGE_SIZE;
}

// Start from the first page of reviews again on another game's page.
watch(gameId, () => {
  reviewSort.value = "RECENT";
  reviewLimit.value = REVIEW_PAGE_SIZE;
});

const { data: activityData, refetch: refetchActivity } = useQuery<GetGameActivityQuery>(GET_GAME_ACTIVITY, {
  variables: () => ({ id: gameId.value, first: 6 })
});
const activity = computed(() => activityData.value?.game?.activity.nodes ?? []);

// After the signed-in user changes their entry or favorite, their review and
// the activity it creates should show up without a reload.
function refetchCommunity() {
  void refetchReviews();
  void refetchActivity();
}

function scrollToDetails(event: MouseEvent) {
  event.preventDefault();
  document.getElementById("game-details")?.scrollIntoView({ behavior: "smooth", block: "start" });
}

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

const libraryButtonLabel = computed(() => {
  if (!game.value) return "";
  if (game.value.isInLibrary) {
    if (showAddForm.value) return "Editing\u2026";
    return inLibraryHovered.value ? "Edit\u2026" : "In library";
  }
  return showAddForm.value ? "Adding\u2026" : "Add to library";
});

function toggleLibraryForm() {
  showAddForm.value = !showAddForm.value;
}

function cancelAddForm() {
  showAddForm.value = false;
}

function onFormSaved(message: string) {
  showAddForm.value = false;
  showSnackbar(message);
  refetch();
  refetchPurchase();
  refetchCommunity();
}

function onFormError(message: string) {
  // The notification under the page body is hidden behind the phone sheet.
  if (isPhone.value) {
    showSnackbar(message, "error");
    return;
  }
  actionMessage.value = message;
  actionIsError.value = true;
}

// ── Phone layout: the form opens in a bottom sheet ──
const PHONE_QUERY = "(max-width: 768px)";
const isPhone = ref(false);
let phoneMedia: MediaQueryList | null = null;
const libraryButtonRef = ref<HTMLButtonElement | null>(null);

function updateIsPhone() {
  isPhone.value = phoneMedia?.matches ?? false;
}

onMounted(() => {
  if (typeof window.matchMedia !== "function") return;
  phoneMedia = window.matchMedia(PHONE_QUERY);
  updateIsPhone();
  phoneMedia.addEventListener("change", updateIsPhone);
});

onBeforeUnmount(() => phoneMedia?.removeEventListener("change", updateIsPhone));

// When the sheet closes, put focus back on the button that opened it.
watch(
  () => showAddForm.value && isPhone.value,
  (open, wasOpen) => {
    if (wasOpen && !open) void nextTick(() => libraryButtonRef.value?.focus());
  }
);

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
    refetchCommunity();
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
    refetchCommunity();
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
const showMergeGameDialog = ref(false);

const adminMenuOpen = ref(false);
const adminMenuRef = ref<HTMLElement | null>(null);
const adminButtonRef = ref<HTMLButtonElement | null>(null);

function onDocumentPointerDown(event: PointerEvent) {
  if (adminMenuRef.value && !adminMenuRef.value.contains(event.target as Node)) {
    closeAdminMenu(false);
  }
}

function toggleAdminMenu() {
  if (adminMenuOpen.value) {
    closeAdminMenu(false);
    return;
  }
  adminMenuOpen.value = true;
  document.addEventListener("pointerdown", onDocumentPointerDown);
  // Move focus into the menu so keyboard users land on the first action.
  nextTick(() => adminMenuRef.value?.querySelector<HTMLElement>("[role='menuitem']")?.focus());
}

function closeAdminMenu(restoreFocus: boolean) {
  if (!adminMenuOpen.value) return;
  adminMenuOpen.value = false;
  document.removeEventListener("pointerdown", onDocumentPointerDown);
  if (restoreFocus) adminButtonRef.value?.focus();
}

onBeforeUnmount(() => document.removeEventListener("pointerdown", onDocumentPointerDown));

function openAdminDialog(dialog: "removeCover" | "wikidataBlocklist" | "mergeGame" | "deleteGame") {
  closeAdminMenu(false);
  if (dialog === "removeCover") showRemoveCoverConfirm.value = true;
  else if (dialog === "wikidataBlocklist") showWikidataBlocklistConfirm.value = true;
  else if (dialog === "mergeGame") showMergeGameDialog.value = true;
  else showDeleteGameConfirm.value = true;
}

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

function onGameMerged(kept: { id: string; name: string }) {
  showSnackbar(`${game.value?.name ?? "Game"} has been merged into ${kept.name}.`);
  router.replace({ name: "game", params: { id: kept.id } });
}
</script>

<style scoped>
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
  color: #fff;
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

/* Cover image: a fixed-width column; the image keeps its own aspect ratio. */
.game-hero-cover {
  width: 240px;
  flex-shrink: 0;
}

.game-hero-cover img {
  display: block;
  width: 100%;
  height: auto;
  border-radius: var(--radius-lg);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
}

.game-cover-placeholder {
  width: 100%;
  aspect-ratio: 3 / 4;
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

/* ── Hero buttons: one row under the cover ── */
.hero-actions {
  display: flex;
  gap: 8px;
  margin-top: 14px;
}

.hero-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  height: 40px;
  padding: 0 14px;
  border-radius: var(--radius-button);
  border: 1px solid rgba(255, 255, 255, 0.22);
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
  font: inherit;
  font-size: 0.875rem;
  font-weight: 600;
  line-height: 1;
  white-space: nowrap;
  cursor: pointer;
  transition:
    background var(--transition-fast),
    border-color var(--transition-fast);
}

.hero-btn:hover {
  background: rgba(255, 255, 255, 0.18);
  border-color: rgba(255, 255, 255, 0.35);
}

.hero-btn:focus-visible {
  outline: 2px solid #fff;
  outline-offset: 2px;
}

.hero-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.hero-btn.primary {
  flex: 1;
  min-width: 0;
  background: #fff;
  border-color: #fff;
  color: #1f1430;
}

.hero-btn.primary:hover {
  background: rgba(255, 255, 255, 0.88);
}

.hero-btn.icon {
  width: 40px;
  padding: 0;
  flex-shrink: 0;
}

.hero-btn.on {
  color: #ff4d6a;
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

@media (prefers-reduced-motion: reduce) {
  .hero-fav-pop,
  .hero-sparkle {
    animation: none;
  }
}

/* Admin menu, opened from the ⋯ button */
.hero-admin {
  position: relative;
}

.hero-admin-menu {
  position: absolute;
  top: calc(100% + 6px);
  right: 0;
  z-index: 20;
  min-width: 220px;
  padding: 6px;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.18);
  text-align: left;
}

.hero-admin-item {
  display: block;
  width: 100%;
  padding: 8px 10px;
  border: 0;
  border-radius: var(--radius-sm);
  background: none;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 0.875rem;
  text-align: left;
  cursor: pointer;
}

.hero-admin-item:hover,
.hero-admin-item:focus-visible {
  background: var(--color-bg-subtle);
  color: var(--color-text-primary);
  outline: none;
}

.hero-admin-item.danger {
  color: var(--color-danger-text);
}

/* ── Hero info + community panel ── */
.hero-split {
  flex: 1;
  min-width: 0;
  display: grid;
  grid-template-columns: minmax(0, 1fr) 300px;
  gap: 2rem;
  align-items: start;
  padding-top: 0.75rem;
}

.hero-split.form-open {
  grid-template-columns: minmax(0, 1fr);
}

.game-hero-info {
  min-width: 0;
}

.game-title {
  font-size: 2.5rem;
  font-weight: 700;
  color: #fff;
  line-height: 1.15;
  margin-bottom: 0.4rem;
  text-wrap: balance;
  overflow-wrap: anywhere;
}

.game-title.is-long {
  font-size: 2rem;
}

.hero-meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px 10px;
  margin-bottom: 1.5rem;
  font-size: 1rem;
  color: rgba(255, 255, 255, 0.75);
}

.hero-meta :deep(a) {
  color: #fff;
  font-weight: 600;
  text-decoration: underline;
  text-decoration-color: rgba(255, 255, 255, 0.35);
  text-underline-offset: 3px;
}

.hero-meta :deep(a:hover) {
  text-decoration-color: #fff;
}

.hero-meta .dot {
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.45);
}

.hero-tag-group {
  margin-bottom: 1rem;
}

.hero-tag-label {
  font-size: 0.7rem;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.6);
  text-transform: uppercase;
  letter-spacing: 0.08em;
  margin-bottom: 0.4rem;
}

.hero-tags {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
}

.hero-tag {
  display: inline-block;
  align-content: center;
  height: 28px;
  text-box: trim-both cap alphabetic;
  padding: 0 10px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.12);
  color: #fff;
  font-size: 0.8125rem;
  font-weight: 500;
  text-decoration: none;
  transition: background var(--transition-fast);
}

.hero-tag:hover {
  background: rgba(255, 255, 255, 0.2);
  color: #fff;
}

.hero-tag-more {
  display: inline-block;
  align-content: center;
  height: 28px;
  text-box: trim-both cap alphabetic;
  padding: 0 10px;
  border-radius: 6px;
  /* An inset ring rather than a border, so the box stays 28px like the chips. */
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.3);
  color: rgba(255, 255, 255, 0.85);
  font-size: 0.8125rem;
  font-weight: 500;
  text-decoration: none;
  transition: background var(--transition-fast);
}

.hero-tag-more:hover {
  background: rgba(255, 255, 255, 0.12);
  color: #fff;
}

.hero-tag:focus-visible,
.hero-tag-more:focus-visible,
.hero-meta :deep(a:focus-visible) {
  outline: 2px solid #fff;
  outline-offset: 2px;
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

/* ── Body: reviews and activity, with details alongside ── */
.game-body {
  display: grid;
  max-width: 1104px;
  grid-template-columns: minmax(0, 1fr) 340px;
  gap: 2rem;
  align-items: start;
  margin: 2.25rem auto 0;
  transition: opacity 0.3s;
}

.game-body-main,
.game-body-side {
  min-width: 0;
}

/* Dimmed body when form is open */
.game-body.dimmed {
  opacity: 0.3;
  pointer-events: none;
}

.game-notification {
  margin-top: 1.5rem;
}

/* ── Loading skeleton ──
   Reuses the page's layout classes so the bones sit where the content lands.
   Bones on the hero are translucent white; on the cards they use the subtle
   surface colour. A highlight sweeps across each bone unless reduced motion
   is preferred. */
.game-skeleton {
  --skel-bg: color-mix(in srgb, var(--color-border) 45%, var(--color-surface));
  --skel-shine: rgba(255, 255, 255, 0.55);
}

@media (prefers-color-scheme: dark) {
  .game-skeleton {
    --skel-bg: rgba(255, 255, 255, 0.07);
    --skel-shine: rgba(255, 255, 255, 0.06);
  }
}

.game-skeleton .game-hero {
  --skel-bg: rgba(255, 255, 255, 0.14);
  --skel-shine: rgba(255, 255, 255, 0.14);
}

.skel {
  position: relative;
  overflow: hidden;
  background: var(--skel-bg);
  border-radius: 6px;
}

.skel::after {
  content: "";
  position: absolute;
  inset: 0;
  background: linear-gradient(90deg, transparent, var(--skel-shine), transparent);
  transform: translateX(-100%);
  animation: skel-shimmer 1.6s ease-in-out infinite;
}

@keyframes skel-shimmer {
  100% {
    transform: translateX(100%);
  }
}

@media (prefers-reduced-motion: reduce) {
  .skel::after {
    display: none;
  }
}

.skel-cover {
  aspect-ratio: 3 / 4;
  border-radius: var(--radius-lg);
}

.skel-btn {
  width: 40px;
  height: 40px;
  border-radius: var(--radius-button);
  flex-shrink: 0;
}

.skel-btn-primary {
  flex: 1;
}

.skel-title {
  width: 60%;
  height: 2.5rem;
  margin-bottom: 0.75rem;
}

.skel-meta {
  width: 40%;
  height: 1rem;
  margin-bottom: 1.5rem;
}

.skel-tag-label {
  width: 64px;
  height: 0.7rem;
  margin-bottom: 0.6rem;
}

.skel-tag {
  height: 28px;
}

/* Mirrors GameHeroPanel's glass box */
.skel-panel {
  padding: 20px;
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.16);
  border-radius: var(--radius-lg);
}

.skel-panel-rating {
  display: flex;
  align-items: center;
  gap: 16px;
}

.skel-panel-rating-text {
  flex: 1;
}

.skel-ring {
  width: 72px;
  height: 72px;
  border-radius: 50%;
  flex-shrink: 0;
}

.skel-panel-rule {
  margin: 16px 0;
  border-top: 1px solid rgba(255, 255, 255, 0.14);
}

.skel-panel-row + .skel-panel-row {
  margin-top: 14px;
}

.skel-avatars {
  display: flex;
  gap: 4px;
}

.skel-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
}

.skel-line {
  height: 0.875rem;
}

.skel-line + .skel-line {
  margin-top: 8px;
}

.skel-line-sm {
  height: 0.75rem;
}

.skel-card-title {
  width: 96px;
  height: 1.25rem;
  margin-bottom: 4px;
}

.skel-review {
  display: grid;
  grid-template-columns: 40px minmax(0, 1fr);
  gap: 14px;
  padding: 18px 0;
  border-top: 1px solid var(--color-border);
}

.skel-card-title + .skel-review {
  margin-top: 14px;
  border-top: 0;
}

.skel-review:last-child {
  padding-bottom: 4px;
}

.skel-review-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
}

.skel-details-list {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr);
  gap: 10px 16px;
}

.skel-details-list .skel-line + .skel-line {
  margin-top: 0;
}

/* ── Responsive ── */
@media (max-width: 1023px) {
  .hero-split {
    grid-template-columns: minmax(0, 1fr);
  }
}

@media (max-width: 768px) {
  .game-hero {
    padding: 1.5rem 0 1.25rem;
  }

  .game-hero-inner {
    flex-direction: column;
    align-items: stretch;
    gap: 1.25rem;
    padding: 0 1rem;
  }

  .game-hero-cover {
    width: 100%;
  }

  .game-hero-cover img,
  .game-cover-placeholder {
    width: 150px;
    margin: 0 auto;
    border-radius: var(--radius-lg);
  }

  .game-cover-placeholder span {
    font-size: 2.25rem;
  }

  .hero-actions {
    margin-top: 16px;
  }

  .hero-btn {
    height: 44px;
  }

  .hero-btn.icon {
    width: 44px;
  }

  .hero-split {
    padding-top: 0;
    gap: 1.25rem;
  }

  .game-hero-info {
    text-align: center;
  }

  .game-title {
    font-size: 1.625rem;
  }

  .game-title.is-long {
    font-size: 1.375rem;
  }

  .hero-meta,
  .hero-tags {
    justify-content: center;
  }

  .hero-meta {
    margin-bottom: 1rem;
  }

  .game-body {
    grid-template-columns: minmax(0, 1fr);
    gap: 0;
    margin-top: 1rem;
  }

  /* Details first on phones, before the longer reviews and activity cards,
     and the series shelf after them. */
  .game-body-side {
    display: contents;
  }

  #game-details,
  .skel-details {
    order: -1;
  }

  .skel-cover {
    width: 150px;
    margin: 0 auto;
  }

  .skel-btn {
    width: 44px;
    height: 44px;
  }

  .skel-title {
    width: 70%;
    height: 1.875rem;
  }

  .skel-title,
  .skel-meta,
  .game-hero-info .skel-tag-label {
    margin-inline: auto;
  }

  .skel-meta {
    margin-bottom: 1rem;
  }
}
</style>
