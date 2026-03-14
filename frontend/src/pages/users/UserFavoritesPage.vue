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
        &rsaquo; Favorite Games
      </h1>

      <div v-if="!favoritedGames.length" class="notification is-light">
        <p>No favorite games yet.</p>
      </div>

      <div class="columns is-multiline">
        <div v-for="game in favoritedGames" :key="game.id" class="column is-2">
          <div class="card">
            <div class="card-image">
              <figure class="image is-3by4">
                <img
                  v-if="game.coverUrl"
                  :src="game.coverUrl"
                  :alt="game.name"
                />
                <img
                  v-else
                  src="https://via.placeholder.com/120x160"
                  :alt="game.name"
                />
              </figure>
            </div>
            <div class="card-content p-3">
              <p class="has-text-centered">{{ game.name }}</p>
            </div>
          </div>
        </div>
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
const favoritedGames = computed(() => user.value?.favoritedGames?.nodes ?? [])
</script>
