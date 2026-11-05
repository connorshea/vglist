<template>
  <aside class="library-rail" aria-label="Library filters">
    <label class="library-rail-search">
      <span class="is-sr-only">Search library</span>
      <Search :size="14" aria-hidden="true" />
      <input
        :value="search"
        type="search"
        placeholder="Search library…"
        @input="emit('update:search', ($event.target as HTMLInputElement).value)"
      />
    </label>

    <section>
      <h2 class="library-rail-heading">Status</h2>
      <ul class="library-rail-list">
        <li>
          <button
            type="button"
            class="library-rail-item"
            :class="{ 'is-active': status === null }"
            :aria-pressed="status === null"
            @click="emit('update:status', null)"
          >
            All games
            <span class="library-rail-count">{{ gamesCount }}</span>
          </button>
        </li>
        <li v-for="s in statuses" :key="s.key">
          <button
            type="button"
            class="library-rail-item"
            :class="{ 'is-active': status === s.key }"
            :aria-pressed="status === s.key"
            @click="emit('update:status', s.key)"
          >
            <span class="status-dot" :class="s.className" aria-hidden="true"></span>
            {{ s.label }}
            <span class="library-rail-count">{{ statusCounts[s.key] ?? 0 }}</span>
          </button>
        </li>
      </ul>
    </section>

    <section v-if="platforms.length">
      <h2 class="library-rail-heading">Platform</h2>
      <ul class="library-rail-list">
        <li v-for="p in visiblePlatforms" :key="p.platform.id">
          <label class="library-rail-item library-rail-check">
            <input
              type="checkbox"
              :checked="platformIds.includes(p.platform.id)"
              @change="emit('toggle-platform', p.platform.id)"
            />
            <span class="library-rail-box" aria-hidden="true"><Check :size="12" :stroke-width="3" /></span>
            {{ p.platform.name }}
            <span class="library-rail-count">{{ p.count }}</span>
          </label>
        </li>
      </ul>
      <button
        v-if="platforms.length > COLLAPSED_COUNT"
        type="button"
        class="library-rail-more"
        :aria-expanded="showAllPlatforms"
        @click="showAllPlatforms = !showAllPlatforms"
      >
        {{ showAllPlatforms ? "Show fewer" : `Show ${platforms.length - COLLAPSED_COUNT} more` }}
      </button>
    </section>

    <section v-if="stores.length">
      <h2 class="library-rail-heading">Store</h2>
      <ul class="library-rail-list">
        <li v-for="s in visibleStores" :key="s.store.id">
          <label class="library-rail-item library-rail-check">
            <input
              type="checkbox"
              :checked="storeIds.includes(s.store.id)"
              @change="emit('toggle-store', s.store.id)"
            />
            <span class="library-rail-box" aria-hidden="true"><Check :size="12" :stroke-width="3" /></span>
            {{ s.store.name }}
            <span class="library-rail-count">{{ s.count }}</span>
          </label>
        </li>
      </ul>
      <button
        v-if="stores.length > COLLAPSED_COUNT"
        type="button"
        class="library-rail-more"
        :aria-expanded="showAllStores"
        @click="showAllStores = !showAllStores"
      >
        {{ showAllStores ? "Show fewer" : `Show ${stores.length - COLLAPSED_COUNT} more` }}
      </button>
    </section>

    <section>
      <h2 id="library-rating-heading" class="library-rail-heading">Your rating</h2>
      <div
        class="library-range"
        role="group"
        aria-labelledby="library-rating-heading"
        :style="{ '--range-min': `${localMin}%`, '--range-max': `${localMax}%` }"
      >
        <span class="library-range-track" aria-hidden="true"></span>
        <input
          v-model.number="localMin"
          type="range"
          min="0"
          max="100"
          step="5"
          aria-label="Minimum rating"
          @input="clampMin"
          @change="commitRating"
        />
        <input
          v-model.number="localMax"
          type="range"
          min="0"
          max="100"
          step="5"
          aria-label="Maximum rating"
          @input="clampMax"
          @change="commitRating"
        />
      </div>
      <div class="library-range-labels" aria-hidden="true">
        <span>{{ localMin }}</span>
        <span>{{ localMax }}</span>
      </div>
    </section>
  </aside>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from "vue";
import { debounce } from "lodash-es";
import { Check, Search } from "@lucide/vue";
import { LIBRARY_STATUSES, NO_STATUS, type LibraryStatusFilter } from "@/utils/library";

interface PlatformCount {
  platform: { id: string; name: string };
  count: number;
}

interface StoreCount {
  store: { id: string; name: string };
  count: number;
}

const props = defineProps<{
  search: string;
  status: LibraryStatusFilter | null;
  gamesCount: number;
  statusCounts: Partial<Record<LibraryStatusFilter, number>>;
  platforms: PlatformCount[];
  stores: StoreCount[];
  platformIds: string[];
  storeIds: string[];
  minRating: number | null;
  maxRating: number | null;
}>();

const emit = defineEmits<{
  "update:search": [value: string];
  "update:status": [value: LibraryStatusFilter | null];
  "toggle-platform": [id: string];
  "toggle-store": [id: string];
  "update:rating": [min: number | null, max: number | null];
}>();

// "No status" is only listed when some game has no status, or it's the active filter.
const statuses = computed(() =>
  (props.statusCounts.NONE ?? 0) > 0 || props.status === NO_STATUS.key
    ? [...LIBRARY_STATUSES, NO_STATUS]
    : LIBRARY_STATUSES
);

// Long lists of platforms or stores are cut short until the user asks for
// the rest, but a selected one always stays visible.
const COLLAPSED_COUNT = 6;
const showAllPlatforms = ref(false);
const showAllStores = ref(false);

