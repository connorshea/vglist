<template>
  <div class="field">
    <label class="label">{{ label }}</label>
    <label class="file-select">
      <!-- We can't use a normal button element here, as it would become the target of the label. -->
      <div class="button">
        <!-- Display the filename if a file has been selected. -->
        <span v-if="value">Selected File: {{ value.name }}</span>
        <span v-else>Select File</span>
      </div>
      <!-- We hide this file input. -->
      <input type="file" @change="handleFileChange">
    </label>
    <div :class="['pt-5', fileClass]">
      <img v-if="image" :src="image">
    </div>
  </div>
</template>

<script>
export default {
  props: {
    value: File,
    label: {
      type: String,
      required: true
    },
    fileClass: {
      type: String,
      required: false,
      default: 'game-cover'
    }
  },
  data() {
    return {
      image: null
    };
  },
  methods: {
    handleFileChange(e) {
      let file = e.target.files[0];
      var reader = new FileReader();
      reader.onloadend = () => {
        this.image = reader.result;
      };
      reader.readAsDataURL(file);

      // Whenever the file changes, emit the 'input' event with the file data.
      this.$emit('input', file);
    }
  }
};
</script>
