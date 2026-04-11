<template>
  <section class="section">
    <h1 class="title">Admin</h1>

    <div class="tabs">
      <ul>
        <li :class="{ 'is-active': activeTab === 'dashboard' }">
          <a @click="activeTab = 'dashboard'">Dashboard</a>
        </li>
        <li :class="{ 'is-active': activeTab === 'wikidataBlocklist' }">
          <a @click="activeTab = 'wikidataBlocklist'">Wikidata Blocklist</a>
        </li>
        <li :class="{ 'is-active': activeTab === 'steamBlocklist' }">
          <a @click="activeTab = 'steamBlocklist'">Steam Blocklist</a>
        </li>
        <li :class="{ 'is-active': activeTab === 'unmatchedGames' }">
          <a @click="activeTab = 'unmatchedGames'">Unmatched Games</a>
        </li>
      </ul>
    </div>

    <!-- Dashboard tab -->
    <div v-if="activeTab === 'dashboard'">
      <div v-if="statsLoading" class="has-text-centered py-6">Loading statistics...</div>
      <div v-if="statsError" class="notification is-danger">{{ statsError.message }}</div>

      <template v-if="stats">
        <div class="box">
          <h3 class="has-text-centered has-text-weight-bold mb-4">Statistics</h3>
          <div class="columns is-multiline has-text-centered">
            <div v-for="item in coreStats" :key="item.label" class="column is-2">
              <p class="heading">{{ item.label }}</p>
              <p class="title is-5">{{ item.value.toLocaleString() }}</p>
            </div>
          </div>
        </div>

        <div class="box mt-5">
          <h3 class="has-text-centered has-text-weight-bold mb-4">External Identifiers</h3>
          <div class="columns is-multiline has-text-centered">
            <div v-for="item in externalIdStats" :key="item.label" class="column is-2">
              <p class="heading">{{ item.label }}</p>
              <p class="title is-5">{{ item.value.toLocaleString() }}</p>
            </div>
          </div>
        </div>
      </template>
    </div>

    <!-- Wikidata Blocklist tab -->
    <div v-if="activeTab === 'wikidataBlocklist'">
      <div v-if="wbLoading" class="has-text-centered py-6">Loading...</div>
      <div v-if="wbError" class="notification is-danger">{{ wbError.message }}</div>

      <template v-if="wbData">
        <div class="table-container">
          <table class="table is-fullwidth is-striped">
            <thead>
              <tr>
                <th>Wikidata ID</th>
                <th>Game Name</th>
                <th>Created by</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="entry in wbData.wikidataBlocklist?.nodes" :key="entry.id">
                <td>
                  <a
                    :href="`https://www.wikidata.org/wiki/Q${entry.wikidataId}`"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    {{ entry.wikidataId }}
                  </a>
                </td>
                <td>{{ entry.name }}</td>
                <td>
                  <router-link v-if="entry.user" :to="`/users/${entry.user.slug}`">
                    {{ entry.user.username }}
                  </router-link>
                </td>
                <td>
                  <button class="button is-small is-danger is-outlined" @click="removeFromWikidataBlocklist(entry.id)">
                    Remove
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <p v-if="wbData.wikidataBlocklist?.nodes.length === 0" class="has-text-centered has-text-grey py-4">
          No entries in the Wikidata blocklist.
        </p>
      </template>
    </div>

    <!-- Steam Blocklist tab -->
    <div v-if="activeTab === 'steamBlocklist'">
      <div class="mb-4">
        <form class="field is-grouped" @submit.prevent="addSteamBlocklistEntry">
          <div class="control">
            <input v-model="newSteamName" class="input" type="text" placeholder="Game name" required />
          </div>
          <div class="control">
            <input
              v-model.number="newSteamAppId"
              class="input"
              type="number"
              placeholder="Steam App ID"
              required
              min="1"
            />
          </div>
          <div class="control">
            <button class="button is-primary" type="submit">Add to blocklist</button>
          </div>
        </form>
      </div>

      <div v-if="sbLoading" class="has-text-centered py-6">Loading...</div>
      <div v-if="sbError" class="notification is-danger">{{ sbError.message }}</div>

      <template v-if="sbData">
        <div class="table-container">
          <table class="table is-fullwidth is-striped">
            <thead>
              <tr>
                <th>Steam App ID</th>
                <th>Game Name</th>
                <th>Created by</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="entry in sbData.steamBlocklist?.nodes" :key="entry.id">
                <td>
                  <a
                    :href="`https://store.steampowered.com/app/${entry.steamAppId}`"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    {{ entry.steamAppId }}
                  </a>
                </td>
                <td>{{ entry.name }}</td>
                <td>
                  <router-link v-if="entry.user" :to="`/users/${entry.user.slug}`">
                    {{ entry.user.username }}
                  </router-link>
                </td>
                <td>
                  <button class="button is-small is-danger is-outlined" @click="removeFromSteamBlocklist(entry.id)">
                    Remove
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <p v-if="sbData.steamBlocklist?.nodes.length === 0" class="has-text-centered has-text-grey py-4">
          No entries in the Steam blocklist.
        </p>
      </template>
    </div>

    <!-- Unmatched Games tab -->
    <div v-if="activeTab === 'unmatchedGames'">
      <div v-if="ugLoading" class="has-text-centered py-6">Loading...</div>
      <div v-if="ugError" class="notification is-danger">{{ ugError.message }}</div>

      <template v-if="ugData">
        <div class="table-container">
          <table class="table is-fullwidth is-striped is-narrow">
            <thead>
              <tr>
                <th>Count</th>
                <th>Service</th>
                <th>Service ID</th>
                <th>Game Name</th>
                <th>Wikidata</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="game in ugData.groupedUnmatchedGames?.nodes" :key="game.externalServiceId">
                <td>{{ game.count }}</td>
                <td>{{ game.externalServiceName }}</td>
                <td>
                  <a
                    v-if="game.externalServiceName === 'STEAM'"
                    :href="`https://store.steampowered.com/app/${game.externalServiceId}`"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    {{ game.externalServiceId }}
                  </a>
                  <template v-else>{{ game.externalServiceId }}</template>
                </td>
                <td>{{ game.name }}</td>
                <td>
                  <a
                    :href="`https://www.wikidata.org/w/index.php?search=${encodeURIComponent(game.name)}`"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="mr-2"
                  >
                    Search
                  </a>
                  <a
                    :href="`https://www.wikidata.org/w/index.php?title=Special:NewItem&label=${encodeURIComponent(game.name)}&description=video+game`"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    Create
                  </a>
                </td>
                <td>
                  <button
                    class="button is-small is-danger is-outlined"
                    @click="removeUnmatchedGame(game.externalServiceId, game.externalServiceName)"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <p v-if="ugData.groupedUnmatchedGames?.nodes.length === 0" class="has-text-centered has-text-grey py-4">
          No unmatched games.
        </p>
      </template>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, ref } from "vue";
