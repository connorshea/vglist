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
                    <span v-for="i in 6" :key="i" class="hero-sparkle" :style="sparkleStyle(i)" />
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
                <div class="form-card">
                  <div class="form-grid">
                    <!-- Left column: Status, Rating, Dates -->
                    <div class="form-col form-col-left">
                      <div class="form-group">
                        <label class="form-label">Status</label>
                        <div class="form-pills">
                          <button
                            v-for="opt in statusOptions"
                            :key="opt.value"
                            type="button"
                            class="form-pill"
                            :class="formStatus === opt.value ? 'form-pill-on' : 'form-pill-off'"
                            @click="formStatus = formStatus === opt.value ? null : opt.value"
                          >
                            {{ opt.label }}
                          </button>
                        </div>
                      </div>

                      <div class="form-group">
                        <label class="form-label" for="form-rating">Rating (out of 100)</label>
                        <div class="form-rating-row">
                          <input
                            id="form-rating"
                            v-model.number="formRating"
                            type="number"
                            min="0"
                            max="100"
                            class="form-rating-input"
                            @input="clampRating"
                          />
                          <div class="form-rating-track" @click="setRatingFromClick">
                            <div class="form-rating-fill" :style="{ width: (formRating ?? 0) + '%' }"></div>
                          </div>
                        </div>
                      </div>

                      <div class="form-group">
                        <label class="form-label" for="form-hours-played">Hours played</label>
                        <input
                          id="form-hours-played"
                          v-model.number="formHoursPlayed"
                          type="number"
                          min="0"
                          step="0.1"
                          class="form-hours-input"
                          placeholder="0"
                        />
                      </div>

                      <div class="form-dates">
                        <div class="form-date-field">
                          <div class="form-label-row">
                            <label class="form-label" for="form-start-date">Started</label>
                            <button type="button" class="form-date-today" @click="formStartDate = today">Today</button>
                          </div>
                          <input
                            id="form-start-date"
                            v-model="formStartDate"
                            type="date"
                            class="form-date-input"
                            :max="today"
                          />
                        </div>
                        <div class="form-date-field">
                          <div class="form-label-row">
                            <label class="form-label" for="form-completion-date">Finished</label>
                            <button type="button" class="form-date-today" @click="formCompletionDate = today">
                              Today
                            </button>
                          </div>
                          <input
                            id="form-completion-date"
                            v-model="formCompletionDate"
                            type="date"
                            class="form-date-input"
                            :max="today"
                          />
                        </div>
                      </div>
                      <p v-if="dateValidationError" class="form-date-error">
                        {{ dateValidationError }}
                      </p>
                    </div>

                    <!-- Right column: Platforms, Store, Notes, Actions -->
                    <div class="form-col form-col-right">
                      <div class="form-group">
                        <label class="form-label">Platforms played</label>
                        <div class="form-pills">
                          <button
                            v-for="plat in game.platforms.nodes"
                            :key="plat.id"
                            type="button"
                            class="form-pill"
                            :class="formPlatformIds.has(plat.id) ? 'form-pill-on' : 'form-pill-off'"
                            @click="toggleFormPlatform(plat.id)"
                          >
                            {{ plat.name }}
                          </button>
                          <span v-if="game.platforms.nodes.length === 0" class="form-empty-hint">
                            No platforms listed for this game.
                          </span>
                        </div>
                      </div>

                      <div class="form-group">
                        <label class="form-label">Store</label>
                        <div class="form-pills">
                          <button
                            v-for="store in allStores"
                            :key="store.id"
                            type="button"
                            class="form-pill"
                            :class="formStoreIds.has(store.id) ? 'form-pill-on' : 'form-pill-off'"
                            @click="toggleFormStore(store.id)"
                          >
                            {{ store.name }}
                          </button>
                          <span v-if="storesLoading" class="form-empty-hint"> Loading stores... </span>
                        </div>
                      </div>

                      <div class="form-group form-notes-group">
                        <label class="form-label" for="form-comments">Review / notes</label>
                        <textarea
                          id="form-comments"
                          v-model="formComments"
                          class="form-textarea"
                          placeholder="What did you think?"
                          maxlength="2000"
                        ></textarea>
                      </div>

                      <div class="form-actions">
                        <button
                          v-if="isEditing"
                          type="button"
                          class="form-btn-remove"
                          :disabled="removingFromLibrary"
                          @click="showRemoveConfirm = true"
                        >
                          {{ removingFromLibrary ? "Removing\u2026" : "Remove" }}
                        </button>
                        <div class="form-actions-right">
                          <button type="button" class="form-btn-cancel" @click="cancelAddForm">Cancel</button>
                          <button
                            type="button"
                            class="form-btn-save"
                            :disabled="addingToLibrary || !!dateValidationError"
                            @click="submitAddForm"
                          >
                            {{ addingToLibrary ? "Saving\u2026" : "Save" }}
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </Transition>
          </div>
        </div>
      </section>

      <!-- Content below hero -->
      <div class="game-body" :class="{ dimmed: showAddForm }">
        <div class="columns is-variable is-6">
          <!-- Main column -->
          <div class="column is-8">
            <!-- Rating -->
            <div v-if="game.avgRating" class="game-rating">
              <div class="rating-circle-wrapper">
                <svg class="rating-circle-svg" viewBox="0 0 120 120">
                  <circle class="rating-circle-bg" cx="60" cy="60" r="52" fill="none" stroke-width="5" />
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
                    <router-link :to="`/companies/${pub.id}`" class="detail-link">{{ pub.name }}</router-link>
                    <span v-if="i < game.publishers.nodes.length - 1">, </span>
                  </template>
                </span>
              </div>
              <div v-if="game.developers.nodes.length" class="detail-card">
                <span class="detail-label">DEVELOPERS</span>
                <span class="detail-value">
                  <template v-for="(dev, i) in game.developers.nodes" :key="dev.id">
                    <router-link :to="`/companies/${dev.id}`" class="detail-link">{{ dev.name }}</router-link>
                    <span v-if="i < game.developers.nodes.length - 1">, </span>
                  </template>
                </span>
              </div>
              <div v-if="game.engines.nodes.length" class="detail-card">
                <span class="detail-label">ENGINE</span>
                <span class="detail-value">
                  <template v-for="(eng, i) in game.engines.nodes" :key="eng.id">
                    <router-link :to="`/engines/${eng.id}`" class="detail-link">{{ eng.name }}</router-link>
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
                    <router-link :to="`/platforms/${plat.id}`" class="detail-link">{{ plat.name }}</router-link>
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
                    <span v-else class="avatar-initials" :style="{ background: avatarColor(owner.username) }">
                      {{ userInitials(owner.username) }}
                    </span>
                  </router-link>
                  <span v-if="game.owners.totalCount > game.owners.nodes.length" class="avatar-overflow">
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
                    <span v-else class="avatar-initials" :style="{ background: avatarColor(fav.username) }">
                      {{ userInitials(fav.username) }}
                    </span>
                  </router-link>
                  <span v-if="game.favoriters.totalCount > game.favoriters.nodes.length" class="avatar-overflow">
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
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, ref, watch } from "vue";
import { useRoute } from "vue-router";
import { useQuery } from "@/composables/useGraphQL";
import { useAuthStore } from "@/stores/auth";
import { gqlClient } from "@/graphql/client";
import { GET_GAME, GET_GAME_PURCHASE } from "@/graphql/queries/games";
import { GET_STORES } from "@/graphql/queries/resources";
import {
  ADD_GAME_TO_LIBRARY,
  UPDATE_GAME_IN_LIBRARY,
  REMOVE_GAME_FROM_LIBRARY,
  FAVORITE_GAME,
  UNFAVORITE_GAME
} from "@/graphql/mutations/games";
import type { GetGameQuery, GetGamePurchaseQuery, GetStoresQuery, GamePurchaseCompletionStatus } from "@/types/graphql";
import { Heart, CircleAlert } from "lucide-vue-next";
import { extractGqlError } from "@/utils/graphql-errors";
import { useSnackbar } from "@/composables/useSnackbar";
import ConfirmDialog from "@/components/ConfirmDialog.vue";

