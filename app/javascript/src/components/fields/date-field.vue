<template>
  <div class="field">
    <label class="label" v-bind:for="dateFieldId">{{ label }}</label>
    <div class="control">
      <input
        autocomplete="off"
        class="input"
        type="date"
        :required="required"
        v-bind:name="dateFieldName"
        v-bind:id="dateFieldId"
        v-bind:value="dataValue"
        v-on:input="handleInput"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";

interface Props {
  formClass: string;
  attribute: string;
  label: string;
  modelValue?: string;
  required?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  required: false,
});

const emit = defineEmits(["update:modelValue"]);

const dataValue = ref(props.modelValue);

// Handle input events with proper typing
function handleInput(event: Event) {
  const target = event.target as HTMLInputElement;
  emit("update:modelValue", target.value);
}

watch(
  () => props.modelValue,
  (newVal) => {
    dataValue.value = newVal;
  },
);

const dateFieldName = computed(() => `${props.formClass}[${props.attribute}]`);
const dateFieldId = computed(() => `${props.formClass}_${props.attribute}`);
</script>
