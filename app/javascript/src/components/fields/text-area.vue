<template>
  <div class="field">
    <label class="label" v-bind:for="textAreaId">{{ label }}</label>
    <div class="control">
      <textarea
        class="textarea"
        v-bind:name="textAreaName"
        v-bind:id="textAreaId"
        v-bind:value="dataValue"
        v-on:input="$emit('input', $event.target?.value)"
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
  value: string;
  required?: boolean;
}

const props = defineProps<Props>();
const emit = defineEmits(['input']);

const dataValue = ref(props.value);

watch(() => props.value, (newVal) => {
  dataValue.value = newVal;
});

const textAreaName = computed(() => `${props.formClass}[${props.attribute}]`);
const textAreaId = computed(() => `${props.formClass}_${props.attribute}`);
</script>
