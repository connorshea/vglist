<template>
  <img v-if="avatarUrl" class="nav-avatar" :src="avatarUrl" alt="" />
  <span v-else class="nav-avatar is-initial" aria-hidden="true">{{ initial }}</span>
</template>

<script setup lang="ts">
import { computed } from "vue";

// The signed-in user's avatar, or their initial when they haven't uploaded
// one. Decorative: the username or an aria-label always sits beside it.
// Parents size and shape it through the `nav-avatar` class.
const props = defineProps<{
  username: string;
  avatarUrl?: string | null;
}>();

const initial = computed(() => props.username.charAt(0).toUpperCase());
</script>

<style scoped>
.nav-avatar {
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  object-fit: cover;
  font-weight: 700;
  line-height: 1;
  user-select: none;
}
</style>
