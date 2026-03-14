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
          <UserCard
            :id="follower.id"
            :username="follower.username"
            :avatar-url="follower.avatarUrl"
            :size="64"
          />
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
import UserCard from "@/components/UserCard.vue";

const route = useRoute();

const { data, loading, error } = useQuery<GetUserQuery>(GET_USER, {
  variables: () => ({ id: route.params.id as string })
});

const user = computed(() => data.value?.user ?? null);
const followerUsers = computed(() => user.value?.followers?.nodes ?? []);
</script>
