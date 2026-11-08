<template>
  <div class="searchable-select" :class="{ 'is-open': open }">
    <label v-if="label" class="label" :for="inputId">{{ label }}</label>

    <!-- Selected tags + input -->
    <div class="ss-control" :class="{ focused: open }" @click="focusInput">
      <span v-for="item in modelValue" :key="item.id" class="ss-tag">
        {{ item.name }}
        <button type="button" class="ss-tag-remove" :aria-label="`Remove ${item.name}`" @click.stop="removeItem(item)">
          <X :size="12" aria-hidden="true" />
        </button>
      </span>
      <input
        :id="inputId"
        ref="inputRef"
        v-model="query"
        class="ss-input"
        type="text"
        role="combobox"
        aria-autocomplete="list"
        :aria-expanded="open"
        :aria-controls="listboxId"
        :aria-activedescendant="open && results[highlightIndex] ? optionId(highlightIndex) : undefined"
        :placeholder="modelValue.length === 0 ? placeholder : ''"
        autocomplete="off"
        @focus="open = true"
        @blur="onBlur"
        @keydown="onKeydown"
      />
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
        :class="{ highlighted: i === highlightIndex, selected: isSelected(option) }"
        :aria-selected="isSelected(option)"
        @mousedown.prevent="toggleOption(option)"
        @mouseenter="highlightIndex = i"
      >
        <Check v-if="isSelected(option)" :size="14" class="ss-check" aria-hidden="true" />
        <span v-else class="ss-check-spacer" />
        {{ option.name }}
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, nextTick, useId } from "vue";
import { X, Check } from "@lucide/vue";
import { useDebouncedSearch } from "@/composables/useDebouncedSearch";

interface Option {
  id: string;
  name: string;
}

const props = withDefaults(
  defineProps<{
    /** The selected records, in the order they were picked. */
    modelValue: Option[];
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
  "update:modelValue": [value: Option[]];
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

function isSelected(option: Option): boolean {
  return props.modelValue.some((item) => item.id === option.id);
}

function toggleOption(option: Option) {
  if (isSelected(option)) {
    removeItem(option);
  } else {
    emit("update:modelValue", [...props.modelValue, { id: option.id, name: option.name }]);
  }
  query.value = "";
  nextTick(() => inputRef.value?.focus());
}

function removeItem(item: Option) {
  emit(
    "update:modelValue",
    props.modelValue.filter((selected) => selected.id !== item.id)
  );
}

function focusInput() {
  inputRef.value?.focus();
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
      toggleOption(option);
    }
  } else if (e.key === "Escape") {
    open.value = false;
    query.value = "";
    inputRef.value?.blur();
  } else if (e.key === "Backspace" && !query.value && props.modelValue.length > 0) {
    removeItem(props.modelValue[props.modelValue.length - 1]);
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
  flex-wrap: wrap;
  gap: 4px;
  padding: 6px 8px;
  border: 1px solid var(--color-border, #dbdbdb);
  border-radius: 4px;
  background: var(--color-surface, #fff);
  cursor: text;
  min-height: 40px;
  align-items: center;
  transition: border-color 0.15s;
}

.ss-control.focused {
  border-color: var(--color-accent, #485fc7);
  box-shadow: 0 0 0 2px rgba(72, 95, 199, 0.15);
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

.ss-tag {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px;
  border-radius: 4px;
  background: var(--p-50, #eff0fb);
  color: var(--p-700, #3a3a8a);
  font-size: 13px;
  font-weight: 500;
  white-space: nowrap;
}

.ss-tag-remove {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: none;
  cursor: pointer;
  color: inherit;
  padding: 0;
  opacity: 0.6;
  transition: opacity 0.1s;
}

.ss-tag-remove:hover {
  opacity: 1;
}

/* The icon is 12px; extend the hit area so it's tappable on touch screens
   without changing how the tag looks. */
.ss-tag-remove {
  position: relative;
}

.ss-tag-remove::after {
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
  gap: 6px;
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
}

.ss-check {
  flex-shrink: 0;
  color: var(--color-accent, #485fc7);
}

.ss-check-spacer {
  width: 14px;
  flex-shrink: 0;
}

.ss-no-results {
  padding: 10px 12px;
  font-size: 13px;
  color: var(--color-text-tertiary);
}
</style>
