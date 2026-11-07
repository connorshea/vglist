<template>
  <div class="resource-index">
    <div class="page-header">
      <div class="page-heading">
        <h1 class="page-title">{{ title }}</h1>
        <span v-if="totalCount !== null" class="page-sub" aria-live="polite">{{
          countLabel(totalCount, kind, kindPlural)
        }}</span>
      </div>
      <router-link v-if="canEdit" :to="newTo" class="new-btn">
        <Plus :size="15" aria-hidden="true" />
        <span class="new-btn-label">New {{ kind }}</span>
      </router-link>
    </div>

    <div class="toolbar">
      <label class="search">
        <Search :size="15" aria-hidden="true" />
        <span class="is-sr-only">Search {{ kindPlural }}</span>
        <input v-model="search" type="search" :placeholder="`Search ${kindPlural}…`" autocomplete="off" />
      </label>
      <span class="grow"></span>
      <div class="seg" role="group" :aria-label="`Sort ${kindPlural}`">
        <router-link
          v-for="link in sortLinks"
          :key="link.label"
          :to="link.to"
          class="seg-btn"
          :class="{ 'is-active': link.active }"
          :aria-current="link.active ? 'true' : undefined"
        >
          {{ link.label }}
        </router-link>
      </div>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load {{ kindPlural }}: {{ error.message }}</p>
    </div>

    <div v-if="!loaded && loading" class="loading-more" role="status">
      <span class="spinner" aria-hidden="true"></span>
      Loading {{ kindPlural }}&hellip;
    </div>
    <div v-else-if="loaded && items.length === 0" class="empty-state">
      <p v-if="nameFilter">No {{ kindPlural }} match &ldquo;{{ nameFilter }}&rdquo;.</p>
      <p v-else>No {{ kindPlural }} yet.</p>
    </div>

    <ul v-if="items.length" class="resource-grid" :class="{ 'is-stale': refreshing }">
      <li v-for="item in items" :key="item.id">
        <ResourceTile
          :id="item.id"
          :name="item.name"
          :meta="item.meta"
          :cover-games="item.coverGames"
          :to="item.to"
          :edit-to="item.editTo"
          :kind="kind"
          :can-edit="canEdit"
          @delete="itemToDelete = item"
        />
      </li>
    </ul>

    <div v-if="hasNextPage" ref="sentinelRef" class="loading-more">
      <template v-if="loadingMore">
        <span class="spinner" aria-hidden="true"></span>
        <span role="status">Loading more {{ kindPlural }}&hellip;</span>
      </template>
      <button v-else type="button" class="load-more-btn" @click="emit('loadMore')">Load more {{ kindPlural }}</button>
    </div>

    <ConfirmDialog
      v-model="showDeleteConfirm"
      :title="`Delete ${kind}?`"
      :confirm-label="`Delete ${kind}`"
      loading-label="Deleting…"
      :loading="deleting"
      @confirm="confirmDelete"
    >
      <template #icon>
        <CircleAlert :size="22" :stroke-width="1.8" />
      </template>
      <strong>{{ itemToDelete?.name }}</strong> will be permanently deleted, and {{ deleteConsequence }} This cannot be
      undone.
    </ConfirmDialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from "vue";
import type { RouteLocationRaw } from "vue-router";
import { CircleAlert, Plus, Search } from "@lucide/vue";
import { countLabel } from "@/components/games-index/format";
import ConfirmDialog from "@/components/ConfirmDialog.vue";
import type { ResourceIndexSortLink } from "@/composables/useResourceIndex";
import ResourceTile from "./ResourceTile.vue";

export interface ResourceIndexItem {
  id: string;
  name: string;
  meta: string;
  coverGames: { id: string; name: string; coverUrl?: string | null }[];
  to: RouteLocationRaw;
  editTo: RouteLocationRaw;
}

const props = defineProps<{
  title: string;
  /** "series", "genre", "platform", "company" or "engine". */
  kind: string;
  kindPlural: string;
  items: ResourceIndexItem[];
  totalCount: number | null;
  sortLinks: ResourceIndexSortLink[];
  nameFilter: string;
  newTo: RouteLocationRaw;
  /** Moderators and admins: shows New and each tile's edit/delete menu. */
  canEdit: boolean;
  /** The rest of the delete warning, e.g. "removed from every game in it." */
  deleteConsequence: string;
  loaded: boolean;
  loading: boolean;
  loadingMore: boolean;
  refreshing: boolean;
  hasNextPage: boolean;
  deleting: boolean;
  error: Error | null;
}>();

const emit = defineEmits<{
  loadMore: [];
  delete: [item: ResourceIndexItem, done: () => void];
}>();

const search = defineModel<string>("search", { required: true });

// ── Delete ──
const itemToDelete = ref<ResourceIndexItem | null>(null);
const showDeleteConfirm = computed({
  get: () => itemToDelete.value !== null,
  set: (open) => {
    if (!open) itemToDelete.value = null;
  }
});

