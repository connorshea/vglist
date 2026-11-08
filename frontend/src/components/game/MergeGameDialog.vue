<template>
  <Teleport to="body">
    <div
      v-if="modelValue"
      class="mg-overlay"
      role="dialog"
      aria-modal="true"
      aria-labelledby="merge-game-title"
      @keydown="onKeydown"
    >
      <div class="mg-backdrop" @click="close"></div>
      <div ref="dialogRef" class="mg-modal">
        <div class="mg-header">
          <h2 id="merge-game-title" class="mg-title">Merge into another game</h2>
          <button type="button" class="mg-close" aria-label="Close" :disabled="merging" @click="close">
            <X :size="18" aria-hidden="true" />
          </button>
        </div>

        <!-- Step 1: pick the game to keep -->
        <template v-if="!target">
          <p class="mg-desc">
            Pick the game to keep. <strong>{{ game.name }}</strong> will be merged into it and deleted.
          </p>

          <label class="mg-search">
            <span class="is-sr-only">Search for the game to keep</span>
            <Search :size="15" aria-hidden="true" />
            <input
              ref="inputRef"
              v-model="term"
              type="search"
              placeholder="Search games…"
              role="combobox"
              autocomplete="off"
              aria-autocomplete="list"
              :aria-expanded="results.length > 0"
              aria-controls="merge-game-results"
              :aria-activedescendant="activeIndex >= 0 ? `merge-game-${activeIndex}` : undefined"
              @keydown.down.prevent="move(1)"
              @keydown.up.prevent="move(-1)"
              @keydown.enter.prevent="chooseActive"
              @keydown.esc="clearSearch"
            />
          </label>

          <ul id="merge-game-results" class="mg-results" role="listbox" aria-label="Games">
            <li
              v-for="(result, index) in results"
              :id="`merge-game-${index}`"
              :key="result.id"
              role="option"
              class="mg-result"
              :class="{ 'is-active': index === activeIndex }"
              :aria-selected="index === activeIndex"
              @mousemove="activeIndex = index"
              @click="choose(result)"
            >
              <span class="mg-cover" aria-hidden="true">
                <img v-if="result.coverUrl" :src="result.coverUrl" alt="" />
                <span v-else>{{ gameInitials(result.name) }}</span>
              </span>
              <span class="mg-result-text">
                <span class="mg-result-name">{{ result.name }}</span>
                <span class="mg-result-meta">{{ describe(result) }}</span>
              </span>
            </li>
          </ul>
          <p v-if="searchError" class="mg-error" role="alert">{{ searchError.message }}</p>
          <p v-else-if="debouncedTerm && !loading && results.length === 0" class="mg-empty" role="status">
            No other games match “{{ debouncedTerm }}”.
          </p>
        </template>

        <!-- Step 2: confirm -->
        <template v-else>
          <div class="mg-pair">
            <div class="mg-pair-row is-deleted">
              <span class="mg-cover" aria-hidden="true">
                <img v-if="game.coverUrl" :src="game.coverUrl" alt="" />
                <span v-else>{{ gameInitials(game.name) }}</span>
              </span>
              <span class="mg-result-text">
                <span class="mg-pair-label">Deleted</span>
                <span class="mg-result-name">{{ game.name }}</span>
              </span>
            </div>
            <ArrowDown class="mg-pair-arrow" :size="16" aria-hidden="true" />
            <div class="mg-pair-row is-kept">
              <span class="mg-cover" aria-hidden="true">
                <img v-if="target.coverUrl" :src="target.coverUrl" alt="" />
                <span v-else>{{ gameInitials(target.name) }}</span>
              </span>
              <span class="mg-result-text">
                <span class="mg-pair-label">Kept</span>
                <span class="mg-result-name">{{ target.name }}</span>
                <span class="mg-result-meta">{{ describe(target) }}</span>
              </span>
            </div>
          </div>

          <div class="mg-warning">
            <TriangleAlert :size="16" aria-hidden="true" />
            <p>
              Library entries and favorites for <strong>{{ game.name }}</strong> move to
              <strong>{{ target.name }}</strong
              >. Anyone who has both keeps their <strong>{{ target.name }}</strong> entry. Then
              <strong>{{ game.name }}</strong> is deleted. This can't be undone.
            </p>
          </div>

          <p v-if="mergeError" class="mg-error" role="alert">{{ mergeError }}</p>

          <div class="mg-actions">
            <button type="button" class="mg-btn mg-btn-danger" :disabled="merging" @click="merge">
              <Merge :size="15" :stroke-width="2" aria-hidden="true" />
              {{ merging ? "Merging…" : "Merge and delete" }}
            </button>
            <button ref="backRef" type="button" class="mg-btn mg-btn-cancel" :disabled="merging" @click="back">
              Back
            </button>
          </div>
        </template>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, ref, watch } from "vue";
