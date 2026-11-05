<template>
  <div class="series-tile" :class="{ 'can-edit': canEdit, 'menu-open': menuOpen }">
    <router-link :to="{ name: 'series', params: { id } }" class="series-link" :aria-label="accessibleName">
      <span class="series-mosaic" aria-hidden="true">
        <span v-for="(slot, i) in slots" :key="i" class="series-slot" :class="{ 'is-empty': !slot }">
          <template v-if="slot">
            <img v-if="slot.coverUrl" :src="slot.coverUrl" alt="" loading="lazy" />
            <span v-else class="series-slot-placeholder">{{ initials(slot.name) }}</span>
          </template>
        </span>
      </span>
      <span class="series-text" aria-hidden="true">
        <b class="series-name">{{ name }}</b>
        <span class="series-meta">{{ meta }}</span>
      </span>
      <ChevronRight v-if="!canEdit" class="series-chevron" :size="18" aria-hidden="true" />
    </router-link>

    <div v-if="canEdit" ref="menuWrapRef" class="series-actions">
      <button
        ref="menuButtonRef"
        type="button"
        class="series-more"
        aria-haspopup="menu"
        :aria-expanded="menuOpen"
        :aria-controls="menuId"
        :aria-label="`Actions for ${name}`"
        @click="toggleMenu"
        @keydown.down.prevent="openMenu"
      >
        <Ellipsis :size="18" aria-hidden="true" />
      </button>
      <div v-if="menuOpen" :id="menuId" ref="menuRef" class="series-menu" role="menu" @keydown="onMenuKeydown">
        <router-link :to="{ name: 'seriesEdit', params: { id } }" class="series-menu-item" role="menuitem">
          <Pencil :size="14" aria-hidden="true" />
          Edit series
        </router-link>
        <button type="button" class="series-menu-item is-danger" role="menuitem" @click="requestDelete">
          <Trash2 :size="14" aria-hidden="true" />
          Delete&hellip;
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, ref, watch } from "vue";
import { ChevronRight, Ellipsis, Pencil, Trash2 } from "@lucide/vue";
import { seriesMeta } from "./format";

interface CoverGame {
  id: string;
  name: string;
  coverUrl?: string | null;
}

const props = withDefaults(
  defineProps<{
    id: string;
    name: string;
    gamesCount: number;
    firstReleaseYear?: number | null;
    lastReleaseYear?: number | null;
    games: CoverGame[];
    canEdit?: boolean;
  }>(),
  { firstReleaseYear: null, lastReleaseYear: null, canEdit: false }
);

const emit = defineEmits<{ delete: [] }>();

const SLOT_COUNT = 4;

// Always four slots, so every tile's mosaic lines up; a series with fewer
// games shows empty slots.
const slots = computed(() => Array.from({ length: SLOT_COUNT }, (_, i): CoverGame | null => props.games[i] ?? null));

const meta = computed(() => seriesMeta(props.gamesCount, props.firstReleaseYear, props.lastReleaseYear));
const accessibleName = computed(() => `${props.name}, ${meta.value}`);

function initials(name: string): string {
  return name
    .split(/[\s:]+/)
    .filter((w) => w.length > 0)
    .slice(0, 2)
    .map((w) => w[0].toUpperCase())
    .join("");
}

// ── Actions menu (moderators and admins only) ──
const menuId = `series-menu-${props.id}`;
const menuOpen = ref(false);
const menuWrapRef = ref<HTMLElement | null>(null);
const menuButtonRef = ref<HTMLButtonElement | null>(null);
const menuRef = ref<HTMLElement | null>(null);

function menuItems(): HTMLElement[] {
  return Array.from(menuRef.value?.querySelectorAll<HTMLElement>('[role="menuitem"]') ?? []);
}

function openMenu() {
  menuOpen.value = true;
  void nextTick(() => menuItems()[0]?.focus());
}

function closeMenu(returnFocus = true) {
  if (!menuOpen.value) return;
  menuOpen.value = false;
  if (returnFocus) menuButtonRef.value?.focus();
}

function toggleMenu() {
  if (menuOpen.value) closeMenu();
  else openMenu();
}

function onMenuKeydown(e: KeyboardEvent) {
  const items = menuItems();
  const index = items.indexOf(document.activeElement as HTMLElement);
  switch (e.key) {
    case "ArrowDown":
      e.preventDefault();
      items[(index + 1) % items.length]?.focus();
      break;
    case "ArrowUp":
      e.preventDefault();
      items[(index - 1 + items.length) % items.length]?.focus();
      break;
    case "Home":
      e.preventDefault();
      items[0]?.focus();
      break;
    case "End":
      e.preventDefault();
      items[items.length - 1]?.focus();
      break;
    case "Escape":
      e.preventDefault();
      closeMenu();
      break;
    case "Tab":
      closeMenu(false);
      break;
  }
}

function requestDelete() {
  closeMenu(false);
  emit("delete");
}

