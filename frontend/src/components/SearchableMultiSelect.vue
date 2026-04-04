<template>
  <div class="searchable-select" :class="{ 'is-open': open }">
    <label v-if="label" class="label">{{ label }}</label>

    <!-- Selected tags + input -->
    <div
      ref="controlRef"
      class="ss-control"
      :class="{ focused: open }"
      role="combobox"
      :aria-expanded="open"
      aria-haspopup="listbox"
      @click="focusInput"
    >
      <span v-for="item in selectedItems" :key="item.id" class="ss-tag">
        {{ item.name }}
        <button type="button" class="ss-tag-remove" :aria-label="`Remove ${item.name}`" @click.stop="removeItem(item)">
          <X :size="12" />
        </button>
      </span>
      <input
        ref="inputRef"
        v-model="search"
        class="ss-input"
        type="text"
        :placeholder="selectedItems.length === 0 ? placeholder : ''"
        autocomplete="off"
        @focus="open = true"
        @keydown="onKeydown"
      />
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
        :class="{ highlighted: i === highlightIndex, selected: isSelected(option) }"
        :aria-selected="isSelected(option)"
        @mousedown.prevent="toggleOption(option)"
        @mouseenter="highlightIndex = i"
      >
        <Check v-if="isSelected(option)" :size="14" class="ss-check" />
        <span v-else class="ss-check-spacer" />
        {{ option.name }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onBeforeUnmount, nextTick } from "vue";
import { X, Check } from "lucide-vue-next";

interface Option {
  id: string;
  name: string;
}

const props = withDefaults(
  defineProps<{
    options: Option[];
    modelValue: string[];
    label?: string;
    placeholder?: string;
  }>(),
  {
    label: undefined,
    placeholder: "Search..."
  }
);

const emit = defineEmits<{
  "update:modelValue": [value: string[]];
}>();

const search = ref("");
const open = ref(false);
const highlightIndex = ref(0);
const inputRef = ref<HTMLInputElement | null>(null);
const controlRef = ref<HTMLElement | null>(null);
const dropdownRef = ref<HTMLElement | null>(null);

const selectedItems = computed(() => {
  const idSet = new Set(props.modelValue);
  return props.options.filter((o) => idSet.has(o.id));
});

const filteredOptions = computed(() => {
  const q = search.value.toLowerCase().trim();
  if (!q) return props.options;
  return props.options.filter((o) => o.name.toLowerCase().includes(q));
});

watch(search, () => {
  highlightIndex.value = 0;
});

function isSelected(option: Option): boolean {
  return props.modelValue.includes(option.id);
}

function toggleOption(option: Option) {
  if (isSelected(option)) {
    emit(
      "update:modelValue",
      props.modelValue.filter((id) => id !== option.id)
    );
  } else {
    emit("update:modelValue", [...props.modelValue, option.id]);
  }
  search.value = "";
  nextTick(() => inputRef.value?.focus());
}

function removeItem(item: Option) {
  emit(
    "update:modelValue",
    props.modelValue.filter((id) => id !== item.id)
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
    if (option) toggleOption(option);
  } else if (e.key === "Escape") {
    open.value = false;
    inputRef.value?.blur();
  } else if (e.key === "Backspace" && !search.value && selectedItems.value.length > 0) {
    removeItem(selectedItems.value[selectedItems.value.length - 1]);
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
