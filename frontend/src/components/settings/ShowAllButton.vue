<template>
  <button type="button" class="show-all" :aria-expanded="expanded" @click="emit('toggle')">
    {{ expanded ? "Show fewer" : `Show all ${total}` }}
    <ChevronDown :size="14" class="show-all-icon" :class="{ 'is-expanded': expanded }" aria-hidden="true" />
  </button>
</template>

<script setup lang="ts">
import { ChevronDown } from "@lucide/vue";

defineProps<{
  expanded: boolean;
  total: number;
}>();

const emit = defineEmits<{
  toggle: [];
}>();
</script>

<style scoped>
.show-all {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  margin-top: 8px;
  padding: 4px 6px;
  border: 0;
  border-radius: var(--radius-sm);
  background: none;
  color: var(--color-accent);
  font: inherit;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.show-all:hover {
  background: var(--color-bg-subtle);
}

.show-all:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.show-all-icon {
  transition: transform 0.15s;
}

.show-all-icon.is-expanded {
  transform: rotate(180deg);
}

@media (prefers-reduced-motion: reduce) {
  .show-all-icon {
    transition: none;
  }
}
</style>
