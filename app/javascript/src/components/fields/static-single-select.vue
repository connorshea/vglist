<template>
  <div class="field">
    <label v-if="label" class="label">{{ label }}</label>
    <div class="control">
      <v-select
        :options="options"
        :maxHeight="maxHeight"
        :disabled="disabled"
        label="label"
        v-bind:value="value"
        v-on:input="$emit('input', $event)"
      ></v-select>
    </div>
  </div>
</template>

<script>
import vSelect from 'vue-select';

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
    value: {
      type: Object,
      required: false
    },
    options: {
      type: Array,
      required: true
    },
    // Replace this with a CSS change when vue-select 3.0.0 comes out.
    // https://github.com/sagalbot/vue-select/pull/759
    maxHeight: {
      type: String,
      required: false,
      default: '400px'
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false
    }
  }
}
</script>