const route = useRoute();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const gameId = computed(() => route.params.id as string);

const { data, loading, error, refetch } = useQuery<GetGameQuery>(GET_GAME, {
  variables: () => ({ id: gameId.value })
});

const game = computed(() => data.value?.game ?? null);

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

const AVATAR_COLORS = ["#6c5ce7", "#00b894", "#e17055", "#0984e3", "#e84393", "#00a862", "#d63031", "#fdcb6e"];

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

// ── Add to Library form state ──
const statusOptions: { value: GamePurchaseCompletionStatus; label: string }[] = [
  { value: "UNPLAYED", label: "Unplayed" },
  { value: "IN_PROGRESS", label: "Playing" },
  { value: "PAUSED", label: "Paused" },
  { value: "DROPPED", label: "Dropped" },
  { value: "COMPLETED", label: "Completed" },
  { value: "FULLY_COMPLETED", label: "100%" },
  { value: "NOT_APPLICABLE", label: "N/A" }
];

const showAddForm = ref(false);
const isEditing = ref(false);
const formStatus = ref<GamePurchaseCompletionStatus | null>(null);
const formRating = ref<number | null>(null);
const formStartDate = ref("");
const formCompletionDate = ref("");
const today = computed(() => new Date().toISOString().slice(0, 10));
const formPlatformIds = ref(new Set<string>());
const formStoreIds = ref(new Set<string>());
const formHoursPlayed = ref<number | null>(null);
const formComments = ref("");

