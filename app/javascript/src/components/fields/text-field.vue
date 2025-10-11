<template>
  <div class="field">
    <label class="label" v-bind:for="textFieldId">{{ label }}</label>
    <div class="control">
      <input
        autocomplete="off"
        class="input"
        type="text"
        :required="required"
        v-bind:name="textFieldName"
        v-bind:id="textFieldId"
        v-bind:value="dataValue"
        v-on:input="$emit('input', ($event.target as HTMLInputElement).value)"
      />
    </div>
  </div>
</template>


<script setup lang="ts">
import { computed, ref, watch } from 'vue';

interface Props {
  formClass: string;
  attribute: string;
  label: string;
  value?: string;
  required?: boolean;
}

// TODO: replace withDefaults after Vue 3.5 upgrade.
// https://vuejs.org/guide/components/props.html#reactive-props-destructure
const props = withDefaults(defineProps<Props>(), {
  required: false
});

const emit = defineEmits(['input']);

const dataValue = ref(props.value);

watch(() => props.value, (newVal) => {
  dataValue.value = newVal;
});

const textFieldName = computed(() => `${props.formClass}[${props.attribute}]`);
const textFieldId = computed(() => `${props.formClass}_${props.attribute}`);
</script>
