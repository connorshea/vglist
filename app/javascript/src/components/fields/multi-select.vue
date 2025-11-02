<template>
  <div class="field">
    <label v-if="label" class="label" :for="inputId">{{ label }}</label>
    <div class="control">
      <!-- TODO: Make this work by adding events for state changes -->
      <vue-select
        :is-multi="true"
        :options="options"
        @search="onSearch"
        :isLoading="isLoading"
        :inputId="inputId"
        :placeholder="placeholder"
        @optionSelected="optionSelected"
        @optionDeselected="optionDeselected"
        :isClearable="true"
        v-model="modelValue"
        @update:modelValue="$emit('update:modelValue', $event)"
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
  modelValue: any[];
  searchPathIdentifier: 'genres' | 'platforms' | 'engines' | 'series' | 'companies' | 'stores';
  placeholder?: string;
}

const props = defineProps<Props>();

const emit = defineEmits(['update:modelValue']);

// Reactive data
const options = ref<Option<string>[]>([]);
const searchPath = computed(() => {
  return `${window.location.origin}/${props.searchPathIdentifier}/search.json`;
});

// Methods
function handleChange(selectedItems: any[]) {
  emit('update:modelValue', selectedItems);
}

const isLoading = ref(false);

/*
 * @param search Current search text
 */
const onSearch = debounce(async (search: string) => {
  isLoading.value = true;
  const searchUrl = new URL(searchPath.value);
  searchUrl.searchParams.append('query', search);
  const response = await fetch(searchUrl.toString(), {
    headers: {
      'Content-Type': 'application/json'
    }
  });
  
  // TODO: Add error handling.
  const data = await response.json();

  // Map the returned objects to the format vue-select likes (objects with label and value keys).
  options.value = data.map((item: { id: number; name: string }) => ({ label: item.name, value: item.id })) ?? [];
  isLoading.value = false;
}, 250);

const optionDeselected = (option: Option<string>) => {
  const newValue = props.modelValue.filter((item: any) => item.id !== option.value);
  handleChange(newValue);
};

const optionSelected = (option: Option<string>) => {
  const newValue = [...props.modelValue, { id: option.value, name: option.label }];
  handleChange(newValue);
};

// Computed properties
const inputId = computed(() => {
  return snakeCase(props.label);
});
</script>
