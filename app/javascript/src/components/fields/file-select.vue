<template>
  <div class="field">
    <label v-if="label" class="label">{{ label }}</label>
    <label class="file-select">
      <!-- We can't use a normal button element here, as it would become the target of the label. -->
      <div class="button">
        <!-- Display the filename if a file has been selected. -->
        <span v-if="modelValue">Selected File: {{ modelValue.name }}</span>
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

<script setup lang="ts">
import { ref } from 'vue';

interface Props {
  modelValue?: File;
  label?: string;
  fileClass?: string;
}

const props = withDefaults(defineProps<Props>(), {
  fileClass: 'game-cover'
});

const emit = defineEmits(['input']);

const image = ref<string | null>(null);

const handleFileChange = (e: Event) => {
  const target = e.target as HTMLInputElement;
  const file = target.files?.[0];

  if (file) {
    const reader = new FileReader();
    reader.onloadend = () => {
      image.value = reader.result as string;
    };
    reader.readAsDataURL(file);

    // Whenever the file changes, emit the 'input' event with the file data.
    emit('input', file);
  }
};
</script>
