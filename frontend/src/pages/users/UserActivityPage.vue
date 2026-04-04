<template>
  <section class="section activity-section">
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>{{ error.message }}</p>
    </div>

    <div v-if="user">
      <h1 class="title">
        <router-link :to="`/users/${route.params.slug}`">{{ user.username }}</router-link>
        &rsaquo; Activity
      </h1>

      <div v-if="events.length === 0 && !loading" class="has-text-centered has-text-grey py-6">
        <p>No activity yet.</p>
      </div>

      <div v-for="event in events" :key="event.id" class="a-card">
        <!-- Cover art for game-related events -->
        <router-link v-if="eventGame(event)" :to="`/games/${eventGame(event)!.id}`" class="a-cover-link">
          <img
            v-if="eventGame(event)!.coverUrl"
            class="a-cover"
            :src="eventGame(event)!.coverUrl!"
            :alt="eventGame(event)!.name"
          />
          <div v-else class="a-cover a-cover-placeholder">
            <span>{{ eventGame(event)!.name.charAt(0).toUpperCase() }}</span>
          </div>
        </router-link>

        <!-- User avatar for non-game events -->
        <div v-else class="a-cover-link">
          <div class="a-cover a-cover-placeholder a-cover-user">
            <span v-if="event.eventCategory === 'FOLLOWING' && 'followed' in event.eventable">
              {{ event.eventable.followed.username.charAt(0).toUpperCase() }}
            </span>
            <span v-else-if="event.eventCategory === 'NEW_USER'">
              {{ event.user.username.charAt(0).toUpperCase() }}
            </span>
          </div>
        </div>

        <div class="a-body">
          <div class="a-row1">
            <span class="a-sentence">
              <img
                v-if="event.user.avatarUrl"
                class="a-user-avatar"
                :src="event.user.avatarUrl"
                :alt="event.user.username"
              />
              <span v-else class="a-user-avatar a-user-avatar-placeholder">
                {{ event.user.username.charAt(0).toUpperCase() }}
              </span>
              <router-link :to="`/users/${event.user.slug}`" class="a-user-link">
                {{ event.user.username }}
              </router-link>
              {{ " " }}
              <template v-if="event.eventCategory === 'ADD_TO_LIBRARY' && 'game' in event.eventable">
                <span class="a-verb">added</span>{{ " " }}
                <router-link :to="`/games/${event.eventable.game.id}`" class="a-game-link">{{
                  event.eventable.game.name
                }}</router-link
                >{{ " " }}
                <span class="a-verb">to their library</span>
              </template>
              <template v-else-if="event.eventCategory === 'CHANGE_COMPLETION_STATUS' && 'game' in event.eventable">
                <span class="a-verb">{{ completionStatusVerb(event) }}</span
                >{{ " " }}
                <router-link :to="`/games/${event.eventable.game.id}`" class="a-game-link">{{
                  event.eventable.game.name
                }}</router-link>
              </template>
              <template v-else-if="event.eventCategory === 'FAVORITE_GAME' && 'game' in event.eventable">
                <span class="a-verb">favorited</span>{{ " " }}
                <router-link :to="`/games/${event.eventable.game.id}`" class="a-game-link">{{
                  event.eventable.game.name
                }}</router-link>
              </template>
              <template v-else-if="event.eventCategory === 'FOLLOWING' && 'followed' in event.eventable">
                <span class="a-verb">started following</span>{{ " " }}
                <router-link :to="`/users/${event.eventable.followed.slug}`" class="a-user-link">{{
                  event.eventable.followed.username
                }}</router-link>
              </template>
              <template v-else-if="event.eventCategory === 'NEW_USER'">
                <span class="a-verb">joined vglist</span>
              </template>
            </span>

            <span v-if="eventBadge(event)" class="a-status-badge" :class="eventBadge(event)!.cssClass">
              {{ eventBadge(event)!.label }}
            </span>

            <button
              v-if="canDeleteEvent(event)"
              class="a-delete-btn"
              aria-label="Delete event"
              :disabled="deletingEventId === event.id"
              @click="promptDeleteEvent(event.id)"
            >
              &times;
            </button>
          </div>

          <div class="a-meta">
            <span class="a-time">{{ timeAgo(event.createdAt) }}</span>
            <template v-if="eventRating(event) !== null">
              <span class="a-separator" />
              <span class="a-rating">{{ eventRating(event) }} / 100</span>
            </template>
          </div>
        </div>
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

    <!-- Delete event confirmation dialog -->
    <ConfirmDialog
      v-model="showDeleteEventConfirm"
      title="Delete event?"
      confirm-label="Delete event"
      loading-label="Deleting…"
      :loading="deletingEventId !== null"
      @confirm="confirmDeleteEvent"
    >
      <template #icon>
        <Trash2 :size="22" :stroke-width="1.8" />
      </template>
      This event will be permanently removed from the activity feed.
    </ConfirmDialog>
  </section>
