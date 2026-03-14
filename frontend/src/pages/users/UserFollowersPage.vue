<template>
  <section class="section">
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>{{ error.message }}</p>
    </div>

    <div v-if="user">
      <h1 class="title">
        <router-link :to="`/users/${route.params.id}`">{{ user.username }}</router-link>
        &rsaquo; Followers
      </h1>

      <p class="subtitle is-6 has-text-grey">{{ user.followers.totalCount }} followers</p>

      <div v-if="!followerUsers.length" class="notification is-light">
        <p>No followers yet.</p>
      </div>

      <div class="columns is-multiline">
        <div v-for="follower in followerUsers" :key="follower.id" class="column is-3">
          <div class="box has-text-centered">
            <figure class="image is-64x64 is-inline-block mb-2">
              <img
                v-if="follower.avatarUrl"
                class="is-rounded"
                :src="follower.avatarUrl"
                :alt="follower.username"
              />
              <img
                v-else
                class="is-rounded"
                src="https://via.placeholder.com/64"
                :alt="follower.username"
              />
            </figure>
            <p>
              <router-link :to="`/users/${follower.id}`">{{ follower.username }}</router-link>
            </p>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useRoute } from "vue-router";
import { useQuery } from "@/composables/useGraphQL";
import { GET_USER } from "@/graphql/queries/users";
import type { GetUserQuery } from "@/types/graphql";

const route = useRoute();

const { data, loading, error } = useQuery<GetUserQuery>(GET_USER, {
  variables: () => ({ id: route.params.id as string })
});

const user = computed(() => data.value?.user ?? null);
const followerUsers = computed(() => user.value?.followers?.nodes ?? []);
</script>