/** localStorage key for persisting review draft text per game. */
function reviewDraftKey(): string {
  return `vglist-review-draft-${gameId.value}`;
}

/** Load a saved review draft from localStorage, but only if the field is currently empty. */
function loadReviewDraft(): void {
  if (formComments.value !== "") return;
  const saved = localStorage.getItem(reviewDraftKey());
  if (saved) {
    formComments.value = saved;
  }
}

/** Clear the saved review draft from localStorage. */
function clearReviewDraft(): void {
  localStorage.removeItem(reviewDraftKey());
}

// Suppress localStorage sync during form reset/population.
let suppressDraftSync = false;

// Persist the review text to localStorage whenever it changes.
watch(formComments, (value) => {
  if (suppressDraftSync) return;
  if (value.trim() === "") {
    clearReviewDraft();
  } else {
    localStorage.setItem(reviewDraftKey(), value);
  }
});

const inLibraryHovered = ref(false);
const showRemoveConfirm = ref(false);

// ── Hero height animation (smooth expand/collapse) ──
const heroInfoRef = ref<HTMLElement | null>(null);
let savedInfoHeight = 0;

function onHeroBeforeLeave() {
  const el = heroInfoRef.value;
  if (el) {
    savedInfoHeight = el.getBoundingClientRect().height;
    el.style.height = savedInfoHeight + "px";
    el.style.overflow = "hidden";
  }
}

