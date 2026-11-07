<template>
  <div class="library-empty" role="status">
    <template v-if="error">
      <p class="library-empty-title">Couldn't load this library</p>
      <p>{{ error.message }}</p>
    </template>
    <template v-else-if="libraryEmpty">
      <p class="library-empty-title">No games in this library yet</p>
    </template>
    <template v-else>
      <p class="library-empty-title">No games match these filters</p>
      <p>Try a different status, or remove a filter.</p>
    </template>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  error: Error | null;
  // Whether the whole library is empty, rather than just the filtered view.
  libraryEmpty: boolean;
}>();
</script>

<style scoped>
.library-empty {
  padding: 48px 16px;
  color: var(--color-text-secondary);
  font-size: 0.875rem;
  text-align: center;
}

.library-empty-title {
  margin-bottom: 4px;
  color: var(--color-text-primary);
  font-size: 1rem;
  font-weight: 600;
}
</style>
