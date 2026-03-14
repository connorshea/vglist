<template>
  <section class="section">
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading store...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load store: {{ error.message }}</p>
    </div>

    <div v-if="data">
      <h1 class="title">{{ data.store.name }}</h1>
    </div>
  </section>
</template>

<script setup lang="ts">
import { useRoute } from 'vue-router'
import { useQuery } from '@/composables/useGraphQL'
import { GET_STORE } from '@/graphql/queries/resources'

const route = useRoute()

const { data, loading, error } = useQuery(GET_STORE, {
  variables: { id: route.params.id },
})
</script>
