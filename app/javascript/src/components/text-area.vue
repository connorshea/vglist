<template>
  <textarea
    class="textarea"
    v-bind:name="textAreaName"
    v-bind:id="textAreaId"
  ></textarea>
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
    }
  },
  computed: {
    textAreaName: function() {
      return `${this.formClass}[${this.attribute}]`;
    },
    textAreaId: function() {
      return `${this.formClass}_${this.attribute}`;
    }
  }
}
</script>

