<template>
  <div class="field">
    <label v-if="label" class="label" :for="inputId">{{ label }}</label>
    <div class="control">
      <vue-select
        :isMulti="true"
        :options="(allOptions as any)"
        @search="onSearch"
        :inputId="label ? inputId : undefined"
        :placeholder="placeholder"
        :isLoading="isLoading"
        :modelValue="selectedValues"
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
  modelValue: Option<number>[];
  searchPathIdentifier: 'games' | 'series' | 'platforms' | 'genres' | 'engines' | 'companies' | 'stores';
  placeholder?: string;
}

const props = defineProps<Props>();

const emit = defineEmits(['update:modelValue']);

// Reactive data
// Store search results separately from pre-selected values
const searchOptions = ref<Option<number>[]>([]);
const searchPath = computed(() => `${window.location.origin}/${props.searchPathIdentifier}/search.json`);
const isLoading = ref(false);

// Combine pre-selected values with search results for the options list
// This ensures selected values can always be looked up by the component
const allOptions = computed(() => {
  const selected = props.modelValue;
  const searched = searchOptions.value;
  // Merge, avoiding duplicates by value
  const merged = [...selected];
  for (const opt of searched) {
    if (!merged.some(s => s.value === opt.value)) {
      merged.push(opt);
    }
  }
  return merged;
});

// Extract just the values for modelValue (vue3-select-component expects values, not Options)
const selectedValues = computed(() => props.modelValue.map(opt => opt.value));

const defaultOptionFunc = (item: { id: number; name: string }): Option<number> => ({
  label: item.name,
  value: item.id
});

// Methods
// When values change, look up full Option objects and emit
function handleValueChange(values: number | number[]) {
  // vue3-select-component emits array for isMulti
  const valuesArray = Array.isArray(values) ? values : [values];
  const selectedOptions = valuesArray
    .map(v => allOptions.value.find(opt => opt.value === v))
    .filter((opt): opt is Option<number> => opt !== undefined);
  emit('update:modelValue', selectedOptions);
}

/*
 * @param {search}  String   Current search text
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
    searchOptions.value = data.map(defaultOptionFunc);
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
