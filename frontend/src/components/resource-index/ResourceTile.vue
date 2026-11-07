<template>
  <div class="resource-tile" :class="{ 'can-edit': canEdit, 'menu-open': menuOpen }">
    <router-link :to="to" class="tile-link" :aria-label="accessibleName">
      <span v-if="coverGames.length === 0" class="tile-mosaic is-placeholder" aria-hidden="true">
        <span class="tile-placeholder">{{ initials(name) }}</span>
      </span>
      <span v-else class="tile-mosaic" aria-hidden="true">
        <span v-for="(slot, i) in slots" :key="i" class="tile-slot" :class="{ 'is-empty': !slot }">
          <template v-if="slot">
            <img v-if="slot.coverUrl" :src="slot.coverUrl" alt="" loading="lazy" />
            <span v-else class="tile-slot-placeholder">{{ initials(slot.name) }}</span>
          </template>
        </span>
      </span>
      <span class="tile-text" aria-hidden="true">
        <b class="tile-name">{{ name }}</b>
        <span class="tile-meta">{{ meta }}</span>
      </span>
      <ChevronRight v-if="!canEdit" class="tile-chevron" :size="18" aria-hidden="true" />
    </router-link>

    <div v-if="canEdit" ref="menuWrapRef" class="tile-actions">
      <button
        ref="menuButtonRef"
        type="button"
        class="tile-more"
        aria-haspopup="menu"
        :aria-expanded="menuOpen"
        :aria-controls="menuId"
        :aria-label="`Actions for ${name}`"
        @click="toggleMenu"
        @keydown.down.prevent="openMenu"
      >
        <Ellipsis :size="18" aria-hidden="true" />
      </button>
      <div v-if="menuOpen" :id="menuId" ref="menuRef" class="tile-menu" role="menu" @keydown="onMenuKeydown">
        <router-link :to="editTo" class="tile-menu-item" role="menuitem">
          <Pencil :size="14" aria-hidden="true" />
          Edit {{ kind }}
        </router-link>
        <button type="button" class="tile-menu-item is-danger" role="menuitem" @click="requestDelete">
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
import type { RouteLocationRaw } from "vue-router";

interface CoverGame {
  id: string;
  name: string;
  coverUrl?: string | null;
}

const props = withDefaults(
  defineProps<{
    id: string;
    name: string;
    /** "38 games · 1996–2025" */
    meta: string;
    /** Up to four games whose covers make up the mosaic. */
    coverGames: CoverGame[];
    to: RouteLocationRaw;
    editTo: RouteLocationRaw;
    /** "series", "genre", "platform", "company" or "engine", for the menu. */
    kind: string;
    canEdit?: boolean;
  }>(),
  { canEdit: false }
);

const emit = defineEmits<{ delete: [] }>();

const SLOT_COUNT = 4;

// Always four slots, so every tile's mosaic lines up; a tile with fewer
// covers shows empty slots.
const slots = computed(() =>
  Array.from({ length: SLOT_COUNT }, (_, i): CoverGame | null => props.coverGames[i] ?? null)
);

const accessibleName = computed(() => `${props.name}, ${props.meta}`);

function initials(name: string): string {
  return name
    .split(/[\s:]+/)
    .filter((w) => w.length > 0)
    .slice(0, 2)
    .map((w) => w[0].toUpperCase())
    .join("");
}

// ── Actions menu (moderators and admins only) ──
const menuId = `${props.kind}-menu-${props.id}`;
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
.resource-tile {
  position: relative;
  height: 100%;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background: var(--color-surface);
  transition: border-color var(--transition-fast);
}

/* Keep an open menu above the tiles after this one. */
.resource-tile.menu-open {
  z-index: 5;
}

.resource-tile:hover {
  border-color: var(--p-300);
}

.tile-link {
  display: flex;
  flex-direction: column;
  height: 100%;
  border-radius: inherit;
  color: var(--color-text-primary);
  overflow: hidden;
}

