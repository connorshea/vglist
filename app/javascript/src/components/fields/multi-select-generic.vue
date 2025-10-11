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
        :modelValue="modelValue"
        @update:modelValue="$emit('update:modelValue', $event)"
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
  modelValue: any[];
  vSelectLabel?: string;
}

const props = withDefaults(defineProps<Props>(), {
  vSelectLabel: "name"
});

const emit = defineEmits(['update:modelValue']);

// Reactive data
const options = ref<any[]>([]);

// Methods
function handleChange(selectedItems: any[]) {
  emit('update:modelValue', selectedItems);
}

// Computed properties
const inputId = computed(() => {
  return snakeCase(props.label);
});
</script>