</template>

<script setup lang="ts">
import { ref, computed, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useQuery, useMutation } from "@/composables/useGraphQL";
import { GET_USER_ACTIVITY } from "@/graphql/queries/users";
import { DELETE_EVENT } from "@/graphql/mutations/events";
import type { GamePurchaseCompletionStatus, DeleteEventMutation } from "@/types/graphql";
import PaginationNav from "@/components/PaginationNav.vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";
import { Trash2 } from "lucide-vue-next";
import { useAuthStore } from "@/stores/auth";
import { useSnackbar } from "@/composables/useSnackbar";

const route = useRoute("userActivity");
const router = useRouter();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();
const { mutate: deleteEventMutate } = useMutation<DeleteEventMutation>(DELETE_EVENT);
const deletingEventId = ref<string | null>(null);

const PAGE_SIZE = 25;
const currentPage = ref(1);
const pageCursors = ref<(string | null)[]>([null]);

interface ActivityEventGame {
  id: string;
  name: string;
  coverUrl?: string | null;
}

interface ActivityEventUser {
  id: string;
  username: string;
  slug: string;
  avatarUrl?: string | null;
}

type ActivityEventable =
  | { game: ActivityEventGame; completionStatus?: string | null; rating?: number | null }
  | { game: ActivityEventGame }
  | { followed: ActivityEventUser }
  | ActivityEventUser;

interface ActivityNode {
  id: string;
  eventCategory: string;
  createdAt: string;
  user: ActivityEventUser;
  eventable: ActivityEventable;
}

interface GetUserActivityResult {
  user: {
    id: string;
    username: string;
    slug: string;
    activity: {
      nodes: ActivityNode[];
      pageInfo: {
        hasNextPage: boolean;
        endCursor: string | null;
      };
    };
  } | null;
}

const { data, loading, error } = useQuery<GetUserActivityResult>(GET_USER_ACTIVITY, {
  variables: () => ({
    slug: route.params.slug,
    first: PAGE_SIZE,
    after: pageCursors.value[currentPage.value - 1]
  })
});

watch([data, error, loading], () => {
  if (!loading.value && (error.value || (data.value && !data.value.user))) {
    router.replace({ name: "notFound" });
  }
});

const user = computed(() => data.value?.user ?? null);
const events = computed(() => user.value?.activity?.nodes ?? []);
const hasNextPage = computed(() => user.value?.activity?.pageInfo.hasNextPage ?? false);

watch(data, (val) => {
  if (val?.user?.activity?.pageInfo.endCursor) {
    pageCursors.value[currentPage.value] = val.user.activity.pageInfo.endCursor;
  }
});

function nextPage() {
  if (hasNextPage.value) {
    currentPage.value++;
    window.scrollTo({ top: 0, behavior: "smooth" });
  }
}

function prevPage() {
  if (currentPage.value > 1) {
    currentPage.value--;
    window.scrollTo({ top: 0, behavior: "smooth" });
  }
}

// ── Event helpers (reused from ActivityPage) ──

function eventGame(event: ActivityNode): ActivityEventGame | null {
  if (
    (event.eventCategory === "ADD_TO_LIBRARY" ||
      event.eventCategory === "CHANGE_COMPLETION_STATUS" ||
      event.eventCategory === "FAVORITE_GAME") &&
    "game" in event.eventable
  ) {
    return event.eventable.game;
  }
  return null;
}

function eventRating(event: ActivityNode): number | null {
  if (
    (event.eventCategory === "ADD_TO_LIBRARY" || event.eventCategory === "CHANGE_COMPLETION_STATUS") &&
    "rating" in event.eventable &&
    event.eventable.rating != null
  ) {
    return event.eventable.rating;
  }
  return null;
}

const completionStatusLabels: Record<GamePurchaseCompletionStatus, string> = {
  UNPLAYED: "Unplayed",
  IN_PROGRESS: "In Progress",
  DROPPED: "Dropped",
  COMPLETED: "Completed",
  FULLY_COMPLETED: "100%",
  NOT_APPLICABLE: "N/A",
  PAUSED: "Paused"
};

