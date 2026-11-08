<template>
  <section class="game-card" aria-labelledby="game-activity-heading">
    <div class="game-card-head">
      <h2 id="game-activity-heading" class="game-card-title">Recent activity</h2>
    </div>
    <ul class="activity-feed">
      <li v-for="event in events" :key="event.id">
        <router-link :to="`/users/${event.user.slug}`" tabindex="-1" aria-hidden="true">
          <UserAvatar :user="event.user" :size="32" />
        </router-link>
        <span class="activity-text">
          <router-link class="activity-user" :to="`/users/${event.user.slug}`">{{ event.user.username }}</router-link
          >{{ " " }}
          <template v-if="event.eventCategory === 'FAVORITE_GAME'">
            <Heart class="activity-heart" :size="15" fill="currentColor" aria-hidden="true" /> favorited it
          </template>
          <template v-else-if="event.eventCategory === 'CHANGE_COMPLETION_STATUS'">
            {{ statusPhrase(event).before }}
            <b v-if="statusPhrase(event).emphasis">{{ statusPhrase(event).emphasis }}</b>
          </template>
          <template v-else>added it to their library</template>
        </span>
        <time :datetime="event.createdAt" :title="new Date(event.createdAt).toLocaleString()">
          {{ timeAgo(event.createdAt) }}
        </time>
      </li>
    </ul>
  </section>
</template>

<script setup lang="ts">
import { Heart } from "@lucide/vue";
import type { GamePurchaseCompletionStatus, GetGameActivityQuery } from "@/types/graphql";
import { timeAgo } from "@/utils/time";
import UserAvatar from "@/components/game/UserAvatar.vue";

export type GameActivityEvent = NonNullable<GetGameActivityQuery["game"]>["activity"]["nodes"][number];

defineProps<{ events: GameActivityEvent[] }>();

interface Phrase {
  before: string;
  emphasis?: string;
}

const STATUS_PHRASES: Record<GamePurchaseCompletionStatus, Phrase> = {
  IN_PROGRESS: { before: "started playing it" },
  COMPLETED: { before: "marked it", emphasis: "Completed" },
  FULLY_COMPLETED: { before: "marked it", emphasis: "100% completed" },
  PAUSED: { before: "marked it", emphasis: "Paused" },
  DROPPED: { before: "marked it", emphasis: "Dropped" },
  UNPLAYED: { before: "marked it", emphasis: "Unplayed" },
  NOT_APPLICABLE: { before: "marked it", emphasis: "N/A" }
};

// The status the event changed the game to. Older events have no recorded
// change, so fall back to the entry's current status for those.
function eventStatus(event: GameActivityEvent): GamePurchaseCompletionStatus | null {
  if (event.completionStatusChange?.after) {
    return event.completionStatusChange.after;
  }
  if ("completionStatus" in event.eventable) {
    return event.eventable.completionStatus;
  }
  return null;
}

function statusPhrase(event: GameActivityEvent): Phrase {
  const status = eventStatus(event);
  return status ? STATUS_PHRASES[status] : { before: "changed its status" };
}
</script>

<style scoped>
.activity-feed {
  margin: 8px 0 0;
  padding: 0;
  list-style: none;
}

.activity-feed li {
  display: grid;
  grid-template-columns: 32px minmax(0, 1fr) auto;
  gap: 12px;
  align-items: center;
  padding: 10px 0;
  border-top: 1px solid var(--color-border);
  font-size: 0.875rem;
  color: var(--color-text-primary);
}

.activity-feed li:first-child {
  border-top: 0;
}

.activity-text {
  min-width: 0;
  overflow-wrap: anywhere;
}

.activity-user {
  font-weight: 600;
  color: var(--color-text-primary);
}

.activity-user:hover {
  text-decoration: underline;
}

.activity-user:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.activity-heart {
  display: inline-block;
  margin-right: 1px;
  vertical-align: -2px;
  color: #ff4d6a;
}

.activity-feed time {
  font-size: 0.78rem;
  color: var(--color-text-secondary);
  white-space: nowrap;
}
</style>
