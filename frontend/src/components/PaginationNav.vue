<template>
  <nav class="pagination-nav" role="navigation" aria-label="pagination">
    <button
      class="page-btn nav"
      :disabled="currentPage <= 1 || loading"
      aria-label="Previous page"
      @click="$emit('prev')"
    >
      <ChevronLeft :size="16" :stroke-width="1.8" />
    </button>
    <span class="page-btn active" aria-current="page">{{ currentPage }}</span>
    <button class="page-btn nav" :disabled="!hasNextPage || loading" aria-label="Next page" @click="$emit('next')">
      <ChevronRight :size="16" :stroke-width="1.8" />
    </button>
  </nav>
</template>

<script setup lang="ts">
import { ChevronLeft, ChevronRight } from "lucide-vue-next";

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

<style scoped>
.pagination-nav {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  margin-top: 24px;
}

.page-btn {
  width: 34px;
  height: 34px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface);
  font-size: 13px;
  color: var(--color-text-secondary);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s;
  cursor: pointer;
  font-family: inherit;
}

.page-btn:hover:not(:disabled):not(.active) {
  border-color: var(--color-text-secondary);
  color: var(--color-text-primary);
}

.page-btn.active {
  background: var(--p-500);
  color: #fff;
  border-color: var(--p-500);
  cursor: default;
}

.page-btn.nav {
  width: auto;
  padding: 0 10px;
}

.page-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}
</style>
