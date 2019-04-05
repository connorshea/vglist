<template>
  <div class="field">
    <label class="label" v-bind:for="textAreaId">{{ label }}</label>
    <div class="control">
      <textarea
        class="textarea"
        v-bind:name="textAreaName"
        v-bind:id="textAreaId"
        v-bind:value="dataValue"
        v-on:input="$emit('input', $event.target.value)"
      ></textarea>
    </div>
  </div>
</template>

<script>
export default {
  name: 'text-area',
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
    }
  },
  data() {
    return {
      dataValue: this.value
    };
  },
  computed: {
    textAreaName: function() {
      return `${this.formClass}[${this.attribute}]`;
    },
    textAreaId: function() {
      return `${this.formClass}_${this.attribute}`;
    }
  }
};
</script>
