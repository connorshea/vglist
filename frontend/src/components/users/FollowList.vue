<template>
  <div class="follow-list">
    <nav class="follow-toggle" aria-label="Followers and following">
      <router-link
        :to="{ name: 'userFollowers', params: { slug } }"
        :class="{ 'is-active': kind === 'followers' }"
        :aria-current="kind === 'followers' ? 'page' : undefined"
      >
        Followers <span class="follow-toggle-count">{{ (user?.followers.totalCount ?? 0).toLocaleString() }}</span>
      </router-link>
      <router-link
        :to="{ name: 'userFollowing', params: { slug } }"
        :class="{ 'is-active': kind === 'following' }"
        :aria-current="kind === 'following' ? 'page' : undefined"
      >
        Following <span class="follow-toggle-count">{{ (user?.following.totalCount ?? 0).toLocaleString() }}</span>
      </router-link>
    </nav>

    <div v-if="users.length" class="follow-grid" :aria-busy="loading">
      <UserCard
        v-for="listed in users"
        :key="listed.id"
        :slug="listed.slug"
        :username="listed.username"
        :avatar-url="listed.avatarUrl"
        :size="64"
      />
    </div>
    <div v-else class="follow-empty" role="status">
      <p v-if="loading">Loading…</p>
      <p v-else-if="error">{{ error.message }}</p>
      <p v-else-if="page > 1">
        There's nothing on page {{ page }}.
        <router-link :to="{ query: {} }">Go to the first page</router-link>
      </p>
      <p v-else-if="kind === 'followers'">No followers yet.</p>
      <p v-else>Not following anyone yet.</p>
    </div>

    <p v-if="error && users.length" class="follow-error" role="alert">{{ error.message }}</p>

    <PaginationNav
      v-if="users.length && (page > 1 || hasNextPage)"
      :current-page="page"
      :has-next-page="hasNextPage"
      :loading="loading"
      @prev="emit('goToPage', page - 1)"
      @next="emit('goToPage', page + 1)"
    />
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useUserProfile } from "@/composables/useUserProfile";
import UserCard from "@/components/UserCard.vue";
import PaginationNav from "@/components/PaginationNav.vue";
import type { FollowListUser } from "@/composables/useFollowList";

defineProps<{
  kind: "followers" | "following";
  users: FollowListUser[];
  loading: boolean;
  error: Error | null;
  page: number;
  hasNextPage: boolean;
}>();

const emit = defineEmits<{
  goToPage: [page: number];
}>();

const { user } = useUserProfile();
const slug = computed(() => user.value?.slug ?? "");
</script>

<style scoped>
.follow-list {
  padding-top: 24px;
}

.follow-toggle {
  display: inline-flex;
  gap: 2px;
  margin-bottom: 20px;
  padding: 3px;
  border-radius: 8px;
  background: var(--color-bg-subtle);
}

.follow-toggle a {
  display: inline-flex;
  gap: 6px;
  align-items: center;
  padding: 5px 12px;
  border-radius: 6px;
  color: var(--color-text-secondary);
  font-size: 0.8rem;
  font-weight: 500;
}

.follow-toggle a:hover {
  color: var(--color-text-primary);
}

.follow-toggle a.is-active {
  background: var(--color-surface);
  color: var(--color-text-primary);
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.12);
}

.follow-toggle a:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 1px;
}

.follow-toggle-count {
  color: var(--color-text-tertiary);
  font-size: 0.7rem;
}

.follow-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 12px;
}

.follow-empty {
  padding: 48px 16px;
  color: var(--color-text-secondary);
  text-align: center;
}

.follow-error {
  margin-top: 16px;
  color: var(--color-danger-text);
  text-align: center;
}

@media (max-width: 768px) {
  .follow-list {
    padding-top: 16px;
  }

  .follow-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 8px;
  }
}
</style>
