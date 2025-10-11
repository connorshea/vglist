<template>
  <div :class="grandparentClass">
    <label v-if="label" :for="inputId" class="label">{{ label }}</label>
    <div class="control">
      <v-select
        :options="options"
        :disabled="disabled"
        label="label"
        :placeholder="placeholder"
        :inputId="inputId"
        v-bind:value="value"
        v-on:input="$emit('input', $event)"
      ></v-select>
    </div>
  </div>
</template>


<script setup lang="ts">
import vSelect from 'vue-select';
import 'vue-select/dist/vue-select.css';
import { snakeCase } from 'lodash-es';
import { computed } from 'vue';

const props = defineProps({
  label: {
    type: String,
    required: false
  },
  placeholder: {
    type: String,
    required: false,
    default: ''
  },
  value: {
    type: [Object, String],
    required: false
  },
  options: {
    type: Array,
    required: true
  },
  grandparentClass: {
    type: String,
    required: false,
    default: 'field'
  },
  disabled: {
    type: Boolean,
    required: false,
    default: false
  }
});

const emit = defineEmits(['input']);

const inputId = computed(() => snakeCase(props.label));
</script>
