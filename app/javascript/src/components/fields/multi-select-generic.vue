<template>
  <div class="field">
    <label class="label" :for="inputId">{{ label }}</label>
    <div class="control">
      <vue-select
        :isMulti="true"
        :isTaggable="true"
        :inputId="inputId"
        :options="(modelValue as any)"
        :modelValue="selectedValues"
        @update:modelValue="handleValueChange"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import VueSelect, { type Option } from 'vue3-select-component';
import { snakeCase } from 'lodash-es';

interface Props {
  label: string;
  modelValue: Option<string>[];
}

const props = defineProps<Props>();

const emit = defineEmits(['update:modelValue']);

// Extract just the values for modelValue (vue3-select-component expects values, not Options)
const selectedValues = computed(() => props.modelValue.map(opt => opt.value));

// Methods
// For taggable selects, new values are strings that become both value and label
function handleValueChange(values: string | string[]) {
  // vue3-select-component emits array for isMulti
  const valuesArray = Array.isArray(values) ? values : [values];
  const selectedOptions = valuesArray.map(v => {
    // Try to find existing option, or create new one for tagged values
    const existing = props.modelValue.find(opt => opt.value === v);
    return existing ?? { value: v, label: v };
  });
  emit('update:modelValue', selectedOptions);
}

// Computed properties
const inputId = computed(() => {
  return snakeCase(props.label);
});
</script>
