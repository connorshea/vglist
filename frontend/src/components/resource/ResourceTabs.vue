<template>
  <nav class="res-tabs scroll-fade-x" :aria-label="label">
    <router-link
      v-for="tab in tabs"
      :key="tab.label"
      :to="tab.to"
      class="res-tab"
      :class="{ 'is-active': tab.active }"
      :aria-current="tab.active ? 'page' : undefined"
      replace
    >
      {{ tab.label }}
      <span class="res-tab-count">{{ tab.count.toLocaleString() }}</span>
    </router-link>
  </nav>
</template>

<script setup lang="ts">
import type { RouteLocationRaw } from "vue-router";

export interface ResourceTab {
  label: string;
  count: number;
  to: RouteLocationRaw;
  active: boolean;
}

defineProps<{
  label: string;
  tabs: ResourceTab[];
}>();
</script>

<style scoped>
.res-tabs {
  display: flex;
  margin-top: 1.75rem;
  overflow-x: auto;
}

.res-tab {
  display: inline-flex;
  align-items: baseline;
  gap: 6px;
  padding: 10px 18px;
  font-size: 0.875rem;
  white-space: nowrap;
  color: var(--color-text-secondary);
  border-bottom: 2px solid transparent;
  /* Sits on top of the header's bottom border. */
  margin-bottom: -1px;
}

.res-tab:hover {
  color: var(--color-text-primary);
}

.res-tab.is-active {
  color: var(--color-accent);
  border-bottom-color: var(--color-accent);
  font-weight: 500;
}

.res-tab-count {
  font-size: 0.6875rem;
  color: var(--color-text-tertiary);
}

.res-tab:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: -2px;
  border-radius: var(--radius-sm) var(--radius-sm) 0 0;
}
</style>
