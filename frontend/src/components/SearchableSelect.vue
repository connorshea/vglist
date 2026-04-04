<template>
  <div class="searchable-select" :class="{ 'is-open': open }">
    <label v-if="label" class="label">{{ label }}</label>

    <div
      ref="controlRef"
      class="ss-control"
      :class="{ focused: open }"
      role="combobox"
      :aria-expanded="open"
      aria-haspopup="listbox"
      @click="focusInput"
    >
      <span v-if="selectedItem && !open" class="ss-selected-text">{{ selectedItem.name }}</span>
      <input
        ref="inputRef"
        v-model="search"
        class="ss-input"
        :class="{ hidden: !!selectedItem && !open }"
        type="text"
        :placeholder="selectedItem ? selectedItem.name : placeholder"
        autocomplete="off"
        @focus="onFocus"
        @keydown="onKeydown"
      />
      <button
        v-if="selectedItem"
        type="button"
        class="ss-clear"
        aria-label="Clear selection"
        @click.stop="clearSelection"
      >
        <X :size="14" />
      </button>
    </div>

    <!-- Dropdown -->
    <div v-if="open" ref="dropdownRef" class="ss-dropdown" role="listbox">
      <div v-if="filteredOptions.length === 0" class="ss-no-results">No results</div>
      <button
        v-for="(option, i) in filteredOptions"
        :key="option.id"
        type="button"
        role="option"
        class="ss-option"
        :class="{ highlighted: i === highlightIndex, selected: modelValue === option.id }"
        :aria-selected="modelValue === option.id"
        @mousedown.prevent="selectOption(option)"
        @mouseenter="highlightIndex = i"
      >
        {{ option.name }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onBeforeUnmount, nextTick } from "vue";
import { X } from "lucide-vue-next";

interface Option {
  id: string;
  name: string;
}

const props = withDefaults(
  defineProps<{
    options: Option[];
    modelValue: string;
    label?: string;
    placeholder?: string;
  }>(),
  {
    label: undefined,
    placeholder: "Search..."
  }
);

const emit = defineEmits<{
  "update:modelValue": [value: string];
}>();

const search = ref("");
const open = ref(false);
const highlightIndex = ref(0);
const inputRef = ref<HTMLInputElement | null>(null);
const controlRef = ref<HTMLElement | null>(null);
const dropdownRef = ref<HTMLElement | null>(null);

const selectedItem = computed(() => {
  if (!props.modelValue) return null;
  return props.options.find((o) => o.id === props.modelValue) ?? null;
});

const filteredOptions = computed(() => {
  const q = search.value.toLowerCase().trim();
  if (!q) return props.options;
  return props.options.filter((o) => o.name.toLowerCase().includes(q));
});

watch(search, () => {
  highlightIndex.value = 0;
});

function selectOption(option: Option) {
  emit("update:modelValue", option.id);
  search.value = "";
  open.value = false;
}

function clearSelection() {
  emit("update:modelValue", "");
  search.value = "";
  nextTick(() => inputRef.value?.focus());
}

function focusInput() {
  inputRef.value?.focus();
}

function onFocus() {
  open.value = true;
  search.value = "";
}

function onKeydown(e: KeyboardEvent) {
  if (e.key === "ArrowDown") {
    e.preventDefault();
    if (!open.value) {
      open.value = true;
    } else if (highlightIndex.value < filteredOptions.value.length - 1) {
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
    e.preventDefault();
    const option = filteredOptions.value[highlightIndex.value];
    if (option) selectOption(option);
  } else if (e.key === "Escape") {
    open.value = false;
    search.value = "";
    inputRef.value?.blur();
  }
}

function scrollHighlightedIntoView() {
  nextTick(() => {
    const el = dropdownRef.value?.querySelector(".highlighted");
    el?.scrollIntoView({ block: "nearest" });
  });
}

function onClickOutside(e: MouseEvent) {
  const target = e.target as Node;
  if (!controlRef.value?.contains(target) && !dropdownRef.value?.contains(target)) {
    open.value = false;
    search.value = "";
  }
}

onMounted(() => {
  document.addEventListener("mousedown", onClickOutside);
});

onBeforeUnmount(() => {
  document.removeEventListener("mousedown", onClickOutside);
});
</script>

<style scoped>
.searchable-select {
  position: relative;
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
