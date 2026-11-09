<template>
  <router-link :to="`/games/${id}`" class="game-tile" :aria-label="accessibleName">
    <span ref="coverRef" class="game-tile-cover">
      <template v-if="coverUrl && !coverFailed">
        <img
          v-if="nearViewport || coverLoaded"
          :src="coverUrl"
          alt=""
          :loading="deferCover ? undefined : 'lazy'"
          @load="onCoverLoad"
          @error="onCoverError"
        />
      </template>
      <span v-else class="game-tile-placeholder" :style="placeholderStyle" aria-hidden="true">{{ initials }}</span>
      <span v-if="rating !== null" class="game-tile-rating" :class="`is-${ratingTier(rating)}`" aria-hidden="true">
        {{ Math.round(rating) }}
      </span>
      <span v-if="inLibrary" class="game-tile-owned" aria-hidden="true">
        <Check :size="11" :stroke-width="3" />
        {{ libraryBadgeLabel(completionStatus) }}
      </span>
    </span>
    <b class="game-tile-name" aria-hidden="true">{{ name }}</b>
    <span v-if="meta" class="game-tile-meta" aria-hidden="true">{{ meta }}</span>
  </router-link>
</template>

<script lang="ts">
// Covers that have loaded this session, which the browser has cached. A tile
// mounted again (the SWR cache re-renders a list instantly on back
// navigation) shows these in its first paint instead of waiting for the
// observer.
const loadedCovers = new Set<string>();
// Covers that failed to load this session. Their tiles show the initials, and
// don't request the cover again each time they scroll back into view.
const failedCovers = new Set<string>();
</script>

<script setup lang="ts">
import { computed, ref } from "vue";
import { Check } from "@lucide/vue";
import { coverPlaceholderStyle } from "@/utils/cover-placeholder";
import type { GamePurchaseCompletionStatus } from "@/types/graphql";
import { libraryBadgeLabel, ratingTier } from "./format";
import { useNearViewport } from "@/composables/useNearViewport";

const props = withDefaults(
  defineProps<{
    id: string;
    name: string;
    coverUrl: string | null;
    meta?: string | null;
    rating?: number | null;
    inLibrary?: boolean | null;
    completionStatus?: GamePurchaseCompletionStatus | null;
    // Wait for the tile to settle near the viewport before loading its cover,
    // for long grids that people scroll through fast. Otherwise the cover
    // lazy-loads, which also preloads ahead inside sideways-scrolling shelves.
    deferCover?: boolean;
  }>(),
  { meta: null, rating: null, inLibrary: false, completionStatus: null, deferCover: false }
);

// With `deferCover`, the cover only loads once the tile settles near the
// viewport. Otherwise a fast scroll starts a download for every tile it
// passes, and the covers where it stops wait behind all of them. If the tile
// leaves before its cover has loaded, the image is removed so a browser that
// drops unused image requests can stop it. A cover that has loaded stays.
const coverRef = ref<HTMLElement | null>(null);
const nearViewport = useNearViewport(coverRef, props.deferCover);
const loadedUrl = ref<string | null>(null);
// `loadedCovers` isn't reactive; `loadedUrl` changing re-evaluates this.
const coverLoaded = computed(
  () => !!props.coverUrl && (loadedUrl.value === props.coverUrl || loadedCovers.has(props.coverUrl))
);

const failedUrl = ref<string | null>(null);
const coverFailed = computed(
  () => !!props.coverUrl && (failedUrl.value === props.coverUrl || failedCovers.has(props.coverUrl))
);

function onCoverError() {
  if (props.coverUrl) {
    failedCovers.add(props.coverUrl);
    failedUrl.value = props.coverUrl;
  }
}

function onCoverLoad() {
  if (props.coverUrl) {
    loadedCovers.add(props.coverUrl);
    loadedUrl.value = props.coverUrl;
  }
}

const initials = computed(() =>
  props.name
    .split(/[\s:]+/)
    .filter((w) => w.length > 0)
    .slice(0, 3)
    .map((w) => w[0].toUpperCase())
    .join("")
);

const placeholderStyle = computed(() => coverPlaceholderStyle(props.name));

// One sentence for screen readers instead of reading the badges and meta line
// as separate fragments.
const accessibleName = computed(() => {
  const parts = [props.name];
  if (props.meta) {
    parts.push(props.meta);
  }
  if (props.rating !== null) {
    parts.push(`rated ${Math.round(props.rating)}`);
  }
  if (props.inLibrary) {
    parts.push(`in your library: ${libraryBadgeLabel(props.completionStatus).toLowerCase()}`);
  }
  return parts.join(", ");
});
</script>

<style scoped>
.game-tile {
  display: block;
  min-width: 0;
  color: var(--color-text-primary);
  border-radius: var(--radius-md);
}

.game-tile:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 3px;
}

.game-tile-cover {
  display: block;
  position: relative;
  aspect-ratio: 3 / 4;
  width: 100%;
  overflow: hidden;
  border-radius: 10px;
  /* The same fill as SkeletonBlock, so a cover that is still loading reads as
     loading. --color-bg-subtle matches the page background in dark mode, which
     left loading covers looking like empty boxes. */
  background: color-mix(in srgb, var(--color-text-primary) 9%, transparent);
  transition:
    transform var(--transition-fast),
    box-shadow var(--transition-fast);
}

.game-tile:hover .game-tile-cover {
  transform: translateY(-2px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
}

.game-tile-cover img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.game-tile-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  color: #fff;
  font-size: 28px;
  font-weight: 700;
  letter-spacing: 0.05em;
  user-select: none;
}

.game-tile-rating {
  position: absolute;
  top: 6px;
  right: 6px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 24px;
  height: 24px;
  padding: 0 5px;
  border-radius: var(--radius-sm);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.4);
  color: #fff;
  font-size: 10.4px;
  font-weight: 700;
}

.game-tile-rating.is-great {
  background: #16a34a;
}

.game-tile-rating.is-good {
  background: #2563eb;
}

.game-tile-rating.is-ok {
  background: #d97706;
}

.game-tile-rating.is-low {
  background: #dc2626;
}

.game-tile-owned {
  position: absolute;
  top: 6px;
  left: 6px;
  display: inline-flex;
  align-items: center;
  gap: 3px;
  max-width: calc(100% - 44px);
  padding: 2px 7px 2px 5px;
  border-radius: 999px;
  background: rgba(17, 11, 36, 0.72);
  backdrop-filter: blur(4px);
  color: #fff;
  font-size: 10px;
  font-weight: 600;
  white-space: nowrap;
}

.game-tile-name {
  display: block;
  margin-top: 8px;
  font-size: 13px;
  font-weight: 600;
  line-height: 1.3;
}

.game-tile:hover .game-tile-name {
  color: var(--color-accent);
}

.game-tile-meta {
  display: block;
  margin-top: 2px;
  font-size: 11.5px;
  color: var(--color-text-secondary);
}

@media (max-width: 768px) {
  /* Two lines, not one: at three tiles per row a single line cuts most titles
     down to a word or two ("Command & Co…"). Both lines are always reserved,
     so the meta lines in a row line up and a tile is the same height whatever
     its title (GameTileSkeleton relies on this). */
  .game-tile-name {
    display: -webkit-box;
    overflow: hidden;
    min-height: calc(2 * 1.3em);
    font-size: 12px;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 2;
    line-clamp: 2;
  }

  .game-tile-meta {
    font-size: 11px;
  }
}

@media (prefers-color-scheme: dark) {
  .game-tile:hover .game-tile-cover {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.4);
  }
}
</style>
