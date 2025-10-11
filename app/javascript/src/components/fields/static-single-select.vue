<template>
  <div :class="grandparentClass">
    <label v-if="label" :for="inputId" class="label">{{ label }}</label>
    <div class="control">
      <v-select
        :options="options"
        :disabled="disabled"
        label="label"
        :placeholder="placeholder"
        :inputId="inputId"
        :modelValue="modelValue"
        @update:modelValue="$emit('update:modelValue', $event)"
      ></v-select>
    </div>
  </div>
</template>


<script setup lang="ts">
// @ts-expect-error No types available, replace vue-select with another component soon. vue3-select-component maybe.
import vSelect from 'vue-select';
import 'vue-select/dist/vue-select.css';
import { snakeCase } from 'lodash-es';
import { computed, withDefaults } from 'vue';

interface SelectOption {
  label: string;
  value: unknown;
}

interface Props {
  label?: string;
  placeholder?: string;
  modelValue?: object | string;
  options: number[] | SelectOption[];
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
</script>
