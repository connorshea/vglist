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
        &rsaquo; Activity
      </h1>

      <div class="notification is-info is-light">
        <p>Activity feed coming soon.</p>
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
</script>
