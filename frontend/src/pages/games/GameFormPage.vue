<template>
  <div>
    <div class="columns is-centered">
      <div class="column is-8">
        <div v-if="!authStore.isModerator" class="notification is-warning">
          <p>You must be a moderator or admin to create or edit games.</p>
        </div>

        <template v-else>
          <h1 class="title">{{ isEditing ? "Edit Game" : "New Game" }}</h1>

          <div v-if="isEditing && gameLoading" class="has-text-centered py-5">
            <p>Loading game...</p>
          </div>

          <div v-if="isEditing && gameError" class="notification is-danger">
            <p>Failed to load game: {{ gameError.message }}</p>
          </div>

          <!-- `gameData` still holds the previously loaded game while a refetch
               for a new id is in flight, so gate on `gameLoading` too or the
               form renders with the wrong record's values. -->
          <form v-if="!isEditing || (gameData && !gameLoading)" @submit.prevent="handleSubmit">
            <!-- Name -->
            <div class="field">
              <label class="label" for="game-name">Name <span class="has-text-danger">*</span></label>
              <div class="control">
                <input
                  id="game-name"
                  v-model="form.name"
                  class="input"
                  type="text"
                  required
                  maxlength="120"
                  placeholder="Game name"
                />
              </div>
            </div>

            <!-- Release Date -->
            <div class="field">
              <label class="label" for="game-release-date">Release Date</label>
              <div class="control">
                <input id="game-release-date" v-model="form.releaseDate" class="input" type="date" />
              </div>
            </div>

            <!-- Series -->
            <SearchableSelect
              v-model="form.series"
              :search="searchSeries"
              label="Series"
              placeholder="Search series..."
            />

            <!-- Platforms -->
            <SearchableMultiSelect
              v-model="form.platforms"
              :search="searchPlatforms"
              label="Platforms"
              placeholder="Search platforms..."
            />

            <!-- Developers -->
            <SearchableMultiSelect
              v-model="form.developers"
              :search="searchCompanies"
              label="Developers"
              placeholder="Search developers..."
            />

            <!-- Publishers -->
            <SearchableMultiSelect
              v-model="form.publishers"
              :search="searchCompanies"
              label="Publishers"
              placeholder="Search publishers..."
            />

            <!-- Genres -->
            <SearchableMultiSelect
              v-model="form.genres"
              :search="searchGenres"
              label="Genres"
              placeholder="Search genres..."
            />

            <!-- Engines -->
            <SearchableMultiSelect
              v-model="form.engines"
              :search="searchEngines"
              label="Engines"
              placeholder="Search engines..."
            />

            <!-- External IDs -->
            <h2 class="title is-5 mt-5">External IDs</h2>

            <div class="columns is-multiline">
              <div class="column is-6">
                <div class="field">
                  <label class="label" for="game-wikidata-id">Wikidata ID</label>
                  <div class="control">
                    <WikidataIdInput
                      id="game-wikidata-id"
                      v-model="form.wikidataId"
                      aria-describedby="game-wikidata-id-help"
                    />
                  </div>
                  <p id="game-wikidata-id-help" class="help">
                    Like "Q12345". You can also paste the item's Wikidata URL.
                  </p>
                </div>
              </div>

              <div class="column is-6">
                <div class="field">
                  <label class="label" for="game-pcgamingwiki-id">PCGamingWiki ID</label>
                  <div class="control">
                    <input
                      id="game-pcgamingwiki-id"
                      v-model="form.pcgamingwikiId"
                      class="input"
                      type="text"
                      placeholder="e.g. Half-Life_2"
                    />
                  </div>
                </div>
              </div>

              <div class="column is-6">
                <div class="field">
                  <label class="label" for="game-mobygames-id">MobyGames ID</label>
                  <div class="control">
                    <input
                      id="game-mobygames-id"
                      v-model="form.mobygamesId"
                      class="input"
                      type="text"
                      inputmode="numeric"
                      placeholder="e.g. 1234"
                    />
                  </div>
                </div>
              </div>

              <div class="column is-6">
                <div class="field">
                  <label class="label" for="game-giantbomb-id">GiantBomb ID</label>
                  <div class="control">
                    <input
                      id="game-giantbomb-id"
                      v-model="form.giantbombId"
                      class="input"
                      type="text"
                      placeholder="e.g. Games/Portal_2"
                    />
                  </div>
                </div>
              </div>

              <div class="column is-6">
                <div class="field">
                  <label class="label" for="game-epic-id">Epic Games Store ID</label>
                  <div class="control">
                    <input
                      id="game-epic-id"
                      v-model="form.epicGamesStoreId"
                      class="input"
                      type="text"
                      placeholder="e.g. fortnite"
                    />
                  </div>
                </div>
              </div>

              <div class="column is-6">
                <div class="field">
                  <label class="label" for="game-gog-id">GOG ID</label>
                  <div class="control">
                    <input
                      id="game-gog-id"
                      v-model="form.gogId"
                      class="input"
                      type="text"
                      placeholder="e.g. the_witcher_3"
                    />
                  </div>
                </div>
              </div>

              <div class="column is-6">
                <div class="field">
                  <label class="label" for="game-igdb-id">IGDB ID</label>
                  <div class="control">
                    <input
                      id="game-igdb-id"
                      v-model="form.igdbId"
                      class="input"
                      type="text"
                      placeholder="e.g. half-life-2"
                    />
                  </div>
                </div>
              </div>

              <div class="column is-6">
                <div class="field">
                  <label class="label" for="game-steam-ids">Steam App IDs</label>
                  <div class="control">
                    <input
                      id="game-steam-ids"
                      v-model="steamAppIdsInput"
                      class="input"
                      type="text"
                      placeholder="e.g. 220, 440"
                    />
                  </div>
                  <p class="help">Comma-separated list of Steam App IDs.</p>
                </div>
              </div>
            </div>

            <div v-if="submitError" class="notification is-danger mt-4">
              <p>{{ submitError }}</p>
            </div>

            <div class="field is-grouped mt-5">
              <div class="control">
                <button
                  type="submit"
                  class="button is-primary"
                  :class="{ 'is-loading': submitting }"
                  :disabled="submitting"
                >
                  {{ isEditing ? "Save Changes" : "Create Game" }}
                </button>
              </div>
              <div class="control">
                <router-link :to="isEditing ? `/games/${route.params.id}` : '/games'" class="button is-light">
                  Cancel
                </router-link>
              </div>
            </div>
          </form>
        </template>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { notFoundLocation } from "@/utils/not-found";
