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
        <UserCard :id="user.id" :username="user.username" :avatar-url="user.avatarUrl" :size="96">
          <p class="subtitle is-6 has-text-grey">{{ user.gamePurchases.totalCount }} games</p>
        </UserCard>
      </div>
    </div>

    <PaginationNav
      v-if="data && (currentPage > 1 || hasNextPage)"
      :current-page="currentPage"
      :has-next-page="hasNextPage"
      :loading="loading"
      @prev="prevPage"
      @next="nextPage"
    />
  </section>
</template>

<script setup lang="ts">
import { ref, watch, computed } from "vue";
import { useQuery } from "@/composables/useGraphQL";
import { GET_USERS } from "@/graphql/queries/users";
import type { GetUsersQuery } from "@/types/graphql";
import PaginationNav from "@/components/PaginationNav.vue";
import UserCard from "@/components/UserCard.vue";

const PAGE_SIZE = 20;
const currentPage = ref(1);
const pageCursors = ref<(string | null)[]>([null]);

const { data, loading, error } = useQuery<GetUsersQuery>(GET_USERS, {
  variables: () => ({
    first: PAGE_SIZE,
    after: pageCursors.value[currentPage.value - 1]
  })
});

const users = computed(() => data.value?.users?.nodes ?? []);
const hasNextPage = computed(() => data.value?.users?.pageInfo?.hasNextPage ?? false);

watch(data, (val) => {
  if (val?.users?.pageInfo?.endCursor) {
    pageCursors.value[currentPage.value] = val.users.pageInfo.endCursor;
  }
});

function nextPage() {
  if (hasNextPage.value) currentPage.value++;
}

function prevPage() {
  if (currentPage.value > 1) currentPage.value--;
}
</script>
