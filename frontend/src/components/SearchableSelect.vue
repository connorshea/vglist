<template>
  <div class="searchable-select" :class="{ 'is-open': open }">
    <label v-if="label" class="label" :for="inputId">{{ label }}</label>

    <div class="ss-control" :class="{ focused: open }" @click="focusInput">
      <span v-if="modelValue && !open" class="ss-selected-text" aria-hidden="true">{{ modelValue.name }}</span>
      <input
        :id="inputId"
        ref="inputRef"
        v-model="query"
        class="ss-input"
        :class="{ hidden: !!modelValue && !open }"
        type="text"
        role="combobox"
        aria-autocomplete="list"
        :aria-expanded="open"
        :aria-controls="listboxId"
        :aria-activedescendant="open && results[highlightIndex] ? optionId(highlightIndex) : undefined"
        :aria-description="modelValue ? `Selected: ${modelValue.name}` : undefined"
        :placeholder="modelValue ? modelValue.name : placeholder"
        autocomplete="off"
        @focus="onFocus"
        @blur="onBlur"
        @keydown="onKeydown"
      />
      <button
        v-if="modelValue"
        type="button"
        class="ss-clear"
        :aria-label="`Clear ${modelValue.name}`"
        @click.stop="clearSelection"
      >
        <X :size="14" aria-hidden="true" />
      </button>
    </div>

    <!-- Dropdown -->
    <div
      v-show="open"
      :id="listboxId"
      ref="dropdownRef"
      class="ss-dropdown"
      role="listbox"
      :aria-label="label"
      @mousedown.prevent
    >
      <div v-if="!query.trim()" class="ss-no-results">Type to search</div>
      <div v-else-if="searching && results.length === 0" class="ss-no-results">Searching…</div>
      <div v-else-if="results.length === 0" class="ss-no-results">No results</div>
      <div
        v-for="(option, i) in results"
        :id="optionId(i)"
        :key="option.id"
        role="option"
        class="ss-option"
        :class="{ highlighted: i === highlightIndex, selected: modelValue?.id === option.id }"
        :aria-selected="modelValue?.id === option.id"
        @mousedown.prevent="selectOption(option)"
        @mouseenter="highlightIndex = i"
      >
        {{ option.name }}
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, nextTick, useId } from "vue";
import { X } from "@lucide/vue";
import { useDebouncedSearch } from "@/composables/useDebouncedSearch";

interface Option {
  id: string;
  name: string;
}

const props = withDefaults(
  defineProps<{
    /** The selected record, or null for none. */
    modelValue: Option | null;
    /** Finds records whose name matches the query. Called after typing pauses. */
    search: (query: string) => Promise<Option[]>;
    label?: string;
    placeholder?: string;
  }>(),
  {
    label: undefined,
    placeholder: "Search..."
  }
);

const emit = defineEmits<{
  "update:modelValue": [value: Option | null];
}>();

const uid = useId();
const inputId = `${uid}-input`;
const listboxId = `${uid}-listbox`;
const optionId = (i: number) => `${uid}-option-${i}`;

const { query, results, searching } = useDebouncedSearch((q) => props.search(q));
const open = ref(false);
const highlightIndex = ref(0);
const inputRef = ref<HTMLInputElement | null>(null);
const dropdownRef = ref<HTMLElement | null>(null);

watch([query, results], () => {
  highlightIndex.value = 0;
});

function selectOption(option: Option) {
  emit("update:modelValue", { id: option.id, name: option.name });
  query.value = "";
  open.value = false;
}

function clearSelection() {
  emit("update:modelValue", null);
  query.value = "";
  nextTick(() => inputRef.value?.focus());
}

function focusInput() {
  inputRef.value?.focus();
}

function onFocus() {
  open.value = true;
  query.value = "";
}

function onKeydown(e: KeyboardEvent) {
  if (e.key === "ArrowDown") {
    e.preventDefault();
    if (!open.value) {
      open.value = true;
    } else if (highlightIndex.value < results.value.length - 1) {
      highlightIndex.value++;
      scrollHighlightedIntoView();
    }
  } else if (e.key === "ArrowUp") {
    e.preventDefault();
    if (highlightIndex.value > 0) {
      highlightIndex.value--;
      scrollHighlightedIntoView();
    }
  } else if (e.key === "Enter") {
    // Don't submit the form while picking from the list.
    e.preventDefault();
    const option = results.value[highlightIndex.value];
    if (open.value && option) {
      selectOption(option);
    }
  } else if (e.key === "Escape") {
    open.value = false;
    query.value = "";
    inputRef.value?.blur();
  }
}

// Close when focus leaves, e.g. on Tab. The list uses `mousedown.prevent`, so
// clicking in it doesn't blur the input first.
function onBlur() {
  open.value = false;
  query.value = "";
}

function scrollHighlightedIntoView() {
  nextTick(() => {
    const el = dropdownRef.value?.querySelector(".highlighted");
    el?.scrollIntoView({ block: "nearest" });
  });
}
</script>

<style scoped>
.searchable-select {
  position: relative;
  margin-bottom: 0.75rem;
}

.ss-control {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 6px 8px;
  border: 1px solid var(--color-border, #dbdbdb);
  border-radius: 4px;
  background: var(--color-surface, #fff);
  cursor: text;
  min-height: 40px;
  transition: border-color 0.15s;
}

.ss-control.focused {
  border-color: var(--color-accent, #485fc7);
  box-shadow: 0 0 0 2px rgba(72, 95, 199, 0.15);
}

.ss-selected-text {
  font-size: 14px;
  flex: 1;
  padding: 2px 4px;
}

.ss-input {
  border: none;
  outline: none;
  background: transparent;
  font-size: 14px;
  flex: 1;
  min-width: 80px;
  padding: 2px 4px;
  font-family: inherit;
}

.ss-input.hidden {
  position: absolute;
  width: 0;
  height: 0;
  opacity: 0;
  overflow: hidden;
}

.ss-clear {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: none;
  cursor: pointer;
  color: var(--color-text-tertiary);
  padding: 2px;
  border-radius: 2px;
  transition:
    color 0.1s,
    background 0.1s;
}

.ss-clear:hover {
  color: var(--color-text-primary);
  background: var(--color-bg-subtle, #f5f5f5);
}

/* Extend the hit area past the 18px button for touch screens. */
.ss-clear {
  position: relative;
}

.ss-clear::after {
  content: "";
  position: absolute;
  inset: -8px;
}

/* Dropdown */
.ss-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  z-index: 50;
  margin-top: 4px;
  max-height: 220px;
  overflow-y: auto;
  background: var(--color-surface, #fff);
  border: 1px solid var(--color-border, #dbdbdb);
  border-radius: 6px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
}

.ss-option {
  display: flex;
  align-items: center;
  width: 100%;
  padding: 7px 10px;
  font-size: 14px;
  border: none;
  background: none;
  cursor: pointer;
  text-align: left;
  font-family: inherit;
  color: var(--color-text-primary);
  transition: background 0.1s;
}

.ss-option.highlighted {
  background: var(--color-bg-subtle, #f5f5f5);
}

.ss-option.selected {
  font-weight: 500;
  color: var(--color-accent, #485fc7);
}

.ss-no-results {
  padding: 10px 12px;
  font-size: 13px;
  color: var(--color-text-tertiary);
}
</style>
