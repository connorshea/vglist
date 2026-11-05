<template>
  <template v-for="(item, i) in items" :key="item.id">
    <template v-if="i > 0">, </template>
    <router-link :to="`${base}/${item.id}`">{{ item.name }}</router-link>
  </template>
</template>

<script setup lang="ts">
// "Windows, macOS, Linux", with each name linking to its page.
defineProps<{
  items: { id: string; name: string }[];
  base: string;
}>();
</script>
