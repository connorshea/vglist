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

    <div
      v-if="data?.companies.pageInfo.hasNextPage"
      class="has-text-centered mt-5"
    >
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
import { useQuery } from '@/composables/useGraphQL'
import { GET_COMPANIES } from '@/graphql/queries/resources'
import type { GetCompaniesQuery } from '@/types/graphql'

const { data, loading, error, fetchMore } = useQuery<GetCompaniesQuery>(GET_COMPANIES, {
  variables: { first: 25 },
})

function loadMore() {
  if (!data.value) return

  fetchMore(
    { first: 25, after: data.value.companies.pageInfo.endCursor },
    (prev, next) => ({
      companies: {
        ...next.companies,
        nodes: [...prev.companies.nodes, ...next.companies.nodes],
      },
    }),
  )
}
</script>