import { useAuthStore } from "@/stores/auth";
import { useQuery, useMutation } from "@/composables/useGraphQL";
import { usePageTitle } from "@/composables/usePageTitle";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_GAME } from "@/graphql/queries/games";
import {
  SEARCH_COMPANIES_FOR_GAME_FORM,
  SEARCH_ENGINES_FOR_GAME_FORM,
  SEARCH_GENRES_FOR_GAME_FORM,
  SEARCH_PLATFORMS_FOR_GAME_FORM,
  SEARCH_SERIES_FOR_GAME_FORM
} from "@/graphql/queries/game-form";
import { gqlClient } from "@/graphql/client";
import type {
  SearchCompaniesForGameFormQuery,
  SearchEnginesForGameFormQuery,
  SearchGenresForGameFormQuery,
  SearchPlatformsForGameFormQuery,
  SearchSeriesForGameFormQuery
} from "@/types/graphql";
import { CREATE_GAME, UPDATE_GAME } from "@/graphql/mutations/games";
import { extractGqlError } from "@/utils/graphql-errors";
import { isValidWikidataId, normalizeWikidataId } from "@/utils/wikidata";
import SearchableMultiSelect from "@/components/SearchableMultiSelect.vue";
import SearchableSelect from "@/components/SearchableSelect.vue";
import WikidataIdInput from "@/components/WikidataIdInput.vue";
import { gamePrefillFromQuery } from "@/utils/game-prefill";

