<template>
  <div class="library-tile-wrap" :class="{ 'is-editable': editable }">
    <router-link :to="{ name: 'game', params: { id: purchase.game.id } }" class="library-tile" :aria-label="ariaLabel">
      <img
        v-if="purchase.game.coverUrl"
        :src="purchase.game.coverUrl"
        alt=""
        class="library-tile-cover"
        loading="lazy"
      />
      <span
        v-else
        class="cover-placeholder library-tile-placeholder"
        :style="coverPlaceholderStyle(purchase.game.name)"
        aria-hidden="true"
      >
        {{ gameInitials(purchase.game.name) }}
      </span>

      <span v-if="status" class="status-dot library-tile-dot" :class="status.className" aria-hidden="true"></span>
      <span
        v-if="purchase.rating !== null"
        class="rating-badge library-tile-rating"
        :class="ratingTier(purchase.rating)"
        aria-hidden="true"
      >
        {{ purchase.rating }}
      </span>

      <span class="library-tile-name" aria-hidden="true">{{ purchase.game.name }}</span>

      <span class="library-tile-hover" aria-hidden="true">
        <b>{{ purchase.game.name }}</b>
        <span v-if="status || hours || purchase.rating !== null" class="library-tile-meta">
          <span v-if="status" class="library-tile-status" :class="status.className">{{ status.label }}</span>
          <span v-if="hours">{{ hours }}</span>
          <span v-if="purchase.rating !== null">{{ purchase.rating }}/100</span>
        </span>
      </span>
    </router-link>

    <!-- A sibling of the link, since a button can't go inside one -->
    <button
      v-if="editable"
      type="button"
      class="library-tile-edit"
      :aria-label="`Edit library entry for ${purchase.game.name}`"
      @click="emit('edit')"
    >
      <Pencil :size="14" :stroke-width="2" aria-hidden="true" />
    </button>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { Pencil } from "@lucide/vue";
import type { LibraryGamePurchaseFieldsFragment } from "@/types/graphql";
import { formatHours, gameInitials, libraryStatus, ratingTier } from "@/utils/library";
import { coverPlaceholderStyle } from "@/utils/cover-placeholder";

const props = defineProps<{
  purchase: LibraryGamePurchaseFieldsFragment;
  hideHours?: boolean;
  /** Show a button that opens the library entry for editing (the owner's own library). */
  editable?: boolean;
}>();

const emit = defineEmits<{ edit: [] }>();

const status = computed(() => libraryStatus(props.purchase.completionStatus));
const hours = computed(() => (props.hideHours ? null : formatHours(props.purchase.hoursPlayed)));

// The dot and badge are visual only, so spell them out for screen readers.
const ariaLabel = computed(() => {
  const parts = [props.purchase.game.name];
  if (status.value) {
    parts.push(status.value.label);
  }
  if (props.purchase.rating !== null) {
    parts.push(`rated ${props.purchase.rating}`);
  }
  return parts.join(", ");
});
</script>

<style scoped>
/* The wrapper lifts on hover, so the edit button moves with the tile. */
.library-tile-wrap {
  position: relative;
  transition: transform var(--transition-fast);
}

.library-tile-wrap:hover {
  transform: translateY(-2px);
}

.library-tile {
  position: relative;
  display: block;
  aspect-ratio: 3 / 4;
  overflow: hidden;
  border-radius: 10px;
  background: var(--color-bg-subtle);
  color: #fff;
  transition: box-shadow var(--transition-fast);
}

.library-tile-wrap:hover .library-tile {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
}

.library-tile:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.library-tile-cover {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.library-tile-placeholder {
  font-size: 1.5rem;
}

.library-tile-dot {
  position: absolute;
  top: 8px;
  left: 8px;
  z-index: 2;
  border: 1.5px solid rgba(0, 0, 0, 0.4);
}

.library-tile-rating {
  position: absolute;
  top: 6px;
  right: 6px;
  z-index: 2;
}

.library-tile-name {
  position: absolute;
  right: 0;
  bottom: 0;
  left: 0;
  z-index: 1;
  padding: 20px 8px 8px;
  background: linear-gradient(to top, rgba(0, 0, 0, 0.75) 0%, rgba(0, 0, 0, 0.35) 60%, transparent 100%);
  font-size: 0.7rem;
  font-weight: 500;
  line-height: 1.3;
  transition: opacity var(--transition-fast);
}

/* The hover panel repeats the name, so hide this one underneath it or it
   shows through the panel's translucent background as a second copy. */
.library-tile-wrap:hover .library-tile-name,
.library-tile-wrap:has(:focus-visible) .library-tile-name {
  opacity: 0;
}

.library-tile-hover {
  position: absolute;
  inset: 0;
  z-index: 3;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  padding: 10px;
  background: rgba(0, 0, 0, 0.65);
  opacity: 0;
  transition: opacity var(--transition-fast);
}

.library-tile-wrap:hover .library-tile-hover,
.library-tile-wrap:has(:focus-visible) .library-tile-hover {
  opacity: 1;
}

.library-tile-hover b:not(:last-child) {
  margin-bottom: 6px;
}

.library-tile-hover b {
  font-size: 0.8rem;
  font-weight: 600;
  line-height: 1.3;
}

.library-tile-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  align-items: center;
  color: rgba(255, 255, 255, 0.7);
  font-size: 0.65rem;
}

.library-tile-status {
  padding: 1px 6px;
  border-radius: 999px;
  color: #fff;
  font-size: 0.6rem;
  font-weight: 600;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

/* Edit button: in the rating badge's corner while the tile is hovered or
   focused (the hover panel repeats the rating), and always shown on touch
   screens, where there's no hover. */
.library-tile-edit {
  position: absolute;
  top: 6px;
  right: 6px;
  z-index: 4;
  display: grid;
  place-items: center;
  width: 30px;
  height: 30px;
  padding: 0;
  border: 1px solid rgba(255, 255, 255, 0.25);
  border-radius: 999px;
  background: rgba(0, 0, 0, 0.6);
  color: #fff;
  cursor: pointer;
  opacity: 0;
  transition:
    opacity var(--transition-fast),
    background-color var(--transition-fast);
}

.library-tile-wrap:hover .library-tile-edit,
.library-tile-wrap:has(:focus-visible) .library-tile-edit {
  opacity: 1;
}

.library-tile-edit:hover {
  background: var(--vglist-theme);
}

.library-tile-edit:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.library-tile-rating {
  transition: opacity var(--transition-fast);
}

@media (hover: hover) {
  .is-editable:hover .library-tile-rating,
  .is-editable:has(:focus-visible) .library-tile-rating {
    opacity: 0;
  }
}

@media (hover: none) {
  .library-tile-edit {
    opacity: 1;
  }

  .is-editable .library-tile-rating {
    right: 42px;
  }
}

@media (prefers-color-scheme: dark) {
  .library-tile-wrap:hover .library-tile {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.4);
  }
}

@media (prefers-reduced-motion: reduce) {
  .library-tile-wrap,
  .library-tile,
  .library-tile-name,
  .library-tile-hover,
  .library-tile-edit,
  .library-tile-rating {
    transition: none;
  }

  .library-tile-wrap:hover {
    transform: none;
  }
}
</style>
