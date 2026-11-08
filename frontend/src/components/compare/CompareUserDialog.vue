<template>
  <Teleport to="body">
    <div
      v-if="modelValue"
      class="cu-overlay"
      role="dialog"
      aria-modal="true"
      aria-labelledby="compare-user-title"
      @keydown="onKeydown"
    >
      <div class="cu-backdrop" @click="close"></div>
      <div ref="dialogRef" class="cu-modal">
        <div class="cu-header">
          <h2 id="compare-user-title" class="cu-title">Compare with someone else</h2>
          <button type="button" class="cu-close" aria-label="Close" @click="close">
            <X :size="18" aria-hidden="true" />
          </button>
        </div>
        <p class="cu-desc">
          Pick someone to compare <strong>{{ username }}</strong
          >'s library with.
        </p>

        <label class="cu-search">
          <span class="is-sr-only">Search users</span>
          <Search :size="15" aria-hidden="true" />
          <input
            ref="inputRef"
            v-model="term"
            type="search"
            placeholder="Search by username…"
            role="combobox"
            autocomplete="off"
            aria-autocomplete="list"
            :aria-expanded="results.length > 0"
            aria-controls="compare-user-results"
            :aria-activedescendant="activeIndex >= 0 ? `compare-user-${activeIndex}` : undefined"
            @keydown.down.prevent="move(1)"
            @keydown.up.prevent="move(-1)"
            @keydown.enter.prevent="chooseActive"
          />
        </label>

        <ul id="compare-user-results" class="cu-results" role="listbox" aria-label="Users">
          <li
            v-for="(user, index) in results"
            :id="`compare-user-${index}`"
            :key="user.id"
            role="option"
            class="cu-result"
            :class="{ 'is-active': index === activeIndex }"
            :aria-selected="index === activeIndex"
            @mousemove="activeIndex = index"
            @click="choose(user.slug)"
          >
            <UserAvatar :user="user" :size="28" />
            <span>{{ user.username }}</span>
          </li>
        </ul>
        <p v-if="debouncedTerm && !loading && results.length === 0" class="cu-empty" role="status">
          No other users match “{{ debouncedTerm }}”.
        </p>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, ref, watch } from "vue";
import { Search, X } from "@lucide/vue";
import { useQuery } from "@/composables/useGraphQL";
import { SEARCH_USERS_TO_COMPARE } from "@/graphql/queries/compare";
import type { SearchUsersToCompareQuery } from "@/types/graphql";
import { useAuthStore } from "@/stores/auth";
import UserAvatar from "@/components/game/UserAvatar.vue";

const props = defineProps<{
  modelValue: boolean;
  // Whose library the picked user is compared with.
  username: string;
  // Users not worth offering, i.e. the two already being compared.
  exclude: string[];
}>();

const emit = defineEmits<{
  "update:modelValue": [value: boolean];
  select: [slug: string];
}>();

const authStore = useAuthStore();
const dialogRef = ref<HTMLElement | null>(null);
const inputRef = ref<HTMLInputElement | null>(null);
const term = ref("");
const debouncedTerm = ref("");
const activeIndex = ref(-1);
let debounceTimer: ReturnType<typeof setTimeout> | undefined;
let previouslyFocused: HTMLElement | null = null;

watch(term, (value) => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    debouncedTerm.value = value.trim();
  }, 250);
});

const { data, loading } = useQuery<SearchUsersToCompareQuery>(SEARCH_USERS_TO_COMPARE, {
  variables: () => ({ query: debouncedTerm.value }),
  enabled: () => props.modelValue && debouncedTerm.value.length > 0
});

// Leave out the users whose libraries the server would refuse to compare:
// banned and private users, except for admins, who can see every library. (A
// private user who follows the viewer could be compared, but the search
// doesn't say who does, so they're left out too.)
function comparable(user: { privacy: string; banned: boolean }): boolean {
  return authStore.isAdmin || (!user.banned && user.privacy !== "PRIVATE_ACCOUNT");
}

const results = computed(() =>
  debouncedTerm.value
    ? (data.value?.userSearch?.nodes ?? []).filter((user) => !props.exclude.includes(user.slug) && comparable(user))
    : []
);

watch(results, () => {
  activeIndex.value = results.value.length > 0 ? 0 : -1;
});

function move(step: number) {
  if (results.value.length === 0) {
    return;
  }
  activeIndex.value = (activeIndex.value + step + results.value.length) % results.value.length;
}

function choose(slug: string) {
  emit("select", slug);
  close();
}

function chooseActive() {
  const user = results.value[activeIndex.value];
  if (user) {
    choose(user.slug);
  }
}

function close() {
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
  const focusable = Array.from(dialogRef.value.querySelectorAll<HTMLElement>("button, input"));
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
      void nextTick(() => inputRef.value?.focus());
    } else {
      previouslyFocused?.focus();
      previouslyFocused = null;
    }
  }
);

onBeforeUnmount(() => clearTimeout(debounceTimer));
</script>

<style scoped>
.cu-overlay {
  position: fixed;
  inset: 0;
  z-index: 100;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding-top: 12vh;
}

.cu-backdrop {
  position: absolute;
  inset: 0;
  background: var(--dialog-scrim, rgba(0, 0, 0, 0.45));
}

.cu-modal {
  position: relative;
  width: calc(100% - 32px);
  max-width: 420px;
  padding: 20px;
  border-radius: 16px;
  background: var(--color-surface);
  box-shadow:
    0 16px 48px rgba(0, 0, 0, 0.12),
    0 2px 8px rgba(0, 0, 0, 0.06);
}

.cu-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.cu-title {
  margin: 0;
  color: var(--color-text-primary);
  font-size: 1.05rem;
  font-weight: 600;
}

.cu-close {
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

.cu-close:hover {
  background: var(--color-bg-subtle);
}

.cu-desc {
  margin: 4px 0 14px;
  color: var(--color-text-secondary);
  font-size: 0.85rem;
}

.cu-desc strong {
  color: var(--color-text-primary);
}

.cu-search {
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

.cu-search:focus-within {
  border-color: var(--color-accent);
}

.cu-search input {
  flex: 1;
  min-width: 0;
  border: 0;
  outline: 0;
  background: none;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 0.9rem;
}

.cu-results {
  margin: 8px 0 0;
  padding: 0;
  list-style: none;
}

.cu-result {
  display: flex;
  gap: 10px;
  align-items: center;
  min-height: 44px;
  padding: 6px 8px;
  border-radius: 8px;
  color: var(--color-text-primary);
  font-size: 0.9rem;
  cursor: pointer;
}

.cu-result.is-active {
  background: var(--color-bg-subtle);
  outline: 2px solid var(--color-accent);
  outline-offset: -2px;
}

.cu-empty {
  margin: 12px 0 0;
  color: var(--color-text-secondary);
  font-size: 0.85rem;
}

.cu-close:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}
</style>
