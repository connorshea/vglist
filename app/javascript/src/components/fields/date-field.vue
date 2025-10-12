<template>
  <div class="field">
    <label class="label" :for="dateFieldId">{{ label }}</label>
    <div class="control">
      <input
        autocomplete="off"
        class="input"
        type="date"
        :required="required"
        :name="dateFieldName"
        :id="dateFieldId"
        :value="dataValue"
        @input="handleInput"
      >
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue';

interface Props {
  formClass: string;
  attribute: string;
  label: string;
  modelValue?: string;
  required?: boolean;
}

// TODO: replace withDefaults after Vue 3.5 upgrade.
// https://vuejs.org/guide/components/props.html#reactive-props-destructure
const props = withDefaults(defineProps<Props>(), {
  required: false
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

const dateFieldName = computed(() => `${props.formClass}[${props.attribute}]`);
const dateFieldId = computed(() => `${props.formClass}_${props.attribute}`);
</script>