const visiblePlatforms = computed(() =>
  showAllPlatforms.value
    ? props.platforms
    : props.platforms.filter((p, i) => i < COLLAPSED_COUNT || props.platformIds.includes(p.platform.id))
);
const visibleStores = computed(() =>
  showAllStores.value
    ? props.stores
    : props.stores.filter((s, i) => i < COLLAPSED_COUNT || props.storeIds.includes(s.store.id))
);

// The slider moves locally and only filters once it's let go, so dragging
// doesn't send a request for every step.
const localMin = ref(props.minRating ?? 0);
const localMax = ref(props.maxRating ?? 100);

watch(
  () => [props.minRating, props.maxRating],
  ([min, max]) => {
    localMin.value = min ?? 0;
    localMax.value = max ?? 100;
  }
);

function clampMin() {
  if (localMin.value > localMax.value) localMin.value = localMax.value;
}

function clampMax() {
  if (localMax.value < localMin.value) localMax.value = localMin.value;
}

// Arrow keys fire a change event per step, so wait for them to settle too.
const commitRating = debounce(() => {
  emit("update:rating", localMin.value === 0 ? null : localMin.value, localMax.value === 100 ? null : localMax.value);
}, 300);

onBeforeUnmount(() => commitRating.cancel());
</script>

<style scoped>
.library-rail {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.library-rail-search {
  display: flex;
  gap: 8px;
  align-items: center;
  height: 34px;
  padding: 0 10px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface);
  color: var(--color-text-tertiary);
}

.library-rail-search:focus-within {
  border-color: var(--color-accent);
  box-shadow: 0 0 0 2px color-mix(in srgb, var(--color-accent) 25%, transparent);
}

.library-rail-search input {
  flex: 1;
  min-width: 0;
  border: 0;
  outline: 0;
  background: transparent;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 0.8rem;
}

.library-rail-search input::placeholder {
  color: var(--color-text-tertiary);
}

.library-rail-heading {
  margin: 0 0 8px;
  color: var(--color-text-tertiary);
  font-size: 0.7rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.library-rail-list {
  display: flex;
  flex-direction: column;
  gap: 2px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.library-rail-item {
  position: relative;
  display: flex;
  gap: 8px;
  align-items: center;
  width: 100%;
  padding: 6px 8px;
  border: 0;
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--color-text-secondary);
  font: inherit;
  font-size: 0.8rem;
  text-align: left;
  cursor: pointer;
}

.library-rail-item:hover {
  background: var(--color-bg-subtle);
  color: var(--color-text-primary);
}

.library-rail-item:focus-visible,
.library-rail-check:focus-within {
  outline: 2px solid var(--color-accent);
  outline-offset: -2px;
}

.library-rail-item.is-active {
  background: var(--p-100);
  color: var(--p-700);
  font-weight: 500;
}

.library-rail-count {
  margin-left: auto;
  color: var(--color-text-tertiary);
  font-size: 0.7rem;
}

.library-rail-item.is-active .library-rail-count {
  color: var(--p-600);
}

/* The real checkbox stays in the accessibility tree and takes focus; the box
   next to it is what's drawn. */
.library-rail-check input {
  position: absolute;
  width: 1px;
  height: 1px;
  opacity: 0;
}

.library-rail-box {
  display: inline-flex;
  flex-shrink: 0;
  align-items: center;
  justify-content: center;
  width: 16px;
  height: 16px;
  border: 1.5px solid var(--color-border);
  border-radius: 4px;
  background: var(--color-surface);
  color: transparent;
}

.library-rail-check input:checked + .library-rail-box {
  border-color: var(--p-500);
  background: var(--p-500);
  color: #fff;
}

.library-rail-more {
  margin-top: 4px;
  padding: 4px 8px;
  border: 0;
  background: none;
  color: var(--color-accent);
  font: inherit;
  font-size: 0.75rem;
  font-weight: 500;
  cursor: pointer;
}

.library-rail-more:focus-visible {
  outline: 2px solid var(--color-accent);
  border-radius: var(--radius-sm);
}

/* Two native range inputs share one track, so each thumb stays keyboard- and
   screen-reader-operable on its own. */
.library-range {
  position: relative;
  height: 20px;
  margin: 8px 4px 0;
}

.library-range-track {
  position: absolute;
  top: 7px;
  right: 0;
  left: 0;
  height: 6px;
  border-radius: 3px;
  background: linear-gradient(
    to right,
    var(--color-border) var(--range-min),
    var(--p-500) var(--range-min),
    var(--p-500) var(--range-max),
    var(--color-border) var(--range-max)
  );
}

.library-range input {
  position: absolute;
  inset: 0;
  width: 100%;
  margin: 0;
  background: none;
  pointer-events: none;
  appearance: none;
}

.library-range input::-webkit-slider-thumb {
  width: 14px;
  height: 14px;
  border: 2px solid var(--p-500);
  border-radius: 50%;
  background: var(--color-surface);
  cursor: pointer;
  pointer-events: auto;
  appearance: none;
}

.library-range input::-moz-range-thumb {
  width: 10px;
  height: 10px;
  border: 2px solid var(--p-500);
  border-radius: 50%;
  background: var(--color-surface);
  cursor: pointer;
  pointer-events: auto;
}

.library-range input:focus-visible::-webkit-slider-thumb {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.library-range input:focus-visible::-moz-range-thumb {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.library-range-labels {
  display: flex;
  justify-content: space-between;
  margin-top: 4px;
  color: var(--color-text-secondary);
  font-size: 0.75rem;
}

@media (prefers-color-scheme: dark) {
  .library-rail-item.is-active {
    background: color-mix(in srgb, var(--p-500) 30%, transparent);
    color: var(--p-100);
  }

  .library-rail-item.is-active .library-rail-count {
    color: var(--p-200);
  }
}
</style>
