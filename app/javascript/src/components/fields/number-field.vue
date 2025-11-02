<template>
  <div class="field" :class="fieldClass">
    <label v-if="label" class="label" :for="numberFieldId">{{ label }}</label>
    <div class="control">
      <input
        autocomplete="off"
        class="input"
        type="number"
        :placeholder="placeholder"
        :min="min"
        :max="max"
        :required="required"
        :name="numberFieldName"
        :id="numberFieldId"
        :value="dataValue"
        @input="handleInput"
        :style="{ width: width ?? '100%' }"
      />
    </div>
  </div>
</template>


<script setup lang="ts">
import { computed, ref, watch } from 'vue';

interface Props {
  formClass: string;
  fieldClass?: string;
  attribute: string;
  label?: string;
  placeholder?: string;
  modelValue?: number | string;
  required?: boolean;
  min?: number;
  max?: number;
  width?: string;
}

const props = withDefaults(defineProps<Props>(), {
  fieldClass: '',
  placeholder: '',
  modelValue: '',
  required: false,
  min: 0
});

const emit = defineEmits(['update:modelValue']);

const dataValue = ref(props.modelValue);

// Handle input events with proper typing
function handleInput(event: InputEvent) {
  emit('update:modelValue', (event.target as HTMLInputElement).value);
}

watch(() => props.modelValue, (newVal) => {
  dataValue.value = newVal;
});

const numberFieldName = computed(() => `${props.formClass}[${props.attribute}]`);
const numberFieldId = computed(() => `${props.formClass}_${props.attribute}`);
</script>
