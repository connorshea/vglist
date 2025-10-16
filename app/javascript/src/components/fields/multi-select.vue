<template>
  <div class="field">
    <label v-if="label" class="label" :for="inputId">{{ label }}</label>
    <div class="control">
      <v-select
        multiple
        :options="options"
        @search="onSearch"
        :inputId="inputId"
        label="name"
        :placeholder="placeholder"
        @change="handleChange"
        :modelValue="modelValue"
        @update:modelValue="$emit('update:modelValue', $event)"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
// @ts-expect-error No types available, replace vue-select with another component soon. vue3-select-component maybe.
import vSelect from 'vue-select';
import 'vue-select/dist/vue-select.css';
import { debounce, snakeCase } from 'lodash-es';

interface Props {
  label?: string;
  modelValue: any[];
  searchPathIdentifier: string;
  placeholder?: string;
}

const props = defineProps<Props>();

const emit = defineEmits(['update:modelValue']);

// Reactive data
const options = ref<any[]>([]);
const searchPath = `${window.location.origin}/${props.searchPathIdentifier}/search.json`;

// Methods
function handleChange(selectedItems: any[]) {
  emit('update:modelValue', selectedItems);
}

/*
 * @param {search}  String   Current search text
 * @param {loading} Function Toggle loading class
 */
const onSearch = debounce((search: string, loading: (state: boolean) => void) => {
  loading(true);
  let searchUrl = new URL(searchPath);
  searchUrl.searchParams.append('query', search);
  // TODO: Add error handling.
  fetch(searchUrl.toString(), {
    headers: {
      'Content-Type': 'application/json'
    }
  })
    .then(response => {
      return response.json();
    })
    .then(items => {
      options.value = items;
      loading(false);
    });
}, 250);

// Computed properties
const inputId = computed(() => {
  return snakeCase(props.label);
});
</script>