interface IdName {
  id: string;
  name: string;
}

const ids = (records: IdName[]) => records.map((record) => record.id);

interface GetGameResult {
  game: {
    id: string;
    name: string;
    releaseDate: string | null;
    wikidataId: string | null;
    steamAppIds: number[];
    pcgamingwikiId: string | null;
    mobygamesId: number | null;
    giantbombId: string | null;
    epicGamesStoreId: string | null;
    gogId: string | null;
    igdbId: string | null;
    series: IdName | null;
    developers: { nodes: IdName[] };
    publishers: { nodes: IdName[] };
    platforms: { nodes: IdName[] };
    genres: { nodes: IdName[] };
    engines: { nodes: IdName[] };
  } | null;
}

interface CreateGameResult {
  createGame: { game: { id: string; name: string } | null } | null;
}

interface UpdateGameResult {
  updateGame: { game: { id: string; name: string } | null } | null;
}

const route = useRoute("gameEdit");
const router = useRouter();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const isEditing = computed(() => !!route.params.id);
const gameId = computed(() => route.params.id);

const form = reactive({
  name: "",
  releaseDate: "",
  series: null as IdName | null,
  platforms: [] as IdName[],
  developers: [] as IdName[],
  publishers: [] as IdName[],
  genres: [] as IdName[],
  engines: [] as IdName[],
  wikidataId: "",
  pcgamingwikiId: "",
  mobygamesId: "",
  giantbombId: "",
  epicGamesStoreId: "",
  gogId: "",
  igdbId: ""
});

const steamAppIdsInput = ref("");
const submitError = ref("");

// Links such as the Steam import results can prefill a new game's name and
// Steam App ID, e.g. `/games/new?name=Portal&steamAppId=400`.
if (!isEditing.value) {
  const prefill = gamePrefillFromQuery(route.query);
  form.name = prefill.name;
  steamAppIdsInput.value = prefill.steamAppId !== null ? String(prefill.steamAppId) : "";
}

// Fetch the game data when editing
const {
  data: gameData,
  loading: gameLoading,
  error: gameError
} = useQuery<GetGameResult>(GET_GAME, {
  variables: () => ({ id: gameId.value }),
  enabled: () => isEditing.value,
  // Seeds the form, which a fresh result arriving later would overwrite.
  cache: false
});

usePageTitle(() => {
  const gameName = isEditing.value ? gameData.value?.game?.name : null;
  return gameName ? `Edit ${gameName}` : null;
});

// Populate form when game data loads
watch(
  () => gameData.value?.game,
  (game) => {
    if (!game) {
      return;
    }
    form.name = game.name;
    form.releaseDate = game.releaseDate ?? "";
    form.series = game.series ? { ...game.series } : null;
    form.platforms = [...game.platforms.nodes];
    form.developers = [...game.developers.nodes];
    form.publishers = [...game.publishers.nodes];
    form.genres = [...game.genres.nodes];
    form.engines = [...game.engines.nodes];
    form.wikidataId = game.wikidataId != null ? String(game.wikidataId) : "";
    form.pcgamingwikiId = game.pcgamingwikiId ?? "";
    form.mobygamesId = game.mobygamesId != null ? String(game.mobygamesId) : "";
    form.giantbombId = game.giantbombId ?? "";
    form.epicGamesStoreId = game.epicGamesStoreId ?? "";
    form.gogId = game.gogId ?? "";
    form.igdbId = game.igdbId ?? "";
    steamAppIdsInput.value = game.steamAppIds.join(", ");
  },
  { immediate: true }
);

// Redirect to 404 when editing a non-existent game
watch([gameData, gameError, gameLoading], () => {
  if (isEditing.value && !gameLoading.value && (gameError.value || (gameData.value && !gameData.value.game))) {
    router.replace(notFoundLocation(route));
  }
});

