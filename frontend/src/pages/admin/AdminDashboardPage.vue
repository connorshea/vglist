<template>
  <div class="admin-dashboard">
    <div v-if="statsLoading" class="has-text-centered py-6">Loading statistics...</div>
    <div v-if="statsError" class="notification is-danger">{{ statsError.message }}</div>

    <template v-if="stats">
      <StatisticsOverview :stats="stats" :history="trendHistory" />
      <p v-if="trendError" class="trend-error">Trends couldn't be loaded: {{ trendError.message }}</p>
      <DataCoverage :stats="stats" />
    </template>

    <StatisticsHistory />
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useQuery } from "@/composables/useGraphQL";
import DataCoverage from "@/components/admin/DataCoverage.vue";
import StatisticsHistory from "@/components/admin/StatisticsHistory.vue";
import StatisticsOverview from "@/components/admin/StatisticsOverview.vue";
import { GET_LIVE_STATISTICS, GET_SITE_STATISTICS } from "@/graphql/queries/admin";
import type { GetLiveStatisticsQuery, GetSiteStatisticsQuery } from "@/types/graphql";

// The longest trend range is 90 days, so one snapshot more than that covers
// its baseline. Also within the API's 100-per-page limit.
const TREND_SNAPSHOTS = 91;

const {
  data: statsData,
  loading: statsLoading,
  error: statsError
} = useQuery<GetLiveStatisticsQuery>(GET_LIVE_STATISTICS);
const stats = computed(() => statsData.value?.liveStatistics ?? null);

const { data: trendData, error: trendError } = useQuery<GetSiteStatisticsQuery>(GET_SITE_STATISTICS, {
  variables: { first: TREND_SNAPSHOTS }
});
const trendHistory = computed(() => trendData.value?.siteStatistics?.nodes ?? []);
</script>

<style scoped>
.trend-error {
  margin: -24px 0 24px;
  font-size: 0.8125rem;
  color: var(--color-text-secondary);
}
</style>

<style>
/*
  Shared by the dashboard's sections, which all render inside .admin-dashboard.
  Kept unscoped (but namespaced) so each section doesn't repeat it.
*/
.admin-dashboard {
  --admin-up: #17703f;
  --admin-spark: var(--p-500);
  --admin-track: var(--color-bg-subtle);
  --admin-low: #c76a12;
}

@media (prefers-color-scheme: dark) {
  .admin-dashboard {
    --admin-up: #7fdca4;
    --admin-spark: var(--p-300);
    --admin-track: var(--s-500);
    --admin-low: #e8a053;
  }
}

.admin-dashboard .admin-section {
  margin-bottom: 2.25rem;
}

.admin-dashboard .admin-section-header {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
  margin-bottom: 0.875rem;
}

.admin-dashboard .admin-section-title {
  margin: 0;
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

.admin-dashboard .admin-section-note {
  margin-left: 8px;
  font-size: 0.8125rem;
  font-weight: 400;
  color: var(--color-text-secondary);
}
</style>