import { ArrowDown, Merge, Search, TriangleAlert, X } from "@lucide/vue";
import { useQuery } from "@/composables/useGraphQL";
import { gqlClient } from "@/graphql/client";
import { SEARCH_GAMES_TO_MERGE } from "@/graphql/queries/admin";
import { MERGE_GAMES } from "@/graphql/mutations/admin";
import type { MergeGamesMutation, SearchGamesToMergeQuery } from "@/types/graphql";
import { extractGqlError } from "@/utils/graphql-errors";
import { gameInitials } from "@/utils/library";

type Candidate = NonNullable<SearchGamesToMergeQuery["gameSearch"]>["nodes"][number];

const props = defineProps<{
  modelValue: boolean;
  // The game being merged away (and deleted).
  game: { id: string; name: string; coverUrl: string | null };
}>();

const emit = defineEmits<{
  "update:modelValue": [value: boolean];
  merged: [game: { id: string; name: string }];
}>();

const dialogRef = ref<HTMLElement | null>(null);
const inputRef = ref<HTMLInputElement | null>(null);
const backRef = ref<HTMLButtonElement | null>(null);
const term = ref("");
const debouncedTerm = ref("");
const activeIndex = ref(-1);
const target = ref<Candidate | null>(null);
const merging = ref(false);
const mergeError = ref("");
let debounceTimer: ReturnType<typeof setTimeout> | undefined;
let previouslyFocused: HTMLElement | null = null;

watch(term, (value) => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    debouncedTerm.value = value.trim();
  }, 250);
});

const {
  data,
  loading,
  error: searchError
} = useQuery<SearchGamesToMergeQuery>(SEARCH_GAMES_TO_MERGE, {
  variables: () => ({ query: debouncedTerm.value }),
  enabled: () => props.modelValue && debouncedTerm.value.length > 0
});

// A game can't be merged into itself, so it's never offered.
const results = computed(() =>
  debouncedTerm.value ? (data.value?.gameSearch?.nodes ?? []).filter((node) => node.id !== props.game.id) : []
);

watch(results, () => {
  activeIndex.value = results.value.length > 0 ? 0 : -1;
});

function describe(candidate: Candidate): string {
  const parts: string[] = [];
  if (candidate.releaseDate) {
    parts.push(candidate.releaseDate.slice(0, 4));
  }
  parts.push(`${candidate.ownerCount} ${candidate.ownerCount === 1 ? "owner" : "owners"}`);
  parts.push(`ID ${candidate.id}`);
  return parts.join(" · ");
}

function move(step: number) {
  if (results.value.length === 0) {
    return;
  }
  activeIndex.value = (activeIndex.value + step + results.value.length) % results.value.length;
}

function choose(candidate: Candidate) {
  target.value = candidate;
  mergeError.value = "";
  // Land on Back rather than the destructive button.
  void nextTick(() => backRef.value?.focus());
}

function chooseActive() {
  const candidate = results.value[activeIndex.value];
  if (candidate) {
    choose(candidate);
  }
}

