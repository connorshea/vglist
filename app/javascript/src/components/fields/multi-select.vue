<template>
  <div class="field">
    <label v-if="label" class="label" :for="inputId">{{ label }}</label>
    <div class="control">
      <vue-select
        :isMulti="true"
        :options="(options as any)"
        @search="onSearch"
        :inputId="inputId"
        :placeholder="placeholder"
        :isLoading="isLoading"
        :modelValue="(modelValue as any)"
        @update:modelValue="(val: any) => handleChange(val)"
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
const options = ref<Option<number>[]>([]);
const searchPath = computed(() => `${window.location.origin}/${props.searchPathIdentifier}/search.json`);
const isLoading = ref(false);

const defaultOptionFunc = (item: { id: number; name: string }): Option<number> => ({
  label: item.name,
  value: item.id
});

// Methods
function handleChange(selectedItems: Option<number>[]) {
  emit('update:modelValue', selectedItems);
}

/*
 * @param {search}  String   Current search text
 */
const onSearch = debounce(async (search: string) => {
  isLoading.value = true;
  const searchUrl = new URL(searchPath.value);
  searchUrl.searchParams.append('query', search);
  // TODO: Add error handling.
  const response = await fetch(searchUrl.toString(), {
    headers: {
      'Content-Type': 'application/json'
    }
  });

  const data: { id: number; name: string }[] = await response.json();
  options.value = data.map(defaultOptionFunc);
  isLoading.value = false;
}, 250);

// Computed properties
const inputId = computed(() => {
  return snakeCase(props.label);
});
</script>
