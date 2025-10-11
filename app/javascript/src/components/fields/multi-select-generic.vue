<template>
  <div class="field">
    <label class="label" :for="inputId">{{ label }}</label>
    <div class="control">
      <v-select
        multiple
        :taggable="true"
        :inputId="inputId"
        :label="vSelectLabel"
        @change="handleChange"
        v-bind:value="value"
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
import { snakeCase } from 'lodash-es';

interface Props {
  label: string;
  value: any[];
  vSelectLabel?: string;
}

const props = withDefaults(defineProps<Props>(), {
  vSelectLabel: "name"
});

const emit = defineEmits(['input']);

// Reactive data
const options = ref<any[]>([]);

// Methods
function handleChange(selectedItems: any[]) {
  emit('input', selectedItems);
}

// Computed properties
const inputId = computed(() => {
  return snakeCase(props.label);
});
</script>
