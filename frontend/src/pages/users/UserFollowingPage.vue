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
        <router-link :to="`/users/${route.params.slug}`">{{ user.username }}</router-link>
        &rsaquo; Following
      </h1>

      <p class="subtitle is-6 has-text-grey">{{ user.following.totalCount }} users</p>

      <div v-if="!followingUsers.length" class="notification is-light">
        <p>Not following anyone yet.</p>
      </div>

      <div class="columns is-multiline">
        <div v-for="followed in followingUsers" :key="followed.id" class="column is-3">
          <UserCard
            :slug="followed.slug"
            :username="followed.username"
            :avatar-url="followed.avatarUrl"
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
  variables: () => ({ slug: route.params.slug as string })
});

const user = computed(() => data.value?.user ?? null);
const followingUsers = computed(() => user.value?.following?.nodes ?? []);
</script>
