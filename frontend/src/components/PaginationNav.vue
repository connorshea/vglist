<template>
  <nav class="pagination is-centered mt-5" role="navigation" aria-label="pagination">
    <button
      class="pagination-previous"
      :disabled="currentPage <= 1 || loading"
      @click="$emit('prev')"
    >
      Previous
    </button>
    <button class="pagination-next" :disabled="!hasNextPage || loading" @click="$emit('next')">
      Next page
    </button>
    <ul class="pagination-list">
      <li>
        <span class="pagination-link is-current" aria-current="page">{{ currentPage }}</span>
      </li>
    </ul>
  </nav>
</template>

<script setup lang="ts">
defineProps<{
  currentPage: number;
  hasNextPage: boolean;
  loading: boolean;
}>();

defineEmits<{
  prev: [];
  next: [];
}>();
</script>