function onHeroEnter() {
  const el = heroInfoRef.value;
  if (!el) return;

  nextTick(() => {
    // Measure new natural height
    el.style.height = "auto";
    const newHeight = el.getBoundingClientRect().height;

    // Snap back to saved height
    el.style.height = savedInfoHeight + "px";
    void el.offsetHeight; // force reflow

    // Animate to new height
    el.style.transition = "height 0.35s ease";
    el.style.height = newHeight + "px";
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

function resetForm() {
  formStatus.value = null;
  formRating.value = null;
  formHoursPlayed.value = null;
  formStartDate.value = "";
  formCompletionDate.value = "";
  formPlatformIds.value = new Set();
  formStoreIds.value = new Set();
  formComments.value = "";
  isEditing.value = false;
}

function openAddForm() {
  suppressDraftSync = true;
  resetForm();
  suppressDraftSync = false;
  loadReviewDraft();
  showAddForm.value = true;
}

function toggleAddForm() {
  if (showAddForm.value) {
    showAddForm.value = false;
  } else {
    openAddForm();
  }
}

async function openEditForm() {
  const purchaseId = game.value?.gamePurchaseId;
  if (!purchaseId) return;

  suppressDraftSync = true;
  resetForm();
  isEditing.value = true;
  showAddForm.value = true;

  try {
    const result = await gqlClient.request<GetGamePurchaseQuery>(GET_GAME_PURCHASE, {
      id: purchaseId
    });
    const gp = result.gamePurchase;
    if (!gp) {
      suppressDraftSync = false;
      return;
    }

    formStatus.value = (gp.completionStatus as GamePurchaseCompletionStatus) ?? null;
    formRating.value = gp.rating ?? null;
    formHoursPlayed.value = gp.hoursPlayed ?? null;
    formStartDate.value = gp.startDate ?? "";
    formCompletionDate.value = gp.completionDate ?? "";
    formComments.value = gp.comments ?? "";
    suppressDraftSync = false;
    loadReviewDraft();
    formPlatformIds.value = new Set(gp.platforms.nodes.map((p) => p.id));
    formStoreIds.value = new Set(gp.stores.nodes.map((s) => s.id));
  } catch {
    suppressDraftSync = false;
    actionMessage.value = "Failed to load game purchase details.";
    actionIsError.value = true;
  }
}

function toggleEditForm() {
  if (showAddForm.value) {
    showAddForm.value = false;
  } else {
    openEditForm();
  }
}

function cancelAddForm() {
  showAddForm.value = false;
}

function toggleFormPlatform(id: string) {
  const next = new Set(formPlatformIds.value);
  if (next.has(id)) {
    next.delete(id);
  } else {
    next.add(id);
  }
  formPlatformIds.value = next;
}

function toggleFormStore(id: string) {
  const next = new Set(formStoreIds.value);
  if (next.has(id)) {
    next.delete(id);
  } else {
    next.add(id);
  }
  formStoreIds.value = next;
}

function clampRating() {
  if (formRating.value == null) return;
  if (formRating.value > 100) formRating.value = 100;
  if (formRating.value < 0) formRating.value = 0;
}

function setRatingFromClick(event: MouseEvent) {
  const track = event.currentTarget as HTMLElement;
  const rect = track.getBoundingClientRect();
  const pct = ((event.clientX - rect.left) / rect.width) * 100;
  formRating.value = Math.round(Math.min(100, Math.max(0, pct)));
}

const dateValidationError = computed(() => {
  const todayStr = today.value;
  if (formStartDate.value && formStartDate.value > todayStr) {
    return "Start date cannot be in the future.";
  }
  if (formCompletionDate.value && formCompletionDate.value > todayStr) {
    return "Completion date cannot be in the future.";
  }
  if (formStartDate.value && formCompletionDate.value) {
    if (formStartDate.value > formCompletionDate.value) {
      return "Start date must be on or before the completion date.";
    }
  }
  return "";
});

// ── Action state ──
const addingToLibrary = ref(false);
const removingFromLibrary = ref(false);
const favoriting = ref(false);
const sparkleKey = ref(0);

function sparkleStyle(i: number): Record<string, string> {
  const angle = (i - 1) * 60;
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
}
const actionMessage = ref("");
const actionIsError = ref(false);

const actionMessageClass = computed(() => (actionIsError.value ? "is-danger" : "is-success"));

function buildFormVariables(): Record<string, unknown> {
  const variables: Record<string, unknown> = {};

  if (formStatus.value) {
    variables.completionStatus = formStatus.value;
  }
  if (formRating.value != null && formRating.value >= 0) {
    variables.rating = Math.round(Math.min(100, Math.max(0, formRating.value)));
  }
  if (formHoursPlayed.value != null && formHoursPlayed.value >= 0) {
    variables.hoursPlayed = formHoursPlayed.value;
  }
  if (formStartDate.value) {
    variables.startDate = formStartDate.value;
  }
  if (formCompletionDate.value) {
    variables.completionDate = formCompletionDate.value;
  }
  if (formPlatformIds.value.size > 0) {
    variables.platforms = [...formPlatformIds.value];
  }
  if (formStoreIds.value.size > 0) {
    variables.stores = [...formStoreIds.value];
  }
  if (formComments.value.trim()) {
    variables.comments = formComments.value.trim();
  }

  return variables;
}

async function submitAddForm() {
  if (!authStore.isAuthenticated) {
    actionMessage.value = "You must be signed in to add games to your library.";
    actionIsError.value = true;
    return;
  }

  if (dateValidationError.value) {
    actionMessage.value = dateValidationError.value;
    actionIsError.value = true;
    return;
  }

  addingToLibrary.value = true;
  actionMessage.value = "";

  const variables = buildFormVariables();

  try {
    if (isEditing.value) {
      variables.gamePurchaseId = game.value?.gamePurchaseId;
      await gqlClient.request(UPDATE_GAME_IN_LIBRARY, variables);
      showSnackbar(`${game.value?.name ?? "Game"} has been updated in your library.`);
    } else {
      variables.gameId = gameId.value;
      await gqlClient.request(ADD_GAME_TO_LIBRARY, variables);
      showSnackbar(`${game.value?.name ?? "Game"} has been added to your library.`);
    }
    actionMessage.value = "";
    actionIsError.value = false;
    showAddForm.value = false;
    clearReviewDraft();
    refetch();
  } catch (err) {
    const action = isEditing.value ? "update" : "add";
    actionMessage.value = `Failed to ${action} game in library: ${extractGqlError(err)}`;
    actionIsError.value = true;
  } finally {
    addingToLibrary.value = false;
  }
}

async function removeFromLibrary() {
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
    clearReviewDraft();
    refetch();
  } catch (err) {
    actionMessage.value = `Failed to remove game from library: ${extractGqlError(err)}`;
    actionIsError.value = true;
    showRemoveConfirm.value = false;
  } finally {
    removingFromLibrary.value = false;
  }
}

async function confirmRemoveFromLibrary() {
  await removeFromLibrary();
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

  .detail-link {
    color: var(--game-link-color);
  }

  .sidebar-tag {
    color: var(--s-100);
    border-color: var(--s-300);
  }

  .rating-circle-value {
    color: var(--game-link-color);
  }

  .details-heading {
    color: var(--game-link-color);
  }

  .rating-bar-fill {
    background: var(--p-400);
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

/* ── Inline form (replaces tags in hero) ── */
.form-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  overflow: hidden;
  color: var(--color-text-primary);
}

.form-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1.2fr);
}

.form-col {
  padding: 1.25rem;
}

.form-col-left {
  border-right: 1px solid var(--color-border);
}

.form-col-right {
  display: flex;
  flex-direction: column;
}

.form-group {
  margin-bottom: 1rem;
}

.form-label {
  display: block;
  font-size: 0.75rem;
  color: var(--color-text-secondary);
  margin-bottom: 0.4rem;
}

/* Form pills */
.form-pills {
  display: flex;
  flex-wrap: wrap;
  gap: 0.25rem;
}

.form-pill {
  font-size: 0.75rem;
  padding: 0.3rem 0.75rem;
  border-radius: var(--radius-pill);
  cursor: pointer;
  transition: all 0.15s;
  display: inline-block;
  user-select: none;
  border: none;
  background: none;
  font-family: inherit;
}

.form-pill-off {
  background: transparent;
  border: 1px solid var(--color-border);
  color: var(--color-text-secondary);
}

.form-pill-off:hover {
  border-color: var(--color-text-secondary);
  color: var(--color-text-primary);
}

.form-pill-on {
  background: var(--p-100);
  color: var(--p-700);
  font-weight: 500;
  border: 1px solid var(--p-100);
}

.form-empty-hint {
  font-size: 0.75rem;
  color: var(--color-text-tertiary);
  font-style: italic;
}

/* Rating input */
.form-rating-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.form-rating-input {
  width: 56px;
  font-size: 0.8rem;
  text-align: center;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 0.35rem 0.5rem;
  outline: none;
  font-family: inherit;
}

.form-rating-input:focus {
  border-color: var(--color-text-secondary);
}

.form-rating-track {
  flex: 1;
  height: 6px;
  border-radius: 3px;
  background: var(--p-100);
  overflow: hidden;
  cursor: pointer;
}

.form-rating-fill {
  height: 100%;
  border-radius: 3px;
  background: var(--p-500);
  transition: width 0.15s;
}

/* Date inputs */
.form-dates {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.625rem;
}

.form-date-input {
  width: 100%;
  font-size: 0.75rem;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 0.35rem 0.5rem;
  outline: none;
  font-family: inherit;
}

.form-date-input:focus {
  border-color: var(--color-text-secondary);
}

.form-label-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
}

