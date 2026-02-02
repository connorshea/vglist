<template>
  <div :class="grandparentClass">
    <label v-if="label" :for="inputId" class="label">{{ label }}</label>
    <div class="control">
      <vue-select
        :options="(options as any)"
        :isDisabled="disabled"
        :placeholder="placeholder"
        :inputId="inputId"
        :modelValue="(modelValue as any)"
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
</script>