import { useQuery } from "@/composables/useGraphQL";
import { useSnackbar } from "@/composables/useSnackbar";
import { gqlClient } from "@/graphql/client";
import {
  GET_LIVE_STATISTICS,
  GET_STEAM_BLOCKLIST,
  GET_WIKIDATA_BLOCKLIST,
  GET_UNMATCHED_GAMES
} from "@/graphql/queries/admin";
import {
  ADD_TO_STEAM_BLOCKLIST,
  REMOVE_FROM_STEAM_BLOCKLIST,
  REMOVE_FROM_WIKIDATA_BLOCKLIST,
  REMOVE_FROM_UNMATCHED_GAMES
} from "@/graphql/mutations/admin";
import { extractGqlError } from "@/utils/graphql-errors";
import type {
  GetLiveStatisticsQuery,
  GetSteamBlocklistQuery,
  GetWikidataBlocklistQuery,
  GetUnmatchedGamesQuery
} from "@/types/graphql";

const { show: showSnackbar } = useSnackbar();
const activeTab = ref("dashboard");

// Dashboard
const {
  data: statsData,
  loading: statsLoading,
  error: statsError
} = useQuery<GetLiveStatisticsQuery>(GET_LIVE_STATISTICS);
const stats = computed(() => statsData.value?.liveStatistics ?? null);

