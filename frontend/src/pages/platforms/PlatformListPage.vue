<template>
  <section class="section">
    <h1 class="title">Platforms</h1>

    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading platforms...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load platforms: {{ error.message }}</p>
    </div>

    <div v-if="data" class="content">
      <ul>
        <li v-for="platform in data.platforms.nodes" :key="platform.id">
          <router-link :to="`/platforms/${platform.id}`">{{ platform.name }}</router-link>
        </li>
      </ul>
    </div>

    <PaginationNav
      v-if="data && (currentPage > 1 || hasNextPage)"
      :current-page="currentPage"
      :has-next-page="hasNextPage"
      :loading="loading"
      @prev="prevPage"
      @next="nextPage"
    />
  </section>
</template>

<script setup lang="ts">
import { ref, watch, computed } from "vue";
import { useQuery } from "@/composables/useGraphQL";
import { GET_PLATFORMS } from "@/graphql/queries/resources";
import type { GetPlatformsQuery } from "@/types/graphql";
import PaginationNav from "@/components/PaginationNav.vue";

const PAGE_SIZE = 25;
const currentPage = ref(1);
const pageCursors = ref<(string | null)[]>([null]);

const { data, loading, error } = useQuery<GetPlatformsQuery>(GET_PLATFORMS, {
  variables: () => ({
    first: PAGE_SIZE,
    after: pageCursors.value[currentPage.value - 1]
  })
});

const hasNextPage = computed(() => data.value?.platforms.pageInfo.hasNextPage ?? false);

watch(data, (val) => {
  if (val?.platforms.pageInfo.endCursor) {
    pageCursors.value[currentPage.value] = val.platforms.pageInfo.endCursor;
  }
});

function nextPage() {
  if (hasNextPage.value) currentPage.value++;
}

function prevPage() {
  if (currentPage.value > 1) currentPage.value--;
}
</script>