// Escape in a non-empty search box clears it rather than closing the dialog.
// An empty box lets Escape through to close the dialog as usual.
function clearSearch(event: KeyboardEvent) {
  if (!term.value) {
    return;
  }
  event.preventDefault();
  event.stopPropagation();
  clearTimeout(debounceTimer);
  term.value = "";
  debouncedTerm.value = "";
}

function back() {
  target.value = null;
  mergeError.value = "";
  void nextTick(() => inputRef.value?.focus());
}

async function merge() {
  if (!target.value || merging.value) {
    return;
  }
  merging.value = true;
  mergeError.value = "";
  try {
    const result = await gqlClient.request<MergeGamesMutation>(MERGE_GAMES, {
      gameToKeepId: target.value.id,
      gameToMergeId: props.game.id
    });
    const kept = result.mergeGames?.game ?? { id: target.value.id, name: target.value.name };
    merging.value = false;
    emit("merged", kept);
    close();
  } catch (err) {
    mergeError.value = extractGqlError(err);
    merging.value = false;
  }
}

function close() {
  if (merging.value) {
    return;
  }
  emit("update:modelValue", false);
}

function onKeydown(event: KeyboardEvent) {
  if (event.key === "Escape") {
    close();
    return;
  }
  if (event.key !== "Tab" || !dialogRef.value) {
    return;
  }

  // Keep focus inside the dialog.
  const focusable = Array.from(dialogRef.value.querySelectorAll<HTMLElement>("button:not([disabled]), input"));
  if (focusable.length === 0) {
    return;
  }
  const first = focusable[0];
  const last = focusable[focusable.length - 1];
  if (event.shiftKey && document.activeElement === first) {
    event.preventDefault();
    last.focus();
  } else if (!event.shiftKey && document.activeElement === last) {
    event.preventDefault();
    first.focus();
  }
}

watch(
  () => props.modelValue,
  (open) => {
    if (open) {
      previouslyFocused = document.activeElement instanceof HTMLElement ? document.activeElement : null;
      term.value = "";
      debouncedTerm.value = "";
      target.value = null;
      mergeError.value = "";
      void nextTick(() => inputRef.value?.focus());
    } else {
      // After a merge the page navigates away, so there may be nothing to return to.
      if (previouslyFocused?.isConnected) {
        previouslyFocused.focus();
      }
      previouslyFocused = null;
    }
  }
);

onBeforeUnmount(() => clearTimeout(debounceTimer));
</script>

<style scoped>
.mg-overlay {
  position: fixed;
  inset: 0;
  z-index: 100;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding-top: 12vh;
}

.mg-backdrop {
  position: absolute;
  inset: 0;
  background: var(--dialog-scrim, rgba(0, 0, 0, 0.45));
}

.mg-modal {
  position: relative;
  width: calc(100% - 32px);
  max-width: 440px;
  max-height: 80vh;
  overflow-y: auto;
  padding: 20px;
  border-radius: 16px;
  background: var(--color-surface);
  box-shadow:
    0 16px 48px rgba(0, 0, 0, 0.12),
    0 2px 8px rgba(0, 0, 0, 0.06);
}

.mg-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.mg-title {
  margin: 0;
  color: var(--color-text-primary);
  font-size: 1.05rem;
  font-weight: 600;
}

.mg-close {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  margin-right: -8px;
  border: 0;
  border-radius: 8px;
  background: none;
  color: var(--color-text-secondary);
  cursor: pointer;
}

.mg-close:hover {
  background: var(--color-bg-subtle);
}

.mg-desc {
  margin: 4px 0 14px;
  color: var(--color-text-secondary);
  font-size: 0.85rem;
}

.mg-desc strong,
.mg-warning strong {
  color: var(--color-text-primary);
  font-weight: 600;
}

.mg-search {
  display: flex;
  gap: 8px;
  align-items: center;
  height: 40px;
  padding: 0 12px;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  background: var(--color-surface);
  color: var(--color-text-secondary);
}

