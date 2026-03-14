<template>
  <section class="section">
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>{{ error.message }}</p>
    </div>

    <div v-if="user">
      <!-- Profile Header -->
      <div class="columns">
        <div class="column is-narrow">
          <figure class="image is-128x128">
            <img
              v-if="user.avatarUrl"
              class="is-rounded"
              :src="user.avatarUrl"
              :alt="user.username"
            />
            <img
              v-else
              class="is-rounded"
              src="https://via.placeholder.com/128"
              :alt="user.username"
            />
          </figure>
        </div>
        <div class="column">
          <div class="is-flex is-align-items-center mb-2">
            <h1 class="title mb-0 mr-3">{{ user.username }}</h1>
            <span v-if="user.role === 'admin'" class="tag is-danger">Admin</span>
            <span v-else-if="user.role === 'moderator'" class="tag is-warning">Moderator</span>
          </div>

          <p v-if="user.bio" class="subtitle is-6 has-text-grey">{{ user.bio }}</p>

          <div class="buttons" v-if="canFollowOrUnfollow">
            <button
              v-if="user.isFollowed"
              class="button is-light"
              :class="{ 'is-loading': unfollowLoading }"
              @click="handleUnfollow"
            >
              Unfollow
            </button>
            <button
              v-else
              class="button is-primary"
              :class="{ 'is-loading': followLoading }"
              @click="handleFollow"
            >
              Follow
            </button>
          </div>

          <nav class="level is-mobile mt-4">
            <div class="level-item has-text-centered">
              <div>
                <p class="heading">Followers</p>
                <p class="title is-5">
                  <router-link :to="`/users/${route.params.id}/followers`">
                    {{ user.followers.totalCount }}
                  </router-link>
                </p>
              </div>
            </div>
            <div class="level-item has-text-centered">
              <div>
                <p class="heading">Following</p>
                <p class="title is-5">
                  <router-link :to="`/users/${route.params.id}/following`">
                    {{ user.following.totalCount }}
                  </router-link>
                </p>
              </div>
            </div>
          </nav>
        </div>
      </div>

      <!-- Favorited Games -->
      <div v-if="favoritedGames.length" class="mb-6">
        <h2 class="title is-4">
          <router-link :to="`/users/${route.params.id}/favorites`">Favorite Games</router-link>
        </h2>
        <div class="columns is-multiline">
          <div v-for="game in favoritedGames" :key="game.id" class="column is-narrow">
            <div class="card" style="width: 120px;">
              <div class="card-image">
                <figure class="image is-3by4">
                  <img
                    v-if="game.coverUrl"
                    :src="game.coverUrl"
                    :alt="game.name"
                  />
                  <img
                    v-else
                    src="https://via.placeholder.com/90x120"
                    :alt="game.name"
                  />
                </figure>
              </div>
              <div class="card-content p-2">
                <p class="is-size-7 has-text-centered">{{ game.name }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Game Library -->
      <div>
        <h2 class="title is-4">Game Library</h2>

        <div v-if="!gamePurchases.length" class="notification is-light">
          <p>No games in library yet.</p>
        </div>

        <div class="columns is-multiline">
          <div v-for="purchase in gamePurchases" :key="purchase.id" class="column is-6">
            <div class="box">
              <article class="media">
                <div class="media-left">
                  <figure class="image is-64x64">
                    <img
                      v-if="purchase.game.coverUrl"
                      :src="purchase.game.coverUrl"
                      :alt="purchase.game.name"
                    />
                    <img
                      v-else
                      src="https://via.placeholder.com/64"
                      :alt="purchase.game.name"
                    />
                  </figure>
                </div>
                <div class="media-content">
                  <p class="title is-5">{{ purchase.game.name }}</p>
                  <p class="subtitle is-6 has-text-grey">
                    <span v-if="purchase.rating !== null">
                      Rating: {{ purchase.rating }}/100
                    </span>
                    <span v-if="purchase.completionStatus" class="ml-3">
                      {{ formatStatus(purchase.completionStatus) }}
                    </span>
                    <span v-if="purchase.hoursPlayed !== null" class="ml-3">
                      {{ purchase.hoursPlayed }}h played
                    </span>
                  </p>
                </div>
              </article>
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
import { useQuery, useMutation } from '@/composables/useGraphQL'
import { useAuthStore } from '@/stores/auth'
import { GET_USER } from '@/graphql/queries/users'
import { FOLLOW_USER, UNFOLLOW_USER } from '@/graphql/mutations/users'

const route = useRoute()
const authStore = useAuthStore()

const { data, loading, error, refetch } = useQuery(GET_USER, {
  variables: () => ({ id: route.params.id as string }),
})

const user = computed(() => data.value?.user ?? null)
const gamePurchases = computed(() => user.value?.gamePurchases?.nodes ?? [])
const favoritedGames = computed(() => user.value?.favoritedGames?.nodes ?? [])

const canFollowOrUnfollow = computed(() => {
  return authStore.isAuthenticated && user.value && authStore.user?.id !== user.value.id
})

const { mutate: followUser, loading: followLoading } = useMutation(FOLLOW_USER)
const { mutate: unfollowUser, loading: unfollowLoading } = useMutation(UNFOLLOW_USER)

async function handleFollow() {
  await followUser({ userId: route.params.id as string })
  await refetch()
}

async function handleUnfollow() {
  await unfollowUser({ userId: route.params.id as string })
  await refetch()
}

function formatStatus(status: string): string {
  return status.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())
}
</script>
