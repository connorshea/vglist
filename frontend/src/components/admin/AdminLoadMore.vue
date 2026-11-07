<template>
  <div class="admin-load-more">
    <p v-if="error" class="has-text-danger mb-3" role="alert">Failed to load more {{ noun }}: {{ error }}</p>
    <button
      v-if="hasNextPage"
      type="button"
      class="button"
      :class="{ 'is-loading': loading }"
      :disabled="loading"
      @click="emit('loadMore')"
    >
      Load more {{ noun }}
    </button>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  hasNextPage: boolean;
  loading: boolean;
  error: string | null;
  // What the rows are, e.g. "entries".
  noun: string;
}>();

const emit = defineEmits<{
  loadMore: [];
}>();
</script>

<style scoped>
.admin-load-more {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-top: 1rem;
}

.admin-load-more:empty {
  display: none;
}
</style>