.tile-link:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.tile-mosaic {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 3px;
  height: 132px;
  background: var(--color-bg-subtle);
}

.tile-slot {
  display: block;
  min-width: 0;
  height: 100%;
  overflow: hidden;
}

.tile-slot img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.tile-slot-placeholder {
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

/* No covers at all (e.g. a platform whose games have no art yet): one
   gradient panel with the resource's initials, like a game's missing cover. */
.tile-mosaic.is-placeholder {
  display: block;
}

.tile-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #e879a0 0%, #c266d6 50%, #7c5ce7 100%);
  color: #fff;
  font-size: 32px;
  font-weight: 700;
  letter-spacing: 0.05em;
  user-select: none;
}

.tile-text {
  display: block;
  min-width: 0;
  padding: 12px 14px 14px;
}

.can-edit .tile-text {
  padding-right: 52px;
}

.tile-name {
  display: block;
  overflow: hidden;
  font-size: 15px;
  font-weight: 600;
  line-height: 1.3;
  white-space: nowrap;
  text-overflow: ellipsis;
}

.tile-meta {
  display: block;
  margin-top: 3px;
  font-size: 12.5px;
  color: var(--color-text-secondary);
  font-variant-numeric: tabular-nums;
}

.tile-chevron {
  display: none;
}

.tile-actions {
  position: absolute;
  right: 8px;
  bottom: 10px;
}

.tile-more {
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

.tile-more:hover,
.tile-more[aria-expanded="true"] {
  background: var(--color-bg-subtle);
  color: var(--color-text-primary);
}

.tile-more:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 1px;
}

.tile-menu {
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

.tile-menu-item {
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

.tile-menu-item:hover,
.tile-menu-item:focus-visible {
  background: var(--color-bg-subtle);
  outline: none;
}

.tile-menu-item.is-danger {
  color: var(--color-danger-text);
}

/* Phone: list rows with a small stack of covers instead of tiles. */
@media screen and (max-width: 768px) {
  .resource-tile {
    border: 0;
    border-bottom: 1px solid var(--color-border);
    border-radius: 0;
    background: transparent;
  }

  .resource-tile:hover {
    border-color: var(--color-border);
  }

  .tile-link {
    flex-direction: row;
    align-items: center;
    gap: 12px;
    min-height: 76px;
    padding: 10px 0;
    overflow: visible;
  }

  .tile-link:focus-visible {
    outline-offset: -2px;
  }

  .tile-mosaic {
    position: relative;
    flex-shrink: 0;
    width: 66px;
    height: 56px;
    background: none;
  }

  .tile-slot {
    position: absolute;
    top: 0;
    width: 42px;
    height: 56px;
    border-radius: 4px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.28);
  }

  .tile-slot:nth-child(1) {
    left: 0;
    z-index: 3;
  }

  .tile-slot:nth-child(2) {
    top: 3px;
    left: 12px;
    z-index: 2;
    height: 50px;
    opacity: 0.85;
  }

  .tile-slot:nth-child(3) {
    top: 6px;
    left: 24px;
    z-index: 1;
    height: 44px;
    opacity: 0.7;
  }

  .tile-slot:nth-child(4),
  .tile-slot.is-empty:not(:first-child) {
    display: none;
  }

  .tile-slot.is-empty {
    background: var(--color-bg-subtle);
    box-shadow: none;
  }

  .tile-slot-placeholder {
    font-size: 12px;
  }

  /* Same width as the stacked covers so names line up across rows. */
  .tile-placeholder {
    width: 42px;
    border-radius: 4px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.28);
    font-size: 13px;
  }

  .tile-text {
    flex: 1;
    padding: 0;
  }

  .can-edit .tile-text {
    padding-right: 44px;
  }

  .tile-chevron {
    display: block;
    flex-shrink: 0;
    color: var(--color-text-tertiary);
  }

  .tile-actions {
    top: 50%;
    right: 0;
    bottom: auto;
    transform: translateY(-50%);
  }

  .tile-more {
    width: 44px;
    height: 44px;
  }
}
</style>