.mg-search:focus-within {
  border-color: var(--color-accent);
}

.mg-search input {
  flex: 1;
  min-width: 0;
  border: 0;
  outline: 0;
  background: none;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 0.9rem;
}

.mg-results {
  margin: 8px 0 0;
  padding: 0;
  list-style: none;
}

.mg-result {
  display: flex;
  gap: 10px;
  align-items: center;
  min-height: 52px;
  padding: 6px 8px;
  border-radius: 8px;
  color: var(--color-text-primary);
  font-size: 0.9rem;
  cursor: pointer;
}

.mg-result.is-active {
  background: var(--color-bg-subtle);
  outline: 2px solid var(--color-accent);
  outline-offset: -2px;
}

.mg-cover {
  display: flex;
  flex-shrink: 0;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 40px;
  overflow: hidden;
  border-radius: 4px;
  background: var(--color-bg-subtle);
  color: var(--color-text-tertiary);
  font-size: 0.65rem;
  font-weight: 600;
}

.mg-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.mg-result-text {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.mg-result-name {
  overflow: hidden;
  color: var(--color-text-primary);
  font-weight: 500;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.mg-result-meta {
  color: var(--color-text-secondary);
  font-size: 0.78rem;
}

.mg-empty {
  margin: 12px 0 0;
  color: var(--color-text-secondary);
  font-size: 0.85rem;
}

.mg-error {
  margin: 12px 0 0;
  color: var(--color-danger-text);
  font-size: 0.85rem;
}

/* Confirmation step */
.mg-pair {
  display: flex;
  flex-direction: column;
  align-items: stretch;
  gap: 4px;
  margin: 14px 0;
}

.mg-pair-row {
  display: flex;
  gap: 10px;
  align-items: center;
  padding: 8px 10px;
  border: 1px solid var(--color-border);
  border-radius: 10px;
}

.mg-pair-row.is-deleted .mg-result-name {
  color: var(--color-text-secondary);
  text-decoration: line-through;
}

.mg-pair-row.is-kept {
  border-color: var(--color-accent);
}

.mg-pair-label {
  color: var(--color-text-tertiary);
  font-size: 0.7rem;
  font-weight: 600;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.mg-pair-row.is-deleted .mg-pair-label {
  color: var(--color-danger-text);
}

.mg-pair-row.is-kept .mg-pair-label {
  color: var(--color-accent);
}

.mg-pair-arrow {
  align-self: center;
  color: var(--color-text-tertiary);
}

.mg-warning {
  display: flex;
  gap: 10px;
  padding: 10px 12px;
  border-radius: 10px;
  background: var(--r-50);
  color: var(--color-text-secondary);
  font-size: 0.85rem;
  line-height: 1.5;
}

.mg-warning svg {
  flex-shrink: 0;
  margin-top: 2px;
  color: var(--color-danger-text);
}

.mg-warning p {
  margin: 0;
}

.mg-actions {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 16px;
}

.mg-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  width: 100%;
  padding: 12px;
  border: none;
  border-radius: 10px;
  font-family: inherit;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
}

.mg-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.mg-btn-danger {
  background: var(--r-500);
  color: #fff;
}

.mg-btn-cancel {
  border: 1px solid var(--color-border);
  background: transparent;
  color: var(--color-text-secondary);
}

.mg-btn-cancel:hover:not(:disabled) {
  background: var(--color-bg-subtle);
  color: var(--color-text-primary);
}

.mg-close:focus-visible,
.mg-btn:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

@media (prefers-color-scheme: dark) {
  .mg-modal {
    border: 1px solid var(--s-300);
    box-shadow:
      0 16px 48px rgba(0, 0, 0, 0.35),
      0 2px 8px rgba(0, 0, 0, 0.2);
  }

  .mg-warning {
    background: rgba(226, 75, 74, 0.12);
  }

  .mg-warning svg,
  .mg-error,
  .mg-pair-row.is-deleted .mg-pair-label {
    color: var(--r-200);
  }
}
</style>
