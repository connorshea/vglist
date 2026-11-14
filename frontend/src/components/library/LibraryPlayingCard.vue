<template>
  <div class="playing-card-wrap" :class="{ 'is-editable': editable }">
    <router-link :to="{ name: 'game', params: { id: purchase.game.id } }" class="playing-card">
      <span class="playing-card-cover">
        <img v-if="purchase.game.coverUrl" :src="purchase.game.coverUrl" alt="" loading="lazy" />
        <span v-else class="cover-placeholder" :style="coverPlaceholderStyle(purchase.game.name)" aria-hidden="true">{{
          gameInitials(purchase.game.name)
        }}</span>
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

    <button
      v-if="editable"
      type="button"
      class="playing-card-edit"
      :aria-label="`Edit library entry for ${purchase.game.name}`"
      @click="emit('edit')"
    >
      <Pencil :size="15" :stroke-width="2" aria-hidden="true" />
    </button>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { Clock, Pencil } from "@lucide/vue";
import type { LibraryPlayingPurchaseFieldsFragment } from "@/types/graphql";
import { formatHours, formatStartDate, gameInitials } from "@/utils/library";
import { coverPlaceholderStyle } from "@/utils/cover-placeholder";

const props = defineProps<{
  purchase: LibraryPlayingPurchaseFieldsFragment;
  hideHours?: boolean;
  /** Show a button that opens the library entry for editing (the owner's own library). */
  editable?: boolean;
}>();

const emit = defineEmits<{ edit: [] }>();

// "Windows · Steam"
const where = computed(() =>
  [...props.purchase.platforms.nodes, ...props.purchase.stores.nodes].map((record) => record.name).join(" · ")
);

// "31h · started Sep 4"
const progress = computed(() => {
  const parts: string[] = [];
  const hours = props.hideHours ? null : formatHours(props.purchase.hoursPlayed);
  if (hours) {
    parts.push(hours);
  }
  if (props.purchase.startDate) {
    parts.push(`started ${formatStartDate(props.purchase.startDate)}`);
  }
  return parts.join(" · ");
});
</script>

<style scoped>
.playing-card-wrap {
  position: relative;
}

.playing-card {
  display: flex;
  height: 100%;
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

/* Leaves room for the edit button in the top-right corner */
.is-editable .playing-card-body {
  padding-right: 28px;
}

.playing-card-edit {
  position: absolute;
  top: 8px;
  right: 8px;
  display: grid;
  place-items: center;
  width: 32px;
  height: 32px;
  padding: 0;
  border: 0;
  border-radius: 999px;
  background: transparent;
  color: var(--color-text-secondary);
  cursor: pointer;
}

.playing-card-edit:hover {
  background: var(--color-bg-subtle);
  color: var(--color-accent);
}

.playing-card-edit:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}
</style>
