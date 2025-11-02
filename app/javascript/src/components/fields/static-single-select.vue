<template>
  <div :class="grandparentClass">
    <label v-if="label" :for="inputId" class="label">{{ label }}</label>
    <div class="control">
      <vue-select
        :options="options"
        :isDisabled="disabled"
        :placeholder="placeholder"
        :inputId="inputId"
        v-model="modelValue"
        @update:modelValue="$emit('update:modelValue', $event)"
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
  options: Option<string>[];
  modelValue: string | null;
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
