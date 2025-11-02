<template>
  <div class="field">
    <label class="label" :for="inputId">{{ label }}</label>
    <div class="control">
      <!-- TODO: Handle changes -->
      <vue-select
        :is-multi="true"
        :is-taggable="true"
        :inputId="inputId"
        :label="vSelectLabel"
        :modelValue="modelValue"
        @update:modelValue="$emit('update:modelValue', $event)"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import VueSelect from 'vue3-select-component';
import { snakeCase } from 'lodash-es';

interface Props {
  label: string;
  modelValue: any[];
  // TODO: I think we just need to map the value to this in the option?
  vSelectLabel?: string;
}

const props = withDefaults(defineProps<Props>(), {
  vSelectLabel: "name"
});

const emit = defineEmits(['update:modelValue']);

// Methods
function handleChange(selectedItems: any[]) {
  emit('update:modelValue', selectedItems);
}

// Computed properties
const inputId = computed(() => {
  return snakeCase(props.label);
});
</script>
