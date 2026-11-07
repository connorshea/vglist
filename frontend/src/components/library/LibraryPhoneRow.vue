<template>
  <router-link :to="{ name: 'game', params: { id: purchase.game.id } }" class="library-row">
    <span class="library-row-cover">
      <img v-if="purchase.game.coverUrl" :src="purchase.game.coverUrl" alt="" loading="lazy" />
      <span v-else class="cover-placeholder" aria-hidden="true">{{ gameInitials(purchase.game.name) }}</span>
    </span>
    <span class="library-row-body">
      <b class="library-row-name">{{ purchase.game.name }}</b>
      <span v-if="status || hours" class="library-row-meta">
        <span v-if="status" class="status-dot" :class="status.className" aria-hidden="true"></span>
        {{ [status?.label, hours].filter(Boolean).join(" · ") }}
      </span>
    </span>
    <span v-if="purchase.rating !== null" class="library-row-score">
      <span class="is-sr-only">Rated</span>
      {{ purchase.rating }}
    </span>
  </router-link>
</template>

<script setup lang="ts">
import { computed } from "vue";
import type { LibraryGamePurchaseFieldsFragment } from "@/types/graphql";
import { formatHours, gameInitials, libraryStatus } from "@/utils/library";

const props = defineProps<{
  purchase: LibraryGamePurchaseFieldsFragment;
  hideHours?: boolean;
}>();

const status = computed(() => libraryStatus(props.purchase.completionStatus));
const hours = computed(() => (props.hideHours ? null : formatHours(props.purchase.hoursPlayed)));
</script>

<style scoped>
.library-row {
  display: flex;
  gap: 12px;
  align-items: center;
  min-height: 44px;
  padding: 10px var(--library-inset, 16px);
  border-bottom: 1px solid var(--color-border);
  color: var(--color-text-primary);
}

.library-row:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: -2px;
}

.library-row-cover {
  flex-shrink: 0;
  width: 40px;
  aspect-ratio: 3 / 4;
  overflow: hidden;
  border-radius: 5px;
  font-size: 0.7rem;
}

.library-row-cover img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.library-row-body {
  min-width: 0;
}

.library-row-name {
  display: block;
  overflow: hidden;
  font-size: 0.875rem;
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.library-row-meta {
  display: flex;
  gap: 6px;
  align-items: center;
  color: var(--color-text-secondary);
  font-size: 0.75rem;
}

.library-row-score {
  margin-left: auto;
  color: var(--color-accent);
  font-size: 0.95rem;
  font-weight: 700;
}
</style>
