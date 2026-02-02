<template>
  <div :class="grandparentClass">
    <label v-if="label" :for="inputId" class="label">{{ label }}</label>
    <div :class="parentClass">
      <vue-select
        :options="(options as any)"
        :isDisabled="disabled"
        @search="onSearch"
        :inputId="inputId"
        :placeholder="placeholder"
        :isClearable="true"
        :isLoading="isLoading"
        :modelValue="(modelValue as any)"
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
const options = ref<Option<number>[]>([]);
const searchPath = computed(() => `${window.location.origin}/${props.searchPathIdentifier}/search.json`);
const isLoading = ref(false);

const defaultOptionFunc = (item: { id: number; name: string }): Option<number> => ({
  label: item.name,
  value: item.id
});

/*
 * @param {search} String Current search text
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
  const optionFunc = props.customOptionFunc ?? defaultOptionFunc;
  options.value = data.map(optionFunc);
  isLoading.value = false;
}, 250);

// Computed properties
const inputId = computed(() => {
  return snakeCase(props.label);
});
</script>
