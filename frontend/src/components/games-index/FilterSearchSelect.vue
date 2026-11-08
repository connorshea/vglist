<template>
  <div class="filter-select">
    <div class="filter-select-control" :class="{ focused: open }">
      <input
        :id="inputId"
        ref="inputRef"
        v-model="search"
        class="filter-select-input"
        type="text"
        role="combobox"
        autocomplete="off"
        :placeholder="selectedName ?? placeholder"
        :class="{ 'has-value': !!selectedName }"
        :aria-expanded="open"
        :aria-controls="listboxId"
        aria-autocomplete="list"
        :aria-activedescendant="open && options[highlightIndex] ? optionId(highlightIndex) : undefined"
        @focus="onFocus"
        @blur="onBlur"
        @keydown="onKeydown"
      />
      <button
        v-if="modelValue"
        type="button"
        class="filter-select-clear"
        :aria-label="`Clear ${label.toLowerCase()} filter`"
        @click="clear"
      >
        <X :size="14" aria-hidden="true" />
      </button>
      <ChevronDown v-else :size="14" class="filter-select-chevron" aria-hidden="true" />
    </div>

    <ul v-show="open" :id="listboxId" class="filter-select-list" role="listbox" :aria-label="label">
      <li v-if="!search.trim()" class="filter-select-hint">Type to search</li>
      <li v-else-if="searching && options.length === 0" class="filter-select-hint">Searching...</li>
      <li v-else-if="options.length === 0" class="filter-select-hint">No results</li>
      <li
        v-for="(option, i) in options"
        :id="optionId(i)"
        :key="option.id"
        role="option"
        class="filter-select-option"
        :class="{ highlighted: i === highlightIndex }"
        :aria-selected="option.id === modelValue"
        @mousedown.prevent="select(option)"
        @mouseenter="highlightIndex = i"
      >
        {{ option.name }}
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, ref, useId, watch } from "vue";
import type { DocumentNode } from "graphql";
import { ChevronDown, X } from "@lucide/vue";
import { gqlClient } from "@/graphql/client";

interface Option {
  id: string;
  name: string;
}

const props = defineProps<{
  /** The selected record's ID, or "" for none. */
  modelValue: string;
  /** The selected record's name, shown in place of the placeholder. */
  selectedName: string | null;
  label: string;
  placeholder: string;
  inputId: string;
  /** A search query taking `$query: String!`. */
  query: DocumentNode;
  /** Pulls the list of results out of the query's response. */
  resultNodes: (data: unknown) => Option[];
}>();

const emit = defineEmits<{
  "update:modelValue": [value: string];
  select: [option: Option | null];
}>();

const uid = useId();
const listboxId = `${uid}-listbox`;
const optionId = (i: number) => `${uid}-option-${i}`;

const inputRef = ref<HTMLInputElement | null>(null);
const search = ref("");
const open = ref(false);
const options = ref<Option[]>([]);
const searching = ref(false);
const highlightIndex = ref(0);

let debounce: ReturnType<typeof setTimeout> | undefined;
let latestRequest = 0;

watch(search, (value) => {
  highlightIndex.value = 0;
  clearTimeout(debounce);
  const q = value.trim();
  if (!q) {
    options.value = [];
    searching.value = false;
    return;
  }
  searching.value = true;
  debounce = setTimeout(() => runSearch(q), 200);
});

async function runSearch(q: string) {
  const requestId = ++latestRequest;
  try {
    const data = await gqlClient.request(props.query, { query: q });
    if (requestId !== latestRequest) {
      return;
    }
    options.value = props.resultNodes(data);
  } catch {
    if (requestId !== latestRequest) {
      return;
    }
    options.value = [];
  } finally {
    if (requestId === latestRequest) {
      searching.value = false;
    }
  }
}

onBeforeUnmount(() => clearTimeout(debounce));

function onFocus() {
  open.value = true;
}

function onBlur() {
  open.value = false;
  search.value = "";
}

function select(option: Option) {
  emit("update:modelValue", option.id);
  emit("select", option);
  search.value = "";
  open.value = false;
  inputRef.value?.blur();
}

function clear() {
  emit("update:modelValue", "");
  emit("select", null);
  inputRef.value?.focus();
}

function onKeydown(e: KeyboardEvent) {
  if (e.key === "ArrowDown") {
    e.preventDefault();
    open.value = true;
    if (highlightIndex.value < options.value.length - 1) {
      highlightIndex.value++;
    }
  } else if (e.key === "ArrowUp") {
    e.preventDefault();
    if (highlightIndex.value > 0) {
      highlightIndex.value--;
    }
  } else if (e.key === "Enter") {
    const option = options.value[highlightIndex.value];
    if (open.value && option) {
      e.preventDefault();
      select(option);
    }
  } else if (e.key === "Escape" && (open.value || search.value)) {
    // Close just the list, not a dialog this sits in.
    e.stopPropagation();
    open.value = false;
    search.value = "";
  }
}
</script>

<style scoped>
.filter-select {
  position: relative;
}

.filter-select-control {
  display: flex;
  align-items: center;
  height: 34px;
  padding: 0 10px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface);
  transition: border-color var(--transition-fast);
}

.filter-select-control.focused {
  border-color: var(--color-accent);
  box-shadow: 0 0 0 2px color-mix(in srgb, var(--color-accent) 25%, transparent);
}

.filter-select-input {
  flex: 1;
  min-width: 0;
  border: none;
  outline: none;
  background: transparent;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 13px;
  /* Inputs can't be trimmed with text-box, and Inter's tall ascent leaves the
     text sitting high in its line box. Moving the padding to the top drops it
     back to the middle of the control. */
  padding-block: 3px 0;
}

.filter-select-input::placeholder {
  color: var(--color-placeholder);
}

.filter-select-input.has-value::placeholder {
  color: var(--color-text-primary);
}

.filter-select-chevron {
  color: var(--color-text-tertiary);
  flex-shrink: 0;
}

.filter-select-clear {
  display: flex;
  align-items: center;
  padding: 2px;
  border: none;
  border-radius: 4px;
  background: none;
  color: var(--color-text-secondary);
  cursor: pointer;
}

.filter-select-clear:hover {
  color: var(--color-text-primary);
}

.filter-select-clear:focus-visible {
  outline: 2px solid var(--color-accent);
}

.filter-select-list {
  position: absolute;
  z-index: 20;
  top: calc(100% + 4px);
  left: 0;
  right: 0;
  max-height: 240px;
  overflow-y: auto;
  padding: 4px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
}

.filter-select-option {
  padding: 6px 8px;
  border-radius: 4px;
  font-size: 13px;
  color: var(--color-text-primary);
  cursor: pointer;
}

.filter-select-option.highlighted {
  background: var(--color-bg-subtle);
}

.filter-select-option[aria-selected="true"] {
  font-weight: 600;
  color: var(--color-accent);
}

.filter-select-hint {
  padding: 6px 8px;
  font-size: 12px;
  color: var(--color-text-tertiary);
}
</style>
