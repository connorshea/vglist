<template>
  <div class="user-card-skeleton" aria-hidden="true">
    <SkeletonBlock class="s-avatar" :style="{ width: `${size}px`, height: `${size}px` }" />
    <div class="s-line s-username">
      <SkeletonBlock class="s-bar" :style="{ width: nameWidth, height: '9px' }" />
    </div>
    <template v-if="meta">
      <div class="s-line s-game-count">
        <SkeletonBlock class="s-bar" :style="{ width: '52px', height: '7px' }" />
      </div>
      <div class="s-line s-joined">
        <SkeletonBlock class="s-bar" :style="{ width: '64px', height: '6px' }" />
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import SkeletonBlock from "@/components/SkeletonBlock.vue";

// Stands in for a UserCard while a list of users loads. The border, padding, avatar size and line boxes are copied from
// UserCard so the grid doesn't move when the real cards arrive; keep them in
// step.
withDefaults(
  defineProps<{
    size?: number;
    // Width of the username bar, varied by the parent so the grid isn't a
    // pattern.
    nameWidth?: string;
    // Whether the card shows the game count and join date lines.
    meta?: boolean;
  }>(),
  { size: 48, nameWidth: "60%", meta: true }
);
</script>

<style scoped>
.user-card-skeleton {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 18px 12px 14px;
  overflow: hidden;
}

.s-avatar {
  border-radius: 50%;
  margin: 0 auto 8px;
}

/* Each row is the height of the real line box, with a shorter bar centred in
   it. */
.s-line {
  display: flex;
  align-items: center;
  justify-content: center;
}

.s-bar {
  border-radius: 4px;
}

.s-username {
  height: calc(12px * 1.5);
  margin-bottom: 2px;
}

.s-game-count {
  height: calc(11px * 1.5);
}

.s-joined {
  height: calc(10px * 1.5);
  margin-top: 1px;
}
</style>
