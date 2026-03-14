<template>
  <section class="section">
    <h1 class="title">Series</h1>

    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading series...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load series: {{ error.message }}</p>
    </div>

    <div v-if="data" class="content">
      <ul>
        <li v-for="s in data.seriesList.nodes" :key="s.id">
          <router-link :to="`/series/${s.id}`">{{ s.name }}</router-link>
        </li>
      </ul>
    </div>

    <div v-if="data?.seriesList.pageInfo.hasNextPage" class="has-text-centered mt-5">
      <button
        class="button is-primary"
        :class="{ 'is-loading': loading }"
        :disabled="loading"
        @click="loadMore"
      >
        Load More
      </button>
    </div>
  </section>
</template>

<script setup lang="ts">
import { useQuery } from "@/composables/useGraphQL";
import { GET_SERIES_LIST } from "@/graphql/queries/resources";
import type { GetSeriesListQuery } from "@/types/graphql";

const { data, loading, error, fetchMore } = useQuery<GetSeriesListQuery>(GET_SERIES_LIST, {
  variables: { first: 25 }
});

function loadMore() {
  if (!data.value) return;

  fetchMore({ first: 25, after: data.value.seriesList.pageInfo.endCursor }, (prev, next) => ({
    seriesList: {
      ...next.seriesList,
      nodes: [...prev.seriesList.nodes, ...next.seriesList.nodes]
    }
  }));
}
</script>
