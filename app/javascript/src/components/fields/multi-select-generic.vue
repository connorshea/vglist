<template>
  <div class="field">
    <label class="label" :for="inputId">{{ label }}</label>
    <div class="control">
      <vue-select
        :isMulti="true"
        :isTaggable="true"
        :inputId="inputId"
        :options="[]"
        :modelValue="modelValue"
        @update:modelValue="(val: any) => handleChange(val)"
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

// Methods
function handleChange(selectedItems: Option<string>[]) {
  emit('update:modelValue', selectedItems);
}

// Computed properties
const inputId = computed(() => {
  return snakeCase(props.label);
});
</script>