const coreStats = computed(() => {
  if (!stats.value) return [];
  return [
    { label: "Users", value: stats.value.users },
    { label: "Games", value: stats.value.games },
    { label: "Platforms", value: stats.value.platforms },
    { label: "Series", value: stats.value.series },
    { label: "Engines", value: stats.value.engines },
    { label: "Companies", value: stats.value.companies },
    { label: "Genres", value: stats.value.genres },
    { label: "Stores", value: stats.value.stores },
    { label: "Events", value: stats.value.events },
    { label: "Game Purchases", value: stats.value.gamePurchases },
    { label: "Relationships", value: stats.value.relationships },
    { label: "Banned Users", value: stats.value.bannedUsers },
    { label: "Games with Covers", value: stats.value.gamesWithCovers },
    { label: "Games with Release Dates", value: stats.value.gamesWithReleaseDates }
  ];
});

const externalIdStats = computed(() => {
  if (!stats.value) return [];
  return [
    { label: "MobyGames", value: stats.value.mobygamesIds },
    { label: "PCGamingWiki", value: stats.value.pcgamingwikiIds },
    { label: "Wikidata", value: stats.value.wikidataIds },
    { label: "GiantBomb", value: stats.value.giantbombIds },
    { label: "Steam", value: stats.value.steamAppIds },
    { label: "Epic Games Store", value: stats.value.epicGamesStoreIds },
    { label: "GOG", value: stats.value.gogIds },
    { label: "IGDB", value: stats.value.igdbIds ?? 0 }
  ];
});

// Wikidata Blocklist
const {
  data: wbData,
  loading: wbLoading,
  error: wbError,
  refetch: wbRefetch
} = useQuery<GetWikidataBlocklistQuery>(GET_WIKIDATA_BLOCKLIST, { variables: { first: 50 } });

async function removeFromWikidataBlocklist(id: string) {
  try {
    await gqlClient.request(REMOVE_FROM_WIKIDATA_BLOCKLIST, { wikidataBlocklistEntryId: id });
    showSnackbar("Removed from Wikidata blocklist.");
    wbRefetch();
  } catch (err) {
    showSnackbar(extractGqlError(err), "error");
  }
}

// Steam Blocklist
const {
  data: sbData,
  loading: sbLoading,
  error: sbError,
  refetch: sbRefetch
} = useQuery<GetSteamBlocklistQuery>(GET_STEAM_BLOCKLIST, { variables: { first: 50 } });

const newSteamName = ref("");
const newSteamAppId = ref<number | undefined>(undefined);

async function addSteamBlocklistEntry() {
  if (!newSteamName.value || !newSteamAppId.value) return;
  try {
    await gqlClient.request(ADD_TO_STEAM_BLOCKLIST, {
      name: newSteamName.value,
      steamAppId: newSteamAppId.value
    });
    showSnackbar("Added to Steam blocklist.");
    newSteamName.value = "";
    newSteamAppId.value = undefined;
    sbRefetch();
  } catch (err) {
    showSnackbar(extractGqlError(err), "error");
  }
}

async function removeFromSteamBlocklist(id: string) {
  try {
    await gqlClient.request(REMOVE_FROM_STEAM_BLOCKLIST, { steamBlocklistEntryId: id });
    showSnackbar("Removed from Steam blocklist.");
    sbRefetch();
  } catch (err) {
    showSnackbar(extractGqlError(err), "error");
  }
}

// Unmatched Games
const {
  data: ugData,
  loading: ugLoading,
  error: ugError,
  refetch: ugRefetch
} = useQuery<GetUnmatchedGamesQuery>(GET_UNMATCHED_GAMES, { variables: { first: 50 } });

async function removeUnmatchedGame(externalServiceId: string, externalServiceName: string) {
  try {
    await gqlClient.request(REMOVE_FROM_UNMATCHED_GAMES, { externalServiceId, externalServiceName });
    showSnackbar("Unmatched game removed.");
    ugRefetch();
  } catch (err) {
    showSnackbar(extractGqlError(err), "error");
  }
}
</script>
