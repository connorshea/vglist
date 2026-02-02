<template>
  <div :class="grandparentClass">
    <label v-if="label" :for="inputId" class="label">{{ label }}</label>
    <div class="control">
      <vue-select
        :options="(options as any)"
        :isDisabled="disabled"
        :placeholder="placeholder"
        :inputId="inputId"
        :modelValue="selectedValue"
        @update:modelValue="handleValueChange"
      />
    </div>
  </div>
</template>


<script setup lang="ts">
import VueSelect, { type Option } from 'vue3-select-component';
import { snakeCase } from 'lodash-es';
import { computed } from 'vue';

interface Props {
  label?: string;
  placeholder?: string;
  modelValue?: Option<string | number> | null;
  options: Option<string | number>[];
  grandparentClass?: string;
  disabled?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  placeholder: '',
  grandparentClass: 'field',
  disabled: false
});

const emit = defineEmits(['update:modelValue']);

const inputId = computed(() => snakeCase(props.label));

// Extract just the value for modelValue (vue3-select-component expects value, not Option)
const selectedValue = computed(() => props.modelValue?.value ?? null);

// When value changes, look up full Option object and emit
function handleValueChange(value: string | number | (string | number | null)[] | null) {
  // vue3-select-component can emit array for some edge cases, handle both
  const singleValue = Array.isArray(value) ? value[0] ?? null : value;
  if (singleValue === null) {
    emit('update:modelValue', null);
    return;
  }
  const selectedOption = props.options.find(opt => opt.value === singleValue);
  emit('update:modelValue', selectedOption ?? null);
}
</script>
