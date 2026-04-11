<template>
  <section class="section">
    <div class="columns is-centered">
      <div class="column is-8">
        <div v-if="!authStore.isModerator" class="notification is-warning">
          <p>You must be a moderator or admin to create or edit games.</p>
        </div>

        <template v-else>
          <h1 class="title">{{ isEditing ? "Edit Game" : "New Game" }}</h1>

          <div v-if="isEditing && gameLoading && !gameData" class="has-text-centered py-5">
            <p>Loading game...</p>
          </div>

          <div v-if="isEditing && gameError" class="notification is-danger">
            <p>Failed to load game: {{ gameError.message }}</p>
          </div>

          <form v-if="!isEditing || gameData" @submit.prevent="handleSubmit">
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
              v-model="form.seriesId"
              :options="allSeries"
              label="Series"
              placeholder="Search series..."
            />

            <!-- Platforms -->
            <SearchableMultiSelect
              v-model="form.platformIds"
              :options="allPlatforms"
              label="Platforms"
              placeholder="Search platforms..."
            />

            <!-- Developers -->
            <SearchableMultiSelect
              v-model="form.developerIds"
              :options="allCompanies"
              label="Developers"
              placeholder="Search developers..."
            />

            <!-- Publishers -->
            <SearchableMultiSelect
              v-model="form.publisherIds"
              :options="allCompanies"
              label="Publishers"
              placeholder="Search publishers..."
            />

            <!-- Genres -->
            <SearchableMultiSelect
              v-model="form.genreIds"
              :options="allGenres"
              label="Genres"
              placeholder="Search genres..."
            />

            <!-- Engines -->
            <SearchableMultiSelect
              v-model="form.engineIds"
              :options="allEngines"
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
                    <input
                      id="game-wikidata-id"
                      v-model="form.wikidataId"
                      class="input"
                      type="text"
                      placeholder="e.g. 12345"
                    />
                  </div>
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
                      placeholder="e.g. 3030-12345"
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
  </section>
</template>

<script setup lang="ts">
import { computed, reactive, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useAuthStore } from "@/stores/auth";
import { useQuery, useMutation } from "@/composables/useGraphQL";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_GAME } from "@/graphql/queries/games";
import { GET_PLATFORMS, GET_COMPANIES, GET_GENRES, GET_ENGINES, GET_SERIES_LIST } from "@/graphql/queries/resources";
import { CREATE_GAME, UPDATE_GAME } from "@/graphql/mutations/games";
import { extractGqlError } from "@/utils/graphql-errors";
import SearchableMultiSelect from "@/components/SearchableMultiSelect.vue";
import SearchableSelect from "@/components/SearchableSelect.vue";

interface IdName {
  id: string;
  name: string;
}

interface ResourceListResult {
  nodes: IdName[];
}

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
  seriesId: "",
  platformIds: [] as string[],
  developerIds: [] as string[],
  publisherIds: [] as string[],
  genreIds: [] as string[],
  engineIds: [] as string[],
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

// Fetch the game data when editing
const {
  data: gameData,
  loading: gameLoading,
  error: gameError
} = useQuery<GetGameResult>(GET_GAME, {
  variables: () => ({ id: gameId.value }),
  enabled: () => isEditing.value
});

// Populate form when game data loads
watch(
  () => gameData.value?.game,
  (game) => {
    if (!game) return;
    form.name = game.name;
    form.releaseDate = game.releaseDate ?? "";
    form.seriesId = game.series?.id ?? "";
    form.platformIds = game.platforms.nodes.map((p) => p.id);
    form.developerIds = game.developers.nodes.map((d) => d.id);
    form.publisherIds = game.publishers.nodes.map((p) => p.id);
    form.genreIds = game.genres.nodes.map((g) => g.id);
    form.engineIds = game.engines.nodes.map((e) => e.id);
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
    router.replace({ name: "notFound" });
  }
});

// Fetch resource lists for the form dropdowns
const RESOURCE_PAGE_SIZE = 500;

const { data: platformsData } = useQuery<{ platforms: ResourceListResult }>(GET_PLATFORMS, {
  variables: { first: RESOURCE_PAGE_SIZE }
});
const { data: companiesData } = useQuery<{ companies: ResourceListResult }>(GET_COMPANIES, {
  variables: { first: RESOURCE_PAGE_SIZE }
});
const { data: genresData } = useQuery<{ genres: ResourceListResult }>(GET_GENRES, {
  variables: { first: RESOURCE_PAGE_SIZE }
});
const { data: enginesData } = useQuery<{ engines: ResourceListResult }>(GET_ENGINES, {
  variables: { first: RESOURCE_PAGE_SIZE }
});
const { data: seriesData } = useQuery<{ seriesList: ResourceListResult }>(GET_SERIES_LIST, {
  variables: { first: RESOURCE_PAGE_SIZE }
});

const allPlatforms = computed(() => platformsData.value?.platforms?.nodes ?? []);
const allCompanies = computed(() => companiesData.value?.companies?.nodes ?? []);
const allGenres = computed(() => genresData.value?.genres?.nodes ?? []);
const allEngines = computed(() => enginesData.value?.engines?.nodes ?? []);
const allSeries = computed(() => seriesData.value?.seriesList?.nodes ?? []);

// Mutations
const { mutate: createGame, loading: creating } = useMutation<CreateGameResult>(CREATE_GAME);
const { mutate: updateGame, loading: updating } = useMutation<UpdateGameResult>(UPDATE_GAME);
const submitting = computed(() => creating.value || updating.value);

function parseSteamAppIds(): number[] {
  if (!steamAppIdsInput.value.trim()) return [];
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

  // Send empty arrays explicitly so the backend clears the associations.
  // Send null for optional scalar fields that are blank.
  const variables = {
    name: form.name.trim(),
    releaseDate: form.releaseDate || null,
    wikidataId: form.wikidataId || null,
    seriesId: form.seriesId || null,
    platformIds: form.platformIds.length > 0 ? form.platformIds : [],
    developerIds: form.developerIds.length > 0 ? form.developerIds : [],
    publisherIds: form.publisherIds.length > 0 ? form.publisherIds : [],
    genreIds: form.genreIds.length > 0 ? form.genreIds : [],
    engineIds: form.engineIds.length > 0 ? form.engineIds : [],
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