.form-label-row .form-label {
  margin-bottom: 0;
}

.form-date-today {
  font-size: 0.7rem;
  font-weight: 600;
  color: var(--p-500);
  background: none;
  border: none;
  padding: 0;
  cursor: pointer;
  font-family: inherit;
  margin-bottom: 0.4rem;
}

.form-date-today:hover {
  color: var(--p-600);
  text-decoration: underline;
}

.form-date-error {
  color: #cc0000;
  font-size: 0.75rem;
  margin-top: 0.25rem;
}

/* Hours played input */
.form-hours-input {
  width: 80px;
  font-size: 0.8rem;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 0.35rem 0.5rem;
  outline: none;
  font-family: inherit;
}

.form-hours-input:focus {
  border-color: var(--color-text-secondary);
}

/* Notes textarea */
.form-notes-group {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.form-textarea {
  width: 100%;
  font-size: 0.8rem;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 0.5rem 0.625rem;
  outline: none;
  resize: vertical;
  min-height: 80px;
  font-family: inherit;
}

.form-textarea:focus {
  border-color: var(--color-text-secondary);
}

/* Form action buttons */
.form-actions {
  display: flex;
  gap: 0.5rem;
  justify-content: space-between;
  align-items: center;
  padding-top: 0.75rem;
}

.form-actions-right {
  display: flex;
  gap: 0.5rem;
}

.form-btn-remove {
  color: #c0392b;
  font-size: 0.8rem;
  background: none;
  border: 1px solid #e8c4c0;
  border-radius: var(--radius-md);
  padding: 0.5rem 1rem;
  cursor: pointer;
  font-family: inherit;
}

.form-btn-remove:hover {
  background: #fdf0ef;
  border-color: #c0392b;
}

.form-btn-remove:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.form-btn-cancel {
  color: var(--color-text-secondary);
  font-size: 0.8rem;
  background: none;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 0.5rem 1rem;
  cursor: pointer;
  font-family: inherit;
}

.form-btn-cancel:hover {
  background: var(--color-bg-subtle);
}

.form-btn-save {
  background: var(--p-500);
  color: #fff;
  font-size: 0.8rem;
  border: none;
  border-radius: var(--radius-md);
  padding: 0.5rem 1.25rem;
  cursor: pointer;
  font-family: inherit;
}

.form-btn-save:hover {
  background: var(--p-600);
}

.form-btn-save:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Dimmed body when form is open */
.game-body.dimmed {
  opacity: 0.3;
  pointer-events: none;
  transition: opacity 0.3s;
}

/* ── Body content ── */
.game-body {
  margin-top: 2rem;
  transition: opacity 0.3s;
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
  background: linear-gradient(90deg, var(--p-500), var(--p-400));
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
  border-radius: var(--radius-md);
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
  border-radius: var(--radius-md);
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
  border-radius: var(--radius-pill);
  color: var(--vglist-theme);
  font-size: 0.85rem;
  font-weight: 500;
  text-decoration: none;
  transition: background 0.15s;
}

.sidebar-tag:hover {
  background: color-mix(in srgb, var(--vglist-theme) 10%, transparent);
}

@media (prefers-color-scheme: dark) {
  .sidebar-tag:hover {
    background: color-mix(in srgb, var(--p-300) 15%, transparent);
  }
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
  color: var(--game-text-muted);
}

.community-divider {
  border: none;
  border-top: 1px solid var(--game-border-light);
  margin: 0.75rem 0;
}

.community-empty {
  font-size: 0.85rem;
  color: var(--game-text-muted);
}

.avatar-stack {
  display: flex;
  align-items: center;
}

.avatar-circle {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: 2px solid var(--color-surface);
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
  color: var(--game-text-muted);
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

  .form-grid {
    grid-template-columns: 1fr;
  }

  .form-col-left {
    border-right: none;
    border-bottom: 1px solid var(--color-border);
  }

  .details-grid {
    grid-template-columns: 1fr;
  }
}

/* ── Dark mode: form overrides ── */
@media (prefers-color-scheme: dark) {
  .form-card {
    border: 1px solid var(--s-300);
  }

  .form-pill-on {
    background: rgba(206, 203, 246, 0.12);
    color: var(--p-200);
  }

  .form-rating-track {
    background: rgba(157, 153, 224, 0.15);
  }

  .form-rating-fill {
    background: var(--p-400);
  }

  .form-rating-input,
  .form-hours-input,
  .form-date-input,
  .form-textarea {
    background: var(--s-600);
    color: var(--s-50);
  }

  .form-rating-input::placeholder,
  .form-hours-input::placeholder,
  .form-date-input::placeholder,
  .form-textarea::placeholder {
    color: var(--s-300);
  }

  .form-btn-remove {
    background: rgba(226, 75, 74, 0.15);
    color: var(--r-200);
    border-color: transparent;
  }

  .form-btn-remove:hover {
    background: rgba(226, 75, 74, 0.25);
    border-color: transparent;
  }

  .form-date-error {
    color: var(--r-200);
  }

  .form-date-today {
    color: var(--p-300);
  }

  .form-date-today:hover {
    color: var(--p-200);
  }
}
</style>