const completionStatusVerbs: Record<GamePurchaseCompletionStatus, string> = {
  UNPLAYED: "set",
  IN_PROGRESS: "is playing",
  DROPPED: "dropped",
  COMPLETED: "completed",
  FULLY_COMPLETED: "100%'d",
  NOT_APPLICABLE: "set",
  PAUSED: "paused"
};

function completionStatusVerb(event: ActivityNode): string {
  if ("completionStatus" in event.eventable && event.eventable.completionStatus) {
    return completionStatusVerbs[event.eventable.completionStatus as GamePurchaseCompletionStatus];
  }
  return "changed the status of";
}

interface BadgeInfo {
  label: string;
  cssClass: string;
}

function eventBadge(event: ActivityNode): BadgeInfo | null {
  if (event.eventCategory === "ADD_TO_LIBRARY") {
    return { label: "Added", cssClass: "badge-added" };
  }
  if (event.eventCategory === "FAVORITE_GAME") {
    return { label: "Favorited", cssClass: "badge-favorited" };
  }
  if (
    event.eventCategory === "CHANGE_COMPLETION_STATUS" &&
    "completionStatus" in event.eventable &&
    event.eventable.completionStatus
  ) {
    const status = event.eventable.completionStatus as GamePurchaseCompletionStatus;
    return {
      label: completionStatusLabels[status],
      cssClass: `badge-${status.toLowerCase().replace("_", "-")}`
    };
  }
  if (event.eventCategory === "NEW_USER") {
    return { label: "New User", cssClass: "badge-new-user" };
  }
  if (event.eventCategory === "FOLLOWING") {
    return { label: "Followed", cssClass: "badge-followed" };
  }
  return null;
}

function timeAgo(dateStr: string): string {
  const date = new Date(dateStr);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffSec = Math.floor(diffMs / 1000);
  const diffMin = Math.floor(diffSec / 60);
  const diffHr = Math.floor(diffMin / 60);
  const diffDay = Math.floor(diffHr / 24);
  const diffWeek = Math.floor(diffDay / 7);
  const diffMonth = Math.floor(diffDay / 30);

  if (diffMin < 1) return "just now";
  if (diffMin < 60) return `${diffMin}m ago`;
  if (diffHr < 24) return `${diffHr}h ago`;
  if (diffDay === 1) return "1 day ago";
  if (diffDay < 7) return `${diffDay} days ago`;
  if (diffWeek === 1) return "1 week ago";
  if (diffWeek < 5) return `${diffWeek} weeks ago`;
  if (diffMonth === 1) return "1 month ago";
  if (diffMonth < 12) return `${diffMonth} months ago`;
  return date.toLocaleDateString();
}

function canDeleteEvent(event: ActivityNode): boolean {
  if (!authStore.user) return false;
  const role = authStore.user.role;
  if (role === "MODERATOR" || role === "ADMIN") return true;
  return event.user.id === authStore.user.id;
}

// ── Delete event ──

const showDeleteEventConfirm = ref(false);
const pendingDeleteEventId = ref<string | null>(null);

function promptDeleteEvent(eventId: string) {
  pendingDeleteEventId.value = eventId;
  showDeleteEventConfirm.value = true;
}

async function confirmDeleteEvent() {
  const eventId = pendingDeleteEventId.value;
  if (!eventId) return;

  deletingEventId.value = eventId;
  try {
    await deleteEventMutate({ eventId });
    showDeleteEventConfirm.value = false;
    if (data.value?.user?.activity) {
      data.value = {
        ...data.value,
        user: {
          ...data.value.user,
          activity: {
            ...data.value.user.activity,
            nodes: data.value.user.activity.nodes.filter((e) => e.id !== eventId)
          }
        }
      };
    }
    showSnackbar("Event deleted.", "success");
  } catch {
    showSnackbar("Failed to delete event.", "error");
  } finally {
    deletingEventId.value = null;
    pendingDeleteEventId.value = null;
  }
}
</script>

<style scoped>
/* Full-width background */
.activity-section {
  background: var(--color-bg-subtle);
  margin: -3rem calc(-50vw + 50%);
  padding: 3rem max(1.5rem, calc(50vw - 50%));
  min-height: calc(100vh - 52px);
}

