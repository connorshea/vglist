<template>
  <label class="file-select">
    <!-- We can't use a normal button element here, as it would become the target of the label. -->
    <div class="select-button">
      <!-- Display the filename if a file has been selected. -->
      <span v-if="value">Selected File: {{value.name}}</span>
      <span v-else>Select File</span>
    </div>
    <!-- We hide this file input. -->
    <input type="file" @change="handleFileChange"/>
  </label>
</template>

<script>
export default {
  props: {
    value: File
  },
  methods: {
    handleFileChange(e) {
      console.log(e);
      console.log(e.target);
      console.log(e.target.files);
      // Whenever the file changes, emit the 'input' event with the file data.
      this.$emit('input', e.target.files[0])
    }
  }
}
</script>
