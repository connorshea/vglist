<template>
  <section class="section">
    <h1 class="title">Companies</h1>

    <div v-if="loading && !result" class="has-text-centered">
      <p>Loading companies...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load companies: {{ error.message }}</p>
    </div>

    <div v-if="result" class="content">
      <ul>
        <li v-for="company in result.companies.nodes" :key="company.id">
          <router-link :to="`/companies/${company.id}`">{{ company.name }}</router-link>
        </li>
      </ul>
    </div>

    <div
      v-if="result?.companies.pageInfo.hasNextPage"
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
import { useQuery } from '@vue/apollo-composable'
import { GET_COMPANIES } from '@/graphql/queries/resources'

const { result, loading, error, fetchMore } = useQuery(GET_COMPANIES, {
  first: 25,
})

function loadMore() {
  fetchMore({
    variables: {
      first: 25,
      after: result.value.companies.pageInfo.endCursor,
    },
    updateQuery(previousResult, { fetchMoreResult }) {
      if (!fetchMoreResult) return previousResult

      return {
        companies: {
          ...fetchMoreResult.companies,
          nodes: [
            ...previousResult.companies.nodes,
            ...fetchMoreResult.companies.nodes,
          ],
        },
      }
    },
  })
}
</script>
