<template>
  <div>
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

    <StatisticsHistory />
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useQuery } from "@/composables/useGraphQL";
import StatisticsHistory from "@/components/admin/StatisticsHistory.vue";
import { GET_LIVE_STATISTICS } from "@/graphql/queries/admin";
import type { GetLiveStatisticsQuery } from "@/types/graphql";

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
</script>
