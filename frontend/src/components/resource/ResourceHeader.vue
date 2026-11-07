<template>
  <header class="res-head" :class="{ 'has-tabs': !!$slots.tabs }">
    <div class="container res-head-inner">
      <div class="res-head-top">
        <div class="res-head-text">
          <span class="res-kind">
            <component :is="icon" :size="14" :stroke-width="2" aria-hidden="true" />
            {{ kind }}
          </span>
          <h1 class="res-name">{{ name }}</h1>
          <div v-if="$slots.facts || wikidataId" class="res-facts">
            <slot name="facts" />
            <a
              v-if="wikidataId"
              class="res-wikidata"
              :href="`https://www.wikidata.org/wiki/Q${wikidataId}`"
              target="_blank"
              rel="noopener noreferrer"
            >
              Wikidata
              <ExternalLink :size="14" aria-hidden="true" />
              <span class="is-sr-only">(opens in a new tab)</span>
            </a>
          </div>
        </div>
        <div v-if="editTo" class="res-actions">
          <router-link :to="editTo" class="res-btn">Edit</router-link>
          <button type="button" class="res-btn is-danger" @click="emit('delete')">Delete</button>
        </div>
      </div>
      <slot name="tabs" />
    </div>
  </header>
</template>

<script setup lang="ts">
import type { Component } from "vue";
import type { RouteLocationRaw } from "vue-router";
import { ExternalLink } from "@lucide/vue";

defineProps<{
  // What sort of resource this is, e.g. "Company".
  kind: string;
  icon: Component;
  name: string;
  wikidataId?: number | null;
  // Where the Edit button goes. Edit and Delete are hidden when this is null,
  // i.e. for anyone who isn't a moderator.
  editTo?: RouteLocationRaw | null;
}>();

const emit = defineEmits<{
  delete: [];
}>();
</script>

<style scoped>
/* Breaks out of the page container so the band spans the full width. */
.res-head {
  width: 100vw;
  margin-left: calc(50% - 50vw);
  margin-top: -3rem;
  background: var(--color-bg-subtle);
  border-bottom: 1px solid var(--color-border);
}

.res-head-inner {
  padding: 2.5rem 1.5rem 1.75rem;
}

.res-head.has-tabs .res-head-inner {
  padding-bottom: 0;
}

@media screen and (min-width: 1024px) {
  .res-head-inner {
    padding-left: 0;
    padding-right: 0;
  }
}

.res-head-top {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: wrap;
}

.res-head-text {
  min-width: 0;
}

.res-kind {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 0.7rem;
  font-weight: 600;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--color-accent);
}

.res-name {
  font-size: 2.5rem;
  font-weight: 700;
  line-height: 1.15;
  margin: 6px 0 8px;
  color: var(--color-text-primary);
  overflow-wrap: anywhere;
}

@media screen and (max-width: 768px) {
  .res-name {
    font-size: 1.85rem;
  }
}

.res-facts {
  display: flex;
  gap: 8px 24px;
  font-size: 0.8125rem;
  color: var(--color-text-secondary);
  flex-wrap: wrap;
}

.res-facts :deep(b) {
  color: var(--color-text-primary);
  font-weight: 600;
}

.res-wikidata {
  display: inline-flex;
  gap: 4px;
  align-items: center;
  color: var(--color-accent);
  font-weight: 500;
}

.res-actions {
  display: flex;
  gap: 8px;
}

.res-btn {
  display: inline-flex;
  align-items: center;
  padding: 6px 16px;
  font: inherit;
  font-size: 0.8125rem;
  font-weight: 500;
  line-height: 1.4;
  color: var(--color-text-primary);
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: border-color var(--transition-fast);
}

.res-btn:hover {
  border-color: var(--color-text-tertiary);
  color: var(--color-text-primary);
}

.res-btn.is-danger {
  color: var(--color-danger-text);
}

.res-btn:focus-visible,
.res-wikidata:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}
</style>
