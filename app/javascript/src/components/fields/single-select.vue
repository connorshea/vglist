<template>
  <div :class="grandparentClass">
    <label v-if="label" :for="inputId" class="label">{{ label }}</label>
    <div :class="parentClass">
      <vue-select
        :options="(allOptions as any)"
        :isDisabled="disabled"
        @search="onSearch"
        :inputId="label ? inputId : undefined"
        :placeholder="placeholder"
        :isClearable="true"
        :isLoading="isLoading"
        :modelValue="selectedValue"
        @update:modelValue="handleValueChange"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import VueSelect, { type Option } from 'vue3-select-component';
import { debounce, snakeCase } from 'lodash-es';

interface Props {
  label?: string;
  modelValue?: Option<number> | null;
  disabled?: boolean;
  searchPathIdentifier: 'games' | 'series' | 'platforms' | 'genres' | 'engines' | 'companies' | 'stores';
  grandparentClass?: string;
  parentClass?: string;
  placeholder?: string;
  customOptionFunc?: (item: { id: number; name: string }) => Option<number>;
}

const props = withDefaults(defineProps<Props>(), {
  disabled: false,
  grandparentClass: 'field',
  parentClass: 'control'
});

const emit = defineEmits(['update:modelValue']);

// Reactive data
// Store search results separately from pre-selected value
const searchOptions = ref<Option<number>[]>([]);
const searchPath = computed(() => `${window.location.origin}/${props.searchPathIdentifier}/search.json`);
const isLoading = ref(false);

// Combine pre-selected value with search results for the options list
// This ensures the selected value can always be looked up by the component
const allOptions = computed(() => {
  const selected = props.modelValue;
  const searched = searchOptions.value;
  if (!selected) return searched;
  // Include selected option if not already in search results
  if (searched.some(opt => opt.value === selected.value)) {
    return searched;
  }
  return [selected, ...searched];
});

// Extract just the value for modelValue (vue3-select-component expects value, not Option)
const selectedValue = computed(() => props.modelValue?.value ?? null);

const defaultOptionFunc = (item: { id: number; name: string }): Option<number> => ({
  label: item.name,
  value: item.id
});

// When value changes, look up full Option object and emit
function handleValueChange(value: number | (number | null)[] | null) {
  // vue3-select-component can emit array for some edge cases, handle both
  const singleValue = Array.isArray(value) ? value[0] ?? null : value;
  if (singleValue === null) {
    emit('update:modelValue', null);
    return;
  }
  const selectedOption = allOptions.value.find(opt => opt.value === singleValue);
  emit('update:modelValue', selectedOption ?? null);
}

/*
 * @param {search} String Current search text
 */
const onSearch = debounce(async (search: string) => {
  isLoading.value = true;
  const searchUrl = new URL(searchPath.value);
  searchUrl.searchParams.append('query', search);
  try {
    const response = await fetch(searchUrl.toString(), {
      headers: {
        'Content-Type': 'application/json'
      }
    });

    const data: { id: number; name: string }[] = await response.json();
    const optionFunc = props.customOptionFunc ?? defaultOptionFunc;
    searchOptions.value = data.map(optionFunc);
  } catch (e) {
    console.error(`Error searching ${props.searchPathIdentifier}:`, e);
  } finally {
    isLoading.value = false;
  }
}, 250);

// Computed properties
const inputId = computed(() => {
  return snakeCase(props.label);
});
</script>