// Search-as-you-type for the association fields. Searching the server (rather
// than filtering one preloaded page, which the API caps at 100 records) means
// every platform, company, etc. can be found.
const searchPlatforms = (query: string) =>
  gqlClient
    .request<SearchPlatformsForGameFormQuery>(SEARCH_PLATFORMS_FOR_GAME_FORM, { query })
    .then((d) => d.platformSearch?.nodes ?? []);
const searchCompanies = (query: string) =>
  gqlClient
    .request<SearchCompaniesForGameFormQuery>(SEARCH_COMPANIES_FOR_GAME_FORM, { query })
    .then((d) => d.companySearch?.nodes ?? []);
const searchGenres = (query: string) =>
  gqlClient
    .request<SearchGenresForGameFormQuery>(SEARCH_GENRES_FOR_GAME_FORM, { query })
    .then((d) => d.genreSearch?.nodes ?? []);
const searchEngines = (query: string) =>
  gqlClient
    .request<SearchEnginesForGameFormQuery>(SEARCH_ENGINES_FOR_GAME_FORM, { query })
    .then((d) => d.engineSearch?.nodes ?? []);
const searchSeries = (query: string) =>
  gqlClient
    .request<SearchSeriesForGameFormQuery>(SEARCH_SERIES_FOR_GAME_FORM, { query })
    .then((d) => d.seriesSearch?.nodes ?? []);

// Mutations
const { mutate: createGame, loading: creating } = useMutation<CreateGameResult>(CREATE_GAME);
const { mutate: updateGame, loading: updating } = useMutation<UpdateGameResult>(UPDATE_GAME);
const submitting = computed(() => creating.value || updating.value);

function parseSteamAppIds(): number[] {
  if (!steamAppIdsInput.value.trim()) {
    return [];
  }
  return steamAppIdsInput.value
    .split(",")
    .map((s) => parseInt(s.trim(), 10))
    .filter((n) => !Number.isNaN(n) && n > 0);
}

async function handleSubmit() {
  submitError.value = "";

  if (!form.name.trim()) {
    submitError.value = "Name is required.";
    return;
  }

  form.wikidataId = normalizeWikidataId(form.wikidataId);
  if (form.wikidataId && !isValidWikidataId(form.wikidataId)) {
    submitError.value = 'Wikidata ID must be a number, like "12345" or "Q12345".';
    return;
  }

  // Send empty arrays explicitly so the backend clears the associations.
  // Send null for optional scalar fields that are blank.
  const variables = {
    name: form.name.trim(),
    releaseDate: form.releaseDate || null,
    wikidataId: form.wikidataId || null,
    seriesId: form.series?.id ?? null,
    platformIds: ids(form.platforms),
    developerIds: ids(form.developers),
    publisherIds: ids(form.publishers),
    genreIds: ids(form.genres),
    engineIds: ids(form.engines),
    pcgamingwikiId: form.pcgamingwikiId || null,
    mobygamesId: form.mobygamesId ? parseInt(form.mobygamesId, 10) : null,
    giantbombId: form.giantbombId || null,
    epicGamesStoreId: form.epicGamesStoreId || null,
    gogId: form.gogId || null,
    igdbId: form.igdbId || null,
    steamAppIds: parseSteamAppIds()
  };

  try {
    if (isEditing.value) {
      const result = await updateGame({ gameId: gameId.value, ...variables });
      const updatedGame = result?.updateGame?.game;
      if (updatedGame) {
        showSnackbar(`${updatedGame.name} has been updated.`);
        router.push(`/games/${updatedGame.id}`);
      }
    } else {
      const result = await createGame(variables);
      const createdGame = result?.createGame?.game;
      if (createdGame) {
        showSnackbar(`${createdGame.name} has been created.`);
        router.push(`/games/${createdGame.id}`);
      }
    }
  } catch (e) {
    submitError.value = extractGqlError(e);
  }
}
</script>
