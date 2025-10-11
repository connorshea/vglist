<template>
  <div class="field" :class="fieldClass">
    <label v-if="label" class="label" v-bind:for="numberFieldId">{{ label }}</label>
    <div class="control">
      <input
        autocomplete="off"
        class="input"
        type="number"
        :placeholder="placeholder"
        :min="min"
        :max="max"
        :required="required"
        v-bind:name="numberFieldName"
        v-bind:id="numberFieldId"
        v-bind:value="dataValue"
        v-on:input="$emit('input', $event.target?.value)"
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
  value?: number | string;
  required?: boolean;
  min?: number;
  max?: number;
}

// TODO: replace withDefaults after Vue 3.5 upgrade.
// https://vuejs.org/guide/components/props.html#reactive-props-destructure
const props = withDefaults(defineProps<Props>(), {
  fieldClass: '',
  placeholder: '',
  value: '',
  required: false,
  min: 0
});

const emit = defineEmits(['input']);

const dataValue = ref(props.value);

watch(() => props.value, (newVal) => {
  dataValue.value = newVal;
});

const numberFieldName = computed(() => `${props.formClass}[${props.attribute}]`);
const numberFieldId = computed(() => `${props.formClass}_${props.attribute}`);
</script>
