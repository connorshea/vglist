<template>
  <div class="users-page">
    <div class="page-header">
      <h1 class="page-title">Users</h1>
      <span v-if="totalCount > 0" class="user-count">{{ totalCount }} users</span>
    </div>

    <div class="toolbar">
      <div class="sort-group">
        <button
          v-for="option in sortOptions"
          :key="option.value ?? 'default'"
          class="sort-btn"
          :class="{ active: currentSort === option.value }"
          @click="setSort(option.value)"
        >
          {{ option.label }}
        </button>
      </div>
    </div>

    <div v-if="loading && !data" class="loading-state">Loading...</div>

    <div v-if="error" class="notification is-danger">
      <p>{{ error.message }}</p>
    </div>

    <div v-if="users.length" class="users-grid">
      <UserCard
        v-for="user in users"
        :key="user.id"
        :slug="user.slug"
        :username="user.username"
        :avatar-url="user.avatarUrl"
        :role="user.role"
        :privacy="user.privacy"
        :banned="user.banned"
        :game-count="user.gamePurchases.totalCount"
        :joined-date="user.createdAt"
      />
    </div>

    <PaginationNav
      v-if="data && (currentPage > 1 || hasNextPage)"
      :current-page="currentPage"
      :has-next-page="hasNextPage"
      :loading="loading"
      @prev="prevPage"
      @next="nextPage"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, watch, computed } from "vue";
import { useQuery } from "@/composables/useGraphQL";
import { GET_USERS } from "@/graphql/queries/users";
import type { GetUsersQuery, UserSort } from "@/types/graphql";
import PaginationNav from "@/components/PaginationNav.vue";
import UserCard from "@/components/UserCard.vue";

const sortOptions: { label: string; value: UserSort | null }[] = [
  { label: "A\u2013Z", value: null },
  { label: "Most games", value: "MOST_GAMES" },
  { label: "Most followers", value: "MOST_FOLLOWERS" }
];

const PAGE_SIZE = 20;
const currentPage = ref(1);
const currentSort = ref<UserSort | null>(null);
const pageCursors = ref<(string | null)[]>([null]);

const { data, loading, error } = useQuery<GetUsersQuery>(GET_USERS, {
  variables: () => ({
    first: PAGE_SIZE,
    after: pageCursors.value[currentPage.value - 1],
    sortBy: currentSort.value
  })
});

const users = computed(() => data.value?.users?.nodes ?? []);
const hasNextPage = computed(() => data.value?.users?.pageInfo?.hasNextPage ?? false);
const totalCount = computed(() => data.value?.users?.totalCount ?? 0);

watch(data, (val) => {
  if (val?.users?.pageInfo?.endCursor) {
    pageCursors.value[currentPage.value] = val.users.pageInfo.endCursor;
  }
});

function setSort(sort: UserSort | null) {
  currentSort.value = sort;
  currentPage.value = 1;
  pageCursors.value = [null];
}

function nextPage() {
  if (hasNextPage.value) currentPage.value++;
}

function prevPage() {
  if (currentPage.value > 1) currentPage.value--;
}
</script>

<style scoped>
.users-page {
}

/* Header */
.page-header {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  margin-bottom: 8px;
}

.page-title {
  font-size: 24px;
  font-weight: 600;
  color: var(--color-text-primary);
  letter-spacing: -0.3px;
}

.user-count {
  font-size: 13px;
  color: var(--color-text-secondary);
}

/* Toolbar */
.toolbar {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.sort-group {
  display: flex;
  align-items: center;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  overflow: hidden;
  width: fit-content;
}

.sort-btn {
  font-size: 11px;
  padding: 6px 12px;
  border: none;
  background: transparent;
  color: var(--color-text-secondary);
  transition: all 0.15s;
  white-space: nowrap;
  position: relative;
  cursor: pointer;
  font-family: inherit;
}

.sort-btn:not(:last-child)::after {
  content: "";
  position: absolute;
  right: 0;
  top: 25%;
  height: 50%;
  width: 1px;
  background: var(--color-border);
}

.sort-btn:hover {
  color: var(--color-text-primary);
}

.sort-btn.active {
  background: var(--p-100);
  color: var(--p-500);
  font-weight: 500;
}

/* Grid */
.users-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 12px;
}

@media (max-width: 900px) {
  .users-grid {
    grid-template-columns: repeat(4, 1fr);
  }
}

@media (max-width: 640px) {
  .users-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* Loading */
.loading-state {
  text-align: center;
  padding: 2rem;
  color: var(--color-text-secondary);
}
</style>
