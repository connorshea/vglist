<template>
  <div class="field">
    <label class="label" v-bind:for="numberFieldId">{{ label }}</label>
    <div class="control">
      <input
        autocomplete="off"
        class="input"
        type="number"
        :min="min"
        :max="max"
        :required="required"
        v-bind:name="numberFieldName"
        v-bind:id="numberFieldId"
        v-bind:value="dataValue"
        v-on:input="$emit('input', $event.target.value)"
      />
    </div>
  </div>
</template>

<script>
export default {
  name: 'number-field',
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
      type: [Number, String],
      required: false,
      default: ''
    },
    required: {
      type: Boolean,
      required: false,
      default: false
    },
    min: {
      type: Number,
      required: false,
      default: 0
    },
    max: {
      type: Number,
      required: false,
      default: 100
    }
  },
  data() {
    return {
      dataValue: this.value
    };
  },
  computed: {
    numberFieldName: function() {
      return `${this.formClass}[${this.attribute}]`;
    },
    numberFieldId: function() {
      return `${this.formClass}_${this.attribute}`;
    }
  }
};
</script>
