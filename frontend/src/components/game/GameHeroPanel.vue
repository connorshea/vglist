<template>
  <aside class="hero-panel" aria-label="On vglist">
    <div class="hero-panel-rating">
      <div class="hero-ring" :class="{ empty: avgRating === null }">
        <svg viewBox="0 0 120 120" aria-hidden="true">
          <circle class="hero-ring-track" cx="60" cy="60" r="52" fill="none" stroke-width="8" />
          <circle
            v-if="avgRating !== null"
            class="hero-ring-fill"
            cx="60"
            cy="60"
            r="52"
            fill="none"
            stroke-width="8"
            :stroke-dasharray="RING_CIRCUMFERENCE"
            :stroke-dashoffset="ringOffset"
            stroke-linecap="round"
            transform="rotate(-90 60 60)"
          />
        </svg>
        <span aria-hidden="true">{{ avgRating === null ? "–" : Math.round(avgRating) }}</span>
      </div>
      <div>
        <p class="hero-panel-rating-title">Average rating</p>
        <p class="hero-panel-rating-sub">
          <template v-if="avgRating !== null">
            {{ avgRating.toFixed(1) }} / 100 from {{ ratingCount.toLocaleString() }}
            {{ ratingCount === 1 ? "rating" : "ratings" }}
          </template>
          <template v-else>No ratings yet</template>
        </p>
      </div>
    </div>

    <button v-if="entry" type="button" class="hero-panel-you" @click="emit('edit-entry')">
      <span class="hero-panel-dot" :class="statusClass" aria-hidden="true"></span>
      <span>
        <b>You:</b> {{ entrySummary }}
        <span class="visually-hidden">(edit your library entry)</span>
      </span>
    </button>

    <hr />

    <h3 class="hero-panel-label">Owners <span>{{ owners.totalCount.toLocaleString() }}</span></h3>
    <div v-if="owners.nodes.length" class="hero-avatars">
      <router-link
        v-for="user in owners.nodes"
        :key="user.id"
        :to="`/users/${user.slug}`"
        :aria-label="user.username"
        :title="user.username"
      >
        <UserAvatar :user="user" :size="30" />
      </router-link>
    </div>
    <p v-else class="hero-panel-empty">No owners yet.</p>

    <h3 class="hero-panel-label hero-panel-label-spaced">
      Favorited by <span>{{ favoriters.totalCount.toLocaleString() }}</span>
    </h3>
    <div v-if="favoriters.nodes.length" class="hero-avatars">
      <router-link
        v-for="user in favoriters.nodes"
        :key="user.id"
        :to="`/users/${user.slug}`"
        :aria-label="user.username"
        :title="user.username"
      >
        <UserAvatar :user="user" :size="30" />
      </router-link>
    </div>
    <p v-else class="hero-panel-empty">No favorites yet.</p>

    <template v-if="externalLinks.length">
      <hr />
      <h3 class="hero-panel-label">Find it on</h3>
      <div class="hero-tags">
        <a
          v-for="link in externalLinks"
          :key="link.label"
          class="hero-tag"
          :href="link.url"
          target="_blank"
          rel="noopener noreferrer"
        >
          {{ link.label }}
        </a>
      </div>
    </template>
  </aside>
</template>

<script setup lang="ts">
import { computed } from "vue";
import type { GamePurchaseCompletionStatus } from "@/types/graphql";
import { formatHours, libraryStatus } from "@/utils/library";
import UserAvatar from "@/components/game/UserAvatar.vue";

interface UserConnection {
  nodes: { id: string; slug: string; username: string; avatarUrl?: string | null }[];
  totalCount: number;
}

export interface HeroPanelEntry {
  completionStatus: GamePurchaseCompletionStatus | null;
  rating: number | null;
  hoursPlayed: number | null;
}

const props = defineProps<{
  avgRating: number | null;
  ratingCount: number;
  // The signed-in user's library entry for the game, if they have one.
  entry: HeroPanelEntry | null;
  owners: UserConnection;
  favoriters: UserConnection;
  externalLinks: { label: string; url: string }[];
}>();

const emit = defineEmits<{ "edit-entry": [] }>();

const RING_CIRCUMFERENCE = 2 * Math.PI * 52;
const ringOffset = computed(() => RING_CIRCUMFERENCE * (1 - (props.avgRating ?? 0) / 100));

const statusClass = computed(() => libraryStatus(props.entry?.completionStatus)?.className ?? "st-none");

