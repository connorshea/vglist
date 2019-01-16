<template>
  <input
    autocomplete="off"
    class="input"
    type="text"
    v-bind:name="textFieldName"
    v-bind:id="textFieldId"
  >
</template>

<script>
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
    }
  },
  computed: {
    textFieldName: function() {
      return `${this.formClass}[${this.attribute}]`;
    },
    textFieldId: function() {
      return `${this.formClass}_${this.attribute}`;
    }
  }
}
</script>

