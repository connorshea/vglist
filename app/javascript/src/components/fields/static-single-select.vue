<template>
  <div :class="grandparentClass">
    <label v-if="label" :for="inputId" class="label">{{ label }}</label>
    <div class="control">
      <vue-select
        :isDisabled="disabled"
        :placeholder="placeholder"
        :inputId="inputId"
        v-model="selected"
        :options="options"
        @option-selected="(option) => emit('update:modelValue', option.value)"
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
  // This is the type of the options available in the select dropdown.
  options: Option<string>[];
  // This is for the currently selected value
  modelValue: Option<string>;
  grandparentClass?: string;
  disabled?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  placeholder: '',
  grandparentClass: 'field',
  disabled: false
});

// compute the Option<T> that matches the current modelValue so the select receives the expected shape
const selected = computed<Option<string> | null>(() => {
  return props.options.find((o) => o === props.modelValue) ?? null;
});

const emit = defineEmits(['update:modelValue']);

const inputId = computed(() => snakeCase(props.label));
</script>
