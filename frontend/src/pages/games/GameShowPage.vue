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
                class="hero-fav-btn"
                :class="{ 'hero-fav-active': game.isFavorited }"
                :disabled="favoriting"
                :aria-label="game.isFavorited ? 'Unfavorite' : 'Favorite'"
                @click="toggleFavorite"
              >
                <span class="hero-fav-heart" :class="{ 'hero-fav-pop': game.isFavorited }">
                  {{ game.isFavorited ? "\u2665" : "\u2661" }}
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
                            :class="
                              formStatus === opt.value ? 'form-pill-on-green' : 'form-pill-off'
                            "
                            @click="formStatus = formStatus === opt.value ? null : opt.value"
                          >
                            {{ opt.label }}
                          </button>
                        </div>
                      </div>

                      <div class="form-group">
                        <label class="form-label">Rating (out of 100)</label>
                        <div class="form-rating-row">
                          <input
                            v-model.number="formRating"
                            type="number"
                            min="0"
                            max="100"
                            class="form-rating-input"
                            @input="clampRating"
                          />
                          <div class="form-rating-track">
                            <div
                              class="form-rating-fill"
                              :style="{ width: (formRating ?? 0) + '%' }"
                            ></div>
                          </div>
                        </div>
                      </div>

                      <div class="form-group">
                        <label class="form-label">Hours played</label>
                        <input
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
                          <label class="form-label">Started</label>
                          <input v-model="formStartDate" type="date" class="form-date-input" />
                        </div>
                        <div class="form-date-field">
                          <label class="form-label">Finished</label>
                          <input v-model="formCompletionDate" type="date" class="form-date-input" />
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
                          <span v-if="storesLoading" class="form-empty-hint">
                            Loading stores...
                          </span>
                        </div>
                      </div>

                      <div class="form-group form-notes-group">
                        <label class="form-label">Review / notes</label>
                        <textarea
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
                          <button type="button" class="form-btn-cancel" @click="cancelAddForm">
                            Cancel
                          </button>
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

      <!-- Remove from library confirmation modal -->
      <Teleport to="body">
        <div
          v-if="showRemoveConfirm"
          class="modal is-active"
          role="dialog"
          aria-modal="true"
          :aria-label="`Confirm removing ${game.name} from your library`"
          @keydown="onRemoveModalKeydown"
        >
          <div class="modal-background" @click="showRemoveConfirm = false"></div>
          <div ref="removeModalRef" class="modal-card remove-confirm-modal" tabindex="-1">
            <header class="modal-card-head">
              <p class="modal-card-title">Remove from library</p>
              <button class="delete" aria-label="Close" @click="showRemoveConfirm = false"></button>
            </header>
            <section class="modal-card-body">
              <p>
                Are you sure you want to remove <strong>{{ game.name }}</strong> from your library?
                This will delete your rating, status, and notes for this game.
              </p>
            </section>
            <footer class="modal-card-foot remove-confirm-footer">
              <button class="button" @click="showRemoveConfirm = false">Cancel</button>
              <button
                class="button is-danger"
                :disabled="removingFromLibrary"
                @click="confirmRemoveFromLibrary"
              >
                {{ removingFromLibrary ? "Removing\u2026" : "Remove" }}
              </button>
            </footer>
          </div>
        </div>
      </Teleport>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, ref, watch } from "vue";
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
import type {
  GetGameQuery,
  GetGamePurchaseQuery,
  GetStoresQuery,
  GamePurchaseCompletionStatus
} from "@/types/graphql";
import { extractGqlError } from "@/utils/graphql-errors";
import { useSnackbar } from "@/composables/useSnackbar";

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
const formPlatformIds = ref(new Set<string>());
const formStoreIds = ref(new Set<string>());
const formHoursPlayed = ref<number | null>(null);
const formComments = ref("");
const inLibraryHovered = ref(false);
const showRemoveConfirm = ref(false);
const removeModalRef = ref<HTMLElement | null>(null);

// ── Remove confirmation modal: focus management ──
function getFocusableElements(): HTMLElement[] {
  if (!removeModalRef.value) return [];
  return Array.from(
    removeModalRef.value.querySelectorAll<HTMLElement>(
      'button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
    )
  );
}

