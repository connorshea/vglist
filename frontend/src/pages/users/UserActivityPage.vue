<template>
  <section class="section">
    <div v-if="loading && !result" class="has-text-centered">
      <p>Loading...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>{{ error.message }}</p>
    </div>

    <div v-if="user">
      <h1 class="title">
        <router-link :to="`/users/${route.params.id}`">{{ user.username }}</router-link>
        &rsaquo; Activity
      </h1>

      <div class="notification is-info is-light">
        <p>Activity feed coming soon.</p>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useQuery } from '@vue/apollo-composable'
import { GET_USER } from '@/graphql/queries/users'

const route = useRoute()

const { result, loading, error } = useQuery(GET_USER, () => ({
  id: route.params.id as string,
}))

const user = computed(() => result.value?.user ?? null)
</script>
