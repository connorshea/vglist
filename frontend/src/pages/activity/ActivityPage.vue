<template>
  <section class="section">
    <h1 class="title">Activity</h1>

    <div class="tabs">
      <ul>
        <li :class="{ 'is-active': feedType === 'GLOBAL' }">
          <a @click="switchFeed('GLOBAL')">Global</a>
        </li>
        <li v-if="authStore.isAuthenticated" :class="{ 'is-active': feedType === 'FOLLOWING' }">
          <a @click="switchFeed('FOLLOWING')">Following</a>
        </li>
      </ul>
    </div>

    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading activity...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load activity: {{ error.message }}</p>
    </div>

    <div v-if="data">
      <div
        v-if="data.activity && data.activity.nodes.length === 0"
        class="has-text-centered has-text-grey py-6"
      >
        <p>No activity yet.</p>
      </div>

      <div v-for="event in data?.activity?.nodes" :key="event.id" class="box">
        <article class="media">
          <figure class="media-left">
            <p class="image is-48x48">
              <img
                v-if="event.user.avatarUrl"
                class="is-rounded"
                :src="event.user.avatarUrl"
                :alt="event.user.username"
              />
              <span v-else class="activity-avatar-placeholder is-rounded">
                {{ event.user.username.charAt(0).toUpperCase() }}
              </span>
            </p>
          </figure>
          <div class="media-content">
            <div class="content">
              <p>
                <strong>
                  <router-link :to="`/users/${event.user.slug}`">
                    {{ event.user.username }}
                  </router-link>
                </strong>
                {{ " " }}
                <template
                  v-if="event.eventCategory === 'ADD_TO_LIBRARY' && 'game' in event.eventable"
                >
                  added
                  <router-link :to="`/games/${event.eventable.game.id}`">
                    {{ event.eventable.game.name }}
                  </router-link>
                  to their library
                </template>
                <template
                  v-else-if="
                    event.eventCategory === 'CHANGE_COMPLETION_STATUS' && 'game' in event.eventable
                  "
                >
                  changed the completion status of
                  <router-link :to="`/games/${event.eventable.game.id}`">
                    {{ event.eventable.game.name }}
                  </router-link>
                  <template
                    v-if="'completionStatus' in event.eventable && event.eventable.completionStatus"
                  >
                    to {{ completionStatusLabel(event.eventable.completionStatus) }}
                  </template>
                </template>
                <template
                  v-else-if="event.eventCategory === 'FAVORITE_GAME' && 'game' in event.eventable"
                >
                  favorited
                  <router-link :to="`/games/${event.eventable.game.id}`">
                    {{ event.eventable.game.name }}
                  </router-link>
                </template>
                <template
                  v-else-if="event.eventCategory === 'FOLLOWING' && 'followed' in event.eventable"
                >
                  started following
                  <router-link :to="`/users/${event.eventable.followed.slug}`">
                    {{ event.eventable.followed.username }}
                  </router-link>
                </template>
                <template v-else-if="event.eventCategory === 'NEW_USER'"> joined vglist </template>
                <br />
                <small class="has-text-grey">{{
                  new Date(event.createdAt).toLocaleString()
                }}</small>
              </p>
            </div>
          </div>
        </article>
      </div>

      <PaginationNav
        v-if="currentPage > 1 || hasNextPage"
        :current-page="currentPage"
        :has-next-page="hasNextPage"
        :loading="loading"
        @prev="prevPage"
        @next="nextPage"
      />
    </div>
  </section>
</template>

<script setup lang="ts">
import { ref, watch, computed } from "vue";
import { useQuery } from "@/composables/useGraphQL";
import { GET_ACTIVITY } from "@/graphql/queries/resources";
import type { GetActivityQuery, GamePurchaseCompletionStatus } from "@/types/graphql";
import PaginationNav from "@/components/PaginationNav.vue";
import { useAuthStore } from "@/stores/auth";

const authStore = useAuthStore();

const PAGE_SIZE = 25;
const feedType = ref<"GLOBAL" | "FOLLOWING">("GLOBAL");
const currentPage = ref(1);
const pageCursors = ref<(string | null)[]>([null]);

const { data, loading, error } = useQuery<GetActivityQuery>(GET_ACTIVITY, {
  variables: () => ({
    feedType: feedType.value,
    first: PAGE_SIZE,
    after: pageCursors.value[currentPage.value - 1]
  })
});

const hasNextPage = computed(() => data.value?.activity?.pageInfo.hasNextPage ?? false);

watch(data, (val) => {
  if (val?.activity?.pageInfo.endCursor) {
    pageCursors.value[currentPage.value] = val.activity.pageInfo.endCursor;
  }
});

function switchFeed(type: "GLOBAL" | "FOLLOWING") {
  feedType.value = type;
  currentPage.value = 1;
  pageCursors.value = [null];
}

function nextPage() {
  if (hasNextPage.value) currentPage.value++;
}

function prevPage() {
  if (currentPage.value > 1) currentPage.value--;
}

const completionStatusLabels: Record<GamePurchaseCompletionStatus, string> = {
  UNPLAYED: "Unplayed",
  IN_PROGRESS: "In Progress",
  DROPPED: "Dropped",
  COMPLETED: "Completed",
  FULLY_COMPLETED: "Fully Completed",
  NOT_APPLICABLE: "Not Applicable",
  PAUSED: "Paused"
};

function completionStatusLabel(status: GamePurchaseCompletionStatus): string {
  return completionStatusLabels[status];
}
</script>

<style scoped>
.activity-avatar-placeholder {
  width: 48px;
  height: 48px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  font-size: 1.25rem;
  font-weight: 700;
  color: #fff;
  letter-spacing: 0.02em;
}
</style>