function onRemoveModalKeydown(e: KeyboardEvent) {
  if (e.key === "Escape") {
    showRemoveConfirm.value = false;
    return;
  }

  if (e.key === "Tab") {
    const focusable = getFocusableElements();
    if (focusable.length === 0) return;

    const first = focusable[0];
    const last = focusable[focusable.length - 1];

    if (e.shiftKey) {
      if (document.activeElement === first) {
        e.preventDefault();
        last.focus();
      }
    } else {
      if (document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
    }
  }
}

let previouslyFocusedElement: HTMLElement | null = null;

watch(showRemoveConfirm, (isOpen) => {
  if (isOpen) {
    previouslyFocusedElement = document.activeElement as HTMLElement | null;
    nextTick(() => {
      removeModalRef.value?.focus();
    });
  } else {
    previouslyFocusedElement?.focus();
    previouslyFocusedElement = null;
  }
});

onBeforeUnmount(() => {
  showRemoveConfirm.value = false;
});

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
  resetForm();
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

  resetForm();
  isEditing.value = true;
  showAddForm.value = true;

  try {
    const result = await gqlClient.request<GetGamePurchaseQuery>(GET_GAME_PURCHASE, {
      id: purchaseId
    });
    const gp = result.gamePurchase;
    if (!gp) return;

    formStatus.value = (gp.completionStatus as GamePurchaseCompletionStatus) ?? null;
    formRating.value = gp.rating ?? null;
    formHoursPlayed.value = gp.hoursPlayed ?? null;
    formStartDate.value = gp.startDate ?? "";
    formCompletionDate.value = gp.completionDate ?? "";
    formComments.value = gp.comments ?? "";
    formPlatformIds.value = new Set(gp.platforms.nodes.map((p) => p.id));
    formStoreIds.value = new Set(gp.stores.nodes.map((s) => s.id));
  } catch {
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

const dateValidationError = computed(() => {
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
  --game-border-light: hsl(0, 0%, 92%);
  --game-text-muted: var(--color-text-secondary);
  --game-text-label: var(--color-text-tertiary);
  --game-track-bg: var(--color-border);
}

@media (prefers-color-scheme: dark) {
  .game-show {
    --game-border-light: hsl(217, 20%, 34%);
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
  padding: 0.25rem;
  font-size: 1.5rem;
  line-height: 1;
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.8);
  cursor: pointer;
  transition: color 0.15s;
}

.hero-fav-btn:hover {
  color: #fff;
}

.hero-fav-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.hero-fav-active {
  color: #ff4d6a;
}

.hero-fav-active:hover {
  color: #ff6b83;
}

.hero-fav-heart {
  display: inline-block;
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
  border-color: #aaa;
  color: #555;
}

.form-pill-on {
  background: #e6f1fb;
  color: #0c447c;
  font-weight: 500;
  border: 1px solid transparent;
}

.form-pill-on-green {
  background: #eaf3de;
  color: #27500a;
  font-weight: 500;
  border: 1px solid transparent;
}

.form-empty-hint {
  font-size: 0.75rem;
  color: #aaa;
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
  background: var(--color-bg-subtle);
  overflow: hidden;
}

.form-rating-fill {
  height: 100%;
  border-radius: 3px;
  background: #27500a;
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
  flex: 1;
  min-height: 60px;
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
  background: var(--color-text-primary);
  color: #fff;
  font-size: 0.8rem;
  border: none;
  border-radius: var(--radius-md);
  padding: 0.5rem 1.25rem;
  cursor: pointer;
  font-family: inherit;
}

.form-btn-save:hover {
  background: #444441;
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

/* ── Remove confirmation modal ── */
.remove-confirm-modal {
  max-width: 480px;
}

.remove-confirm-modal:focus-visible {
  outline: 2px solid var(--vglist-theme);
  outline-offset: 2px;
}

.remove-confirm-footer {
  justify-content: flex-end;
  gap: 0.5rem;
}

.remove-confirm-footer .button:focus-visible {
  outline: 2px solid var(--vglist-theme);
  outline-offset: 2px;
}
</style>