/* Card */
.a-card {
  background: var(--color-surface);
  border-radius: 10px;
  padding: 14px 16px;
  display: flex;
  gap: 14px;
  align-items: flex-start;
  border: 1px solid rgba(0, 0, 0, 0.08);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  transition:
    box-shadow 0.2s,
    border-color 0.2s;
  margin-bottom: 8px;
}

.a-card:hover {
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
  border-color: rgba(0, 0, 0, 0.1);
}

/* Cover art */
.a-cover-link {
  flex-shrink: 0;
  text-decoration: none;
}

.a-cover {
  width: 52px;
  height: 68px;
  border-radius: 6px;
  object-fit: cover;
  display: block;
}

.a-cover-placeholder {
  background: linear-gradient(145deg, var(--p-400) 0%, var(--p-500) 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-weight: 700;
  font-size: 1.1rem;
}

.a-cover-user {
  background: linear-gradient(145deg, var(--p-500) 0%, var(--p-700) 100%);
}

/* Body */
.a-body {
  flex: 1;
  min-width: 0;
}

.a-row1 {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.a-sentence {
  font-size: 14px;
  line-height: 1.45;
  flex: 1;
  min-width: 0;
}

/* Inline user avatar */
.a-user-avatar {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  vertical-align: middle;
  margin-right: 4px;
  display: inline-block;
}

.a-user-avatar-placeholder {
  background: linear-gradient(135deg, var(--p-400) 0%, var(--p-600) 100%);
  color: #fff;
  font-size: 9px;
  font-weight: 600;
  text-align: center;
  line-height: 22px;
}

.a-user-link {
  color: var(--color-text-primary);
  font-weight: 500;
  text-decoration: none;
  font-size: 14px;
  vertical-align: middle;
}

.a-user-link:hover {
  color: var(--color-accent);
}

.a-verb {
  color: var(--color-text-secondary);
}

.a-game-link {
  color: var(--color-accent);
  text-decoration: none;
  font-weight: 500;
}

.a-game-link:hover {
  text-decoration: underline;
}

/* Status badges */
.a-status-badge {
  font-size: 10px;
  font-weight: 600;
  padding: 3px 9px;
  border-radius: 12px;
  text-transform: uppercase;
  letter-spacing: 0.3px;
  white-space: nowrap;
  flex-shrink: 0;
}

.badge-added {
  background: var(--p-50);
  color: var(--p-500);
}

.badge-favorited {
  background: #fef0e6;
  color: #c2410c;
}

.badge-completed {
  background: #e6f1fb;
  color: #0c447c;
}

.badge-in-progress {
  background: #eaf3de;
  color: #27500a;
}

.badge-dropped {
  background: #fef0e6;
  color: #8b4513;
}

.badge-unplayed {
  background: var(--color-bg-subtle);
  color: var(--color-text-secondary);
}

.badge-fully-completed {
  background: #fff8db;
  color: #7a6200;
}

.badge-not-applicable {
  background: var(--color-bg-subtle);
  color: var(--color-text-tertiary);
}

.badge-paused {
  background: var(--color-bg-subtle);
  color: var(--color-text-secondary);
}

.badge-new-user {
  background: #e8f5e9;
  color: #2e7d32;
}

.badge-followed {
  background: #e3f2fd;
  color: #1565c0;
}

/* Meta row */
.a-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 6px;
  flex-wrap: wrap;
}

.a-time {
  font-size: 12px;
  color: var(--color-text-tertiary);
}

.a-separator {
  width: 3px;
  height: 3px;
  border-radius: 50%;
  background: var(--color-border);
  flex-shrink: 0;
}

/* Delete button */
.a-delete-btn {
  background: none;
  border: none;
  color: var(--color-text-tertiary);
  font-size: 18px;
  cursor: pointer;
  padding: 0 4px;
  line-height: 1;
  flex-shrink: 0;
  opacity: 0;
  transition:
    opacity 0.15s,
    color 0.15s;
}

.a-card:hover .a-delete-btn {
  opacity: 1;
}

.a-delete-btn:hover {
  color: var(--r-500);
}

.a-delete-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.a-rating {
  font-size: 12px;
  color: var(--color-text-secondary);
}

/* ── Mobile layout ── */
@media (max-width: 768px) {
  .a-card {
    flex-direction: column;
    gap: 10px;
    padding: 12px 14px;
  }

  .a-cover-link {
    display: none;
  }

  .a-row1 {
    gap: 6px;
  }

  .a-status-badge {
    order: 1;
  }

  .a-delete-btn {
    order: 2;
    opacity: 1;
  }
}
</style>