// "Completed · rated 92 · 41h", or "In library" when there's nothing else to say.
const entrySummary = computed(() => {
  const entry = props.entry;
  if (!entry) {
    return "";
  }
  const parts: string[] = [];
  const status = libraryStatus(entry.completionStatus);
  if (status) {
    parts.push(status.label);
  }
  if (entry.rating !== null) {
    parts.push(`rated ${entry.rating}`);
  }
  const hours = formatHours(entry.hoursPlayed);
  if (hours) {
    parts.push(hours);
  }
  return parts.length ? parts.join(" · ") : "In library";
});
</script>

<style scoped>
.hero-panel {
  padding: 20px;
  color: #fff;
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.16);
  border-radius: var(--radius-lg);
  backdrop-filter: blur(6px);
}

.hero-panel-rating {
  display: flex;
  align-items: center;
  gap: 16px;
}

.hero-ring {
  position: relative;
  width: 72px;
  height: 72px;
  flex-shrink: 0;
}

.hero-ring svg {
  display: block;
  width: 100%;
  height: 100%;
}

.hero-ring-track {
  stroke: rgba(255, 255, 255, 0.18);
}

.hero-ring-fill {
  stroke: #fff;
}

.hero-ring span {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5rem;
  font-weight: 700;
}

.hero-ring.empty span {
  color: rgba(255, 255, 255, 0.6);
}

.hero-panel-rating-title {
  font-size: 0.95rem;
  font-weight: 600;
}

.hero-panel-rating-sub {
  margin-top: 2px;
  font-size: 0.8125rem;
  color: rgba(255, 255, 255, 0.72);
}

.hero-panel-you {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  margin-top: 14px;
  padding: 8px 10px;
  border: 0;
  border-radius: var(--radius-sm);
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
  font: inherit;
  font-size: 0.85rem;
  text-align: left;
  cursor: pointer;
}

.hero-panel-you:hover {
  background: rgba(255, 255, 255, 0.16);
}

.hero-panel-you:focus-visible,
.hero-tag:focus-visible,
.hero-avatars a:focus-visible {
  outline: 2px solid #fff;
  outline-offset: 2px;
}

.hero-panel-dot {
  width: 10px;
  height: 10px;
  margin: 0 4px;
  flex-shrink: 0;
  border-radius: 50%;
  background: #6b7280;
  box-shadow: 0 0 0 4px rgba(255, 255, 255, 0.12);
}

.st-in-progress {
  background: #3b82f6;
}
.st-completed {
  background: #22c55e;
}
.st-fully-completed {
  background: #16a34a;
}
.st-paused {
  background: #f59e0b;
}
.st-dropped {
  background: #ef4444;
}
.st-unplayed {
  background: #a855f7;
}
.st-none {
  background: transparent;
  box-shadow: inset 0 0 0 1.5px rgba(255, 255, 255, 0.6);
}

.hero-panel hr {
  border: 0;
  border-top: 1px solid rgba(255, 255, 255, 0.14);
  margin: 16px 0;
  background: none;
  height: 0;
}

.hero-panel-label {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
  font-size: 0.7rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: rgba(255, 255, 255, 0.62);
}

.hero-panel-label span {
  letter-spacing: 0;
  text-transform: none;
  font-weight: 500;
}

.hero-panel-label-spaced {
  margin-top: 14px;
}

.hero-panel-empty {
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.62);
}

.hero-avatars {
  display: flex;
}

.hero-avatars a {
  display: inline-flex;
  border: 2px solid rgba(30, 20, 40, 0.85);
  border-radius: 50%;
  margin-left: -8px;
  transition: transform var(--transition-fast);
}

.hero-avatars a:first-child {
  margin-left: 0;
}

.hero-avatars a:hover {
  transform: translateY(-2px);
  z-index: 1;
}

.hero-tags {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
}

.hero-tag {
  display: inline-block;
  align-content: center;
  height: 28px;
  text-box: trim-both cap alphabetic;
  padding: 0 10px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.12);
  color: #fff;
  font-size: 0.8125rem;
  font-weight: 500;
  text-decoration: none;
}

.hero-tag:hover {
  background: rgba(255, 255, 255, 0.2);
  color: #fff;
}

.visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  margin: -1px;
  padding: 0;
  overflow: hidden;
  clip: rect(0 0 0 0);
  white-space: nowrap;
  border: 0;
}
</style>
