<template>
  <section class="section">
    <h1 class="title">Companies</h1>

    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading companies...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load companies: {{ error.message }}</p>
    </div>

    <div v-if="data" class="content">
      <ul>
        <li v-for="company in data.companies.nodes" :key="company.id">
          <router-link :to="`/companies/${company.id}`">{{ company.name }}</router-link>
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
import { GET_COMPANIES } from "@/graphql/queries/resources";
import type { GetCompaniesQuery } from "@/types/graphql";
import PaginationNav from "@/components/PaginationNav.vue";

const PAGE_SIZE = 25;
const currentPage = ref(1);
const pageCursors = ref<(string | null)[]>([null]);

const { data, loading, error } = useQuery<GetCompaniesQuery>(GET_COMPANIES, {
  variables: () => ({
    first: PAGE_SIZE,
    after: pageCursors.value[currentPage.value - 1],
  }),
});

const hasNextPage = computed(() => data.value?.companies.pageInfo.hasNextPage ?? false);

watch(data, (val) => {
  if (val?.companies.pageInfo.endCursor) {
    pageCursors.value[currentPage.value] = val.companies.pageInfo.endCursor;
  }
});

function nextPage() {
  if (hasNextPage.value) currentPage.value++;
}

function prevPage() {
  if (currentPage.value > 1) currentPage.value--;
}
</script>
