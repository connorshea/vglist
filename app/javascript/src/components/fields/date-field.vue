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
        v-on:input="$emit('input', $event.target.value)"
      >
    </div>
  </div>
</template>

<script lang="ts">
export default {
  name: 'date-field',
  props: {
    formClass: {
      type: String,
      required: true
    },
    attribute: {
      type: String,
      required: true
    },
    label: {
      type: String,
      required: true
    },
    value: {
      type: String,
      required: false
    },
    required: {
      type: Boolean,
      required: false,
      default: false
    }
  },
  data() {
    return {
      dataValue: this.value
    };
  },
  computed: {
    dateFieldName: function() {
      return `${this.formClass}[${this.attribute}]`;
    },
    dateFieldId: function() {
      return `${this.formClass}_${this.attribute}`;
    }
  }
};
</script>
