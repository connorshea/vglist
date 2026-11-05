<template>
  <router-link :to="{ name: 'game', params: { id: purchase.game.id } }" class="playing-card">
    <span class="playing-card-cover">
      <img v-if="purchase.game.coverUrl" :src="purchase.game.coverUrl" alt="" loading="lazy" />
      <span v-else class="cover-placeholder" aria-hidden="true">{{ gameInitials(purchase.game.name) }}</span>
    </span>
    <span class="playing-card-body">
      <b class="playing-card-name">{{ purchase.game.name }}</b>
      <span v-if="where" class="playing-card-meta">{{ where }}</span>
      <span v-if="progress" class="playing-card-meta playing-card-progress">
        <Clock :size="14" aria-hidden="true" />
        {{ progress }}
      </span>
    </span>
  </router-link>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { Clock } from "@lucide/vue";
import type { GetLibraryShelvesQuery } from "@/types/graphql";
import { formatHours, formatStartDate, gameInitials } from "@/utils/library";

type PlayingPurchase = NonNullable<GetLibraryShelvesQuery["user"]>["inProgress"]["nodes"][number];

const props = defineProps<{
  purchase: PlayingPurchase;
  hideHours?: boolean;
}>();

// "Windows · Steam"
const where = computed(() =>
  [...props.purchase.platforms.nodes, ...props.purchase.stores.nodes].map((record) => record.name).join(" · ")
);

// "31h · started Sep 4"
const progress = computed(() => {
  const parts: string[] = [];
  const hours = props.hideHours ? null : formatHours(props.purchase.hoursPlayed);
  if (hours) parts.push(hours);
  if (props.purchase.startDate) parts.push(`started ${formatStartDate(props.purchase.startDate)}`);
  return parts.join(" · ");
});
</script>

<style scoped>
.playing-card {
  display: flex;
  gap: 12px;
  padding: 12px;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  background: var(--color-surface);
  color: var(--color-text-primary);
  transition:
    border-color var(--transition-fast),
    box-shadow var(--transition-fast);
}

.playing-card:hover {
  border-color: var(--color-accent);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.playing-card:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.playing-card-cover {
  flex-shrink: 0;
  width: 64px;
  aspect-ratio: 3 / 4;
  overflow: hidden;
  border-radius: var(--radius-sm);
  font-size: 1rem;
}

.playing-card-cover img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.playing-card-body {
  display: flex;
  flex: 1;
  flex-direction: column;
  min-width: 0;
}

.playing-card-name {
  font-size: 0.875rem;
  font-weight: 600;
  line-height: 1.3;
}

.playing-card-meta {
  margin-top: 2px;
  color: var(--color-text-secondary);
  font-size: 0.75rem;
}

.playing-card-progress {
  display: flex;
  gap: 6px;
  align-items: center;
  margin-top: auto;
  padding-top: 10px;
  font-size: 0.7rem;
}
</style>
