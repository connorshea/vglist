<template>
  <div class="field">
    <label class="label" v-bind:for="textAreaId">{{ label }}</label>
    <div class="control">
      <textarea
        class="textarea"
        v-bind:name="textAreaName"
        v-bind:id="textAreaId"
        v-model="dataValue"
        @input="handleInput"
        :required="required"
      ></textarea>
    </div>
  </div>
</template>


<script setup lang="ts">
import { computed, ref, watch } from 'vue';

interface Props {
  formClass: string;
  attribute: string;
  label: string;
  modelValue: string;
  required?: boolean;
}

const props = defineProps<Props>();
const emit = defineEmits(['update:modelValue']);

const dataValue = ref(props.modelValue);

// Handle input events with proper typing
function handleInput(event: InputEvent) {
  emit('update:modelValue', (event.target as HTMLTextAreaElement).value);
}

watch(() => props.modelValue, (newVal) => {
  dataValue.value = newVal;
});

const textAreaName = computed(() => `${props.formClass}[${props.attribute}]`);
const textAreaId = computed(() => `${props.formClass}_${props.attribute}`);
</script>
