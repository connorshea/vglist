<template>
  <section class="section">
    <h1 class="title">Users</h1>

    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>{{ error.message }}</p>
    </div>

    <div v-if="users.length" class="columns is-multiline">
      <div v-for="user in users" :key="user.id" class="column is-3">
        <div class="card">
          <div class="card-content has-text-centered">
            <figure class="image is-96x96 is-inline-block mb-3">
              <img
                v-if="user.avatarUrl"
                class="is-rounded"
                :src="user.avatarUrl"
                :alt="user.username"
              />
              <img
                v-else
                class="is-rounded"
                src="https://via.placeholder.com/96"
                :alt="user.username"
              />
            </figure>
            <p class="title is-5">
              <router-link :to="`/users/${user.id}`">{{ user.username }}</router-link>
            </p>
            <p class="subtitle is-6 has-text-grey">{{ user.gamePurchases.totalCount }} games</p>
          </div>
        </div>
      </div>
    </div>

    <div v-if="hasNextPage" class="has-text-centered mt-5">
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
import { computed } from "vue";
import { useQuery } from "@/composables/useGraphQL";
import { GET_USERS } from "@/graphql/queries/users";
import type { GetUsersQuery } from "@/types/graphql";

const { data, loading, error, fetchMore } = useQuery<GetUsersQuery>(GET_USERS, {
  variables: { first: 20 }
});

const users = computed(() => data.value?.users?.nodes ?? []);
const hasNextPage = computed(() => data.value?.users?.pageInfo?.hasNextPage ?? false);
const endCursor = computed(() => data.value?.users?.pageInfo?.endCursor ?? null);

function loadMore() {
  fetchMore({ first: 20, after: endCursor.value }, (prev, next) => ({
    users: {
      ...next.users,
      nodes: [...prev.users.nodes, ...next.users.nodes]
    }
  }));
}
</script>
