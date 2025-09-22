<template>
  <div class="field">
    <label class="label" :for="inputId">{{ label }}</label>
    <div class="control">
      <v-select
        multiple
        :taggable="true"
        :inputId="inputId"
        :label="vSelectLabel"
        @change="onChange"
        v-bind:value="value"
        v-on:input="$emit('input', $event)"
      ></v-select>
    </div>
  </div>
</template>

<script lang="ts">
import vSelect from 'vue-select';
import 'vue-select/dist/vue-select.css';
import { snakeCase } from 'lodash-es';
import { defineComponent } from 'vue';

export default defineComponent({
  name: 'multi-select-generic',
  components: {
    vSelect
  },
  props: {
    label: {
      type: String,
      required: true
    },
    value: {
      type: Array,
      required: true
    },
    vSelectLabel: {
      type: String,
      required: false,
      default: "name"
    }
  },
  emit: ['input'],
  data: function() {
    return {
      options: []
    };
  },
  methods: {
    onChange(selectedItems) {
      this.$emit('input', selectedItems);
    }
  },
  computed: {
    inputId() {
      return snakeCase(this.label);
    }
  }
});
</script>
