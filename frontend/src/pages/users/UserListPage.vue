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

    <p class="is-sr-only" role="status">{{ showSkeleton ? "Loading users…" : "" }}</p>

    <div v-if="showSkeleton" class="users-grid" aria-hidden="true">
      <UserCardSkeleton v-for="card in SKELETON_CARDS" :key="card" :name-width="skeletonNameWidth(card)" />
    </div>

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
import { computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useQuery } from "@/composables/useGraphQL";
import { useCursorPages, withoutPage } from "@/composables/useCursorPages";
import { GET_USERS } from "@/graphql/queries/users";
import type { GetUsersQuery, UserSort } from "@/types/graphql";
import PaginationNav from "@/components/PaginationNav.vue";
import UserCard from "@/components/UserCard.vue";
import UserCardSkeleton from "@/components/UserCardSkeleton.vue";

const sortOptions: { label: string; value: UserSort | null; slug: string | null }[] = [
  { label: "A–Z", value: null, slug: null },
  { label: "Most games", value: "MOST_GAMES", slug: "most-games" },
  { label: "Most followers", value: "MOST_FOLLOWERS", slug: "most-followers" }
];

const PAGE_SIZE = 20;
const route = useRoute();
const router = useRouter();

// The sort and page live in the query string, so Back and Forward return to
// them and a sorted list can be linked to.
const currentSort = computed(
  () => sortOptions.find((o) => o.slug !== null && o.slug === route.query.sort)?.value ?? null
);
const {
  currentPage,
  variables: pageVariables,
  nextPage: goToNextPage,
  prevPage: goToPrevPage
} = useCursorPages(PAGE_SIZE);

const { data, loading, error } = useQuery<GetUsersQuery>(GET_USERS, {
  variables: () => ({
    ...pageVariables.value,
    sortBy: currentSort.value
  })
});

const users = computed(() => data.value?.users?.nodes ?? []);
const hasNextPage = computed(() => data.value?.users?.pageInfo?.hasNextPage ?? false);
const totalCount = computed(() => data.value?.users?.totalCount ?? 0);

// ── First load ──
// Placeholder cards until the first page arrives. Later loads (sort, page)
// keep the current cards up until the new ones replace them.
const showSkeleton = computed(() => loading.value && !data.value);
const SKELETON_CARDS = PAGE_SIZE;
const SKELETON_NAME_WIDTHS = ["58%", "42%", "70%", "50%", "64%", "46%"];
function skeletonNameWidth(i: number): string {
  return SKELETON_NAME_WIDTHS[(i - 1) % SKELETON_NAME_WIDTHS.length] ?? "55%";
}

function setSort(sort: UserSort | null) {
  if (sort === currentSort.value) {
    return;
  }
  const slug = sortOptions.find((o) => o.value === sort)?.slug ?? undefined;
  void router.push({ query: { ...withoutPage(route.query), sort: slug } });
}

function nextPage() {
  if (hasNextPage.value) {
    goToNextPage(data.value?.users?.pageInfo?.endCursor);
  }
}

function prevPage() {
  goToPrevPage(data.value?.users?.pageInfo?.startCursor);
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
</style>
