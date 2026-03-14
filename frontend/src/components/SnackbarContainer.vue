<template>
  <div class="snackbar-container" aria-live="polite">
    <TransitionGroup name="snackbar">
      <div
        v-for="msg in messages"
        :key="msg.id"
        class="snackbar"
        :class="msg.type === 'error' ? 'snackbar-error' : 'snackbar-success'"
        :role="msg.type === 'error' ? 'alert' : 'status'"
      >
        <span class="snackbar-text">{{ msg.text }}</span>
        <button class="snackbar-close" aria-label="Dismiss" @click="dismiss(msg.id)">
          &times;
        </button>
      </div>
    </TransitionGroup>
  </div>
</template>

<script setup lang="ts">
import { useSnackbar } from "@/composables/useSnackbar";

const { messages, dismiss } = useSnackbar();
</script>

<style scoped>
.snackbar-container {
  position: fixed;
  bottom: 20px;
  left: 20px;
  z-index: 10000;
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-width: 400px;
}

.snackbar {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border-radius: 8px;
  color: #fff;
  font-size: 14px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
}

.snackbar-success {
  background: #48c774;
}

.snackbar-error {
  background: #f14668;
}

.snackbar-text {
  flex: 1;
}

.snackbar-close {
  background: none;
  border: none;
  color: #fff;
  font-size: 18px;
  cursor: pointer;
  padding: 0 4px;
  opacity: 0.8;
  line-height: 1;
}

.snackbar-close:hover {
  opacity: 1;
}

.snackbar-enter-active,
.snackbar-leave-active {
  transition: all 0.3s ease;
}

.snackbar-enter-from {
  transform: translateX(-100%);
  opacity: 0;
}

.snackbar-leave-to {
  transform: translateX(-100%);
  opacity: 0;
}
</style>
