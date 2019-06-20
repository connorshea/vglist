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
        v-on:input="$emit('input', $event.target.value)"
      />
    </div>
  </div>
</template>

<script lang="ts">
export default {
  name: 'text-field',
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
      required: true
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
    textFieldName: function() {
      return `${this.formClass}[${this.attribute}]`;
    },
    textFieldId: function() {
      return `${this.formClass}_${this.attribute}`;
    }
  }
};
</script>
