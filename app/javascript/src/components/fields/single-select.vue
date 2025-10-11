<template>
  <div :class="grandparentClass">
    <label v-if="label" :for="inputId" class="label">{{ label }}</label>
    <div :class="parentClass">
      <v-select
        :options="options"
        :disabled="disabled"
        @search="onSearch"
        label="name"
        :inputId="inputId"
        v-bind:value="value"
        :placeholder="placeholder"
        v-on:input="$emit('input', $event)"
      ></v-select>
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
  value?: any;
  disabled?: boolean;
  searchPathIdentifier: string;
  grandparentClass?: string;
  parentClass?: string;
  placeholder?: string;
  customOptionFunc?: (item: any) => any;
}

const props = withDefaults(defineProps<Props>(), {
  disabled: false,
  grandparentClass: 'field',
  parentClass: 'control'
});

const emit = defineEmits(['input']);

// Reactive data
const options = ref<any[]>([]);
const searchPath = `${window.location.origin}/${props.searchPathIdentifier}/search.json`;

/*
 * @param {search} String Current search text
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
      // Apply the customOptionFunc if it exists.
      if (props.customOptionFunc) {
        items = items.map(props.customOptionFunc);
      }
      options.value = items;
      loading(false);
    });
}, 250);

// Computed properties
const inputId = computed(() => {
  return snakeCase(props.label);
});
</script>