function confirmDelete() {
  const item = itemToDelete.value;
  if (!item) return;
  // The page runs the mutation and closes the dialog when it's finished.
  emit("delete", item, () => (itemToDelete.value = null));
}

// ── Loading more ──
// Load the next page as the end of the grid scrolls into view. The "Load
// more" button stays as a fallback for keyboards and when this doesn't fire.
const sentinelRef = ref<HTMLElement | null>(null);
let observer: IntersectionObserver | undefined;

watch(sentinelRef, (el, oldEl) => {
  if (oldEl) observer?.unobserve(oldEl);
  if (el) observer?.observe(el);
});

onMounted(() => {
  observer = new IntersectionObserver(
    (entries) => {
      if (entries.some((entry) => entry.isIntersecting) && !props.loadingMore) emit("loadMore");
    },
    { rootMargin: "600px 0px" }
  );
  if (sentinelRef.value) observer.observe(sentinelRef.value);
});

onBeforeUnmount(() => observer?.disconnect());
</script>

<style scoped>
.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 20px;
}

.page-heading {
  display: flex;
  align-items: baseline;
  flex-wrap: wrap;
  gap: 12px;
}

.page-title {
  font-size: 24px;
  font-weight: 600;
  letter-spacing: -0.3px;
  color: var(--color-text-primary);
}

.page-sub {
  font-size: 13px;
  color: var(--color-text-secondary);
}

.new-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 32px;
  padding: 0 14px;
  border-radius: var(--radius-sm);
  background: var(--p-500);
  color: #fff;
  font-size: 13px;
  font-weight: 600;
}

/* Trimmed to cap height and baseline so the letters, not the line box, are
   centered next to the icon. */
.new-btn-label {
  text-box: trim-both cap alphabetic;
}

.new-btn:hover {
  background: var(--p-600);
  color: #fff;
}

.new-btn:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.toolbar {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 24px;
}

.grow {
  flex: 1;
}

.search {
  display: flex;
  flex: 1;
  align-items: center;
  gap: 8px;
  min-width: 240px;
  max-width: 420px;
  height: 38px;
  padding: 0 10px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface);
  color: var(--color-text-secondary);
}

.search:focus-within {
  border-color: var(--color-accent);
  box-shadow: 0 0 0 2px color-mix(in srgb, var(--color-accent) 25%, transparent);
}

.search input {
  flex: 1;
  min-width: 0;
  height: 100%;
  border: 0;
  background: transparent;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 14px;
  outline: none;
}

.search input::placeholder {
  color: var(--color-text-tertiary);
}

.seg {
  display: inline-flex;
  max-width: 100%;
  overflow-x: auto;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface);
}

.seg-btn {
  position: relative;
  padding: 8px 14px;
  font-size: 13px;
  white-space: nowrap;
  color: var(--color-text-secondary);
}

.seg-btn + .seg-btn::before {
  content: "";
  position: absolute;
  top: 25%;
  left: 0;
  width: 1px;
  height: 50%;
  background: var(--color-border);
}

.seg-btn:hover {
  color: var(--color-text-primary);
}

.seg-btn.is-active {
  background: color-mix(in srgb, var(--color-accent) 14%, transparent);
  color: var(--color-accent);
  font-weight: 500;
}

.seg-btn:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: -2px;
}

.resource-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 16px;
  transition: opacity var(--transition-fast);
}

.resource-grid.is-stale {
  opacity: 0.55;
}

.empty-state {
  padding: 48px 0;
  text-align: center;
  color: var(--color-text-secondary);
}

.loading-more {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 32px 0 64px;
  font-size: 13px;
  color: var(--color-text-secondary);
}

.spinner {
  width: 16px;
  height: 16px;
  border: 2px solid var(--color-border);
  border-top-color: var(--p-500);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

@media (prefers-reduced-motion: reduce) {
  .spinner {
    animation-duration: 2.4s;
  }
}

.load-more-btn {
  padding: 7px 18px;
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius-button);
  background: transparent;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 13px;
  cursor: pointer;
}

.load-more-btn:hover {
  border-color: var(--p-300);
}

.load-more-btn:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

@media (prefers-color-scheme: dark) {
  .seg-btn.is-active {
    background: color-mix(in srgb, var(--p-300) 22%, transparent);
    color: var(--p-100);
  }
}

/* Phone: search on its own row, full-width sort, rows instead of tiles. */
@media screen and (max-width: 768px) {
  .page-title {
    font-size: 20px;
  }

  .search {
    flex-basis: 100%;
    max-width: none;
    height: 44px;
  }

  .grow {
    display: none;
  }

  .seg {
    display: flex;
    width: 100%;
  }

  .seg-btn {
    flex: 1 1 auto;
    padding: 10px 8px;
    text-align: center;
  }

  .toolbar {
    margin-bottom: 4px;
  }

  .resource-grid {
    grid-template-columns: 1fr;
    gap: 0;
  }
}
</style>
