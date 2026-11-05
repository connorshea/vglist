<template>
  <span class="user-avatar" :style="{ width: `${size}px`, height: `${size}px` }">
    <img v-if="user.avatarUrl" :src="user.avatarUrl" alt="" />
    <span
      v-else
      class="user-avatar-initials"
      :style="{ background: avatarColor(user.username), fontSize: `${Math.round(size * 0.38)}px` }"
    >
      {{ userInitials(user.username) }}
    </span>
  </span>
</template>

<script setup lang="ts">
import { avatarColor, userInitials } from "@/utils/avatar";

// Decorative: the username always sits next to it (or in the parent link's
// accessible name), so the image has empty alt text.
withDefaults(
  defineProps<{
    user: { username: string; avatarUrl?: string | null };
    size?: number;
  }>(),
  { size: 32 }
);
</script>

<style scoped>
.user-avatar {
  display: inline-flex;
  flex-shrink: 0;
  border-radius: 50%;
  overflow: hidden;
}

.user-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.user-avatar-initials {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  color: #fff;
  user-select: none;
}
</style>
