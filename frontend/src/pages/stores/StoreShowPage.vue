<template>
  <section class="section">
    <div v-if="loading && !result" class="has-text-centered">
      <p>Loading store...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load store: {{ error.message }}</p>
    </div>

    <div v-if="result">
      <h1 class="title">{{ result.store.name }}</h1>
    </div>
  </section>
</template>

<script setup lang="ts">
import { useRoute } from 'vue-router'
import { useQuery } from '@vue/apollo-composable'
import { GET_STORE } from '@/graphql/queries/resources'

const route = useRoute()

const { result, loading, error } = useQuery(GET_STORE, {
  id: route.params.id,
})
</script>
