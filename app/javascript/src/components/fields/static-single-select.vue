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

<script lang="ts">
import vSelect from 'vue-select';
import 'vue-select/dist/vue-select.css';
import * as _ from 'lodash';

export default {
  name: 'static-single-select',
  components: {
    vSelect
  },
  props: {
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
      type: Object,
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
  },
  computed: {
    inputId() {
      return _.snakeCase(this.label);
    }
  }
};
</script>