function onDocumentPointerDown(e: PointerEvent) {
  if (menuWrapRef.value && !menuWrapRef.value.contains(e.target as Node)) closeMenu(false);
}

watch(menuOpen, (open) => {
  if (open) document.addEventListener("pointerdown", onDocumentPointerDown);
  else document.removeEventListener("pointerdown", onDocumentPointerDown);
});

onBeforeUnmount(() => document.removeEventListener("pointerdown", onDocumentPointerDown));
</script>

<style scoped>
.series-tile {
  position: relative;
  height: 100%;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background: var(--color-surface);
  transition: border-color var(--transition-fast);
}

/* Keep an open menu above the tiles after this one. */
.series-tile.menu-open {
  z-index: 5;
}

.series-tile:hover {
  border-color: var(--p-300);
}

.series-link {
  display: flex;
  flex-direction: column;
  height: 100%;
  border-radius: inherit;
  color: var(--color-text-primary);
  overflow: hidden;
}

.series-link:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.series-mosaic {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 3px;
  height: 132px;
  background: var(--color-bg-subtle);
}

.series-slot {
  display: block;
  min-width: 0;
  height: 100%;
  overflow: hidden;
}

.series-slot img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.series-slot-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #e879a0 0%, #c266d6 50%, #7c5ce7 100%);
  color: #fff;
  font-size: 15px;
  font-weight: 700;
  letter-spacing: 0.05em;
  user-select: none;
}

.series-text {
  display: block;
  min-width: 0;
  padding: 12px 14px 14px;
}

.can-edit .series-text {
  padding-right: 52px;
}

.series-name {
  display: block;
  overflow: hidden;
  font-size: 15px;
  font-weight: 600;
  line-height: 1.3;
  white-space: nowrap;
  text-overflow: ellipsis;
}

.series-meta {
  display: block;
  margin-top: 3px;
  font-size: 12.5px;
  color: var(--color-text-secondary);
  font-variant-numeric: tabular-nums;
}

.series-chevron {
  display: none;
}

.series-actions {
  position: absolute;
  right: 8px;
  bottom: 10px;
}

.series-more {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border: 0;
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--color-text-secondary);
  cursor: pointer;
}

.series-more:hover,
.series-more[aria-expanded="true"] {
  background: var(--color-bg-subtle);
  color: var(--color-text-primary);
}

.series-more:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 1px;
}

.series-menu {
  position: absolute;
  top: calc(100% + 4px);
  right: 0;
  z-index: 20;
  min-width: 170px;
  padding: 4px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background: var(--color-surface);
  box-shadow: var(--shadow-dialog, 0 8px 24px rgba(0, 0, 0, 0.18));
}

.series-menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 8px 10px;
  border: 0;
  border-radius: var(--radius-sm);
  background: none;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 13px;
  text-align: left;
  cursor: pointer;
}

.series-menu-item:hover,
.series-menu-item:focus-visible {
  background: var(--color-bg-subtle);
  outline: none;
}

.series-menu-item.is-danger {
  color: var(--r-500);
}

/* Phone: list rows with a small stack of covers instead of tiles. */
@media screen and (max-width: 768px) {
  .series-tile {
    border: 0;
    border-bottom: 1px solid var(--color-border);
    border-radius: 0;
    background: transparent;
  }

  .series-tile:hover {
    border-color: var(--color-border);
  }

  .series-link {
    flex-direction: row;
    align-items: center;
    gap: 12px;
    min-height: 76px;
    padding: 10px 0;
    overflow: visible;
  }

  .series-link:focus-visible {
    outline-offset: -2px;
  }

  .series-mosaic {
    position: relative;
    flex-shrink: 0;
    width: 66px;
    height: 56px;
    background: none;
  }

  .series-slot {
    position: absolute;
    top: 0;
    width: 42px;
    height: 56px;
    border-radius: 4px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.28);
  }

  .series-slot:nth-child(1) {
    left: 0;
    z-index: 3;
  }

  .series-slot:nth-child(2) {
    top: 3px;
    left: 12px;
    z-index: 2;
    height: 50px;
    opacity: 0.85;
  }

  .series-slot:nth-child(3) {
    top: 6px;
    left: 24px;
    z-index: 1;
    height: 44px;
    opacity: 0.7;
  }

  .series-slot:nth-child(4),
  .series-slot.is-empty:not(:first-child) {
    display: none;
  }

  .series-slot.is-empty {
    background: var(--color-bg-subtle);
    box-shadow: none;
  }

  .series-slot-placeholder {
    font-size: 12px;
  }

  .series-text {
    flex: 1;
    padding: 0;
  }

  .can-edit .series-text {
    padding-right: 44px;
  }

  .series-chevron {
    display: block;
    flex-shrink: 0;
    color: var(--color-text-tertiary);
  }

  .series-actions {
    top: 50%;
    right: 0;
    bottom: auto;
    transform: translateY(-50%);
  }

  .series-more {
    width: 44px;
    height: 44px;
  }
}
</style>
