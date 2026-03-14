<template>
  <Teleport to="body">
    <Transition name="confirm-dialog">
      <div
        v-if="modelValue"
        class="cd-overlay"
        role="dialog"
        aria-modal="true"
        :aria-label="title"
        @keydown="onKeydown"
      >
        <div class="cd-backdrop" @click="cancel"></div>
        <div ref="dialogRef" class="cd-modal" tabindex="-1">
          <div class="cd-body">
            <div v-if="$slots.icon" class="cd-icon">
              <slot name="icon" />
            </div>
            <div class="cd-title">{{ title }}</div>
            <div class="cd-desc">
              <slot />
            </div>
          </div>
          <div class="cd-actions">
            <button class="cd-btn cd-btn-danger" :disabled="loading" @click="$emit('confirm')">
              <Trash2 :size="15" :stroke-width="2" />
              {{ loading ? loadingLabel : confirmLabel }}
            </button>
            <button class="cd-btn cd-btn-cancel" @click="cancel">
              {{ cancelLabel }}
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, watch, nextTick, onBeforeUnmount } from "vue";
import { Trash2 } from "lucide-vue-next";

const props = withDefaults(
  defineProps<{
    modelValue: boolean;
    title: string;
    confirmLabel?: string;
    loadingLabel?: string;
    cancelLabel?: string;
    loading?: boolean;
  }>(),
  {
    confirmLabel: "Remove from library",
    loadingLabel: "Removing\u2026",
    cancelLabel: "Cancel",
    loading: false
  }
);

const emit = defineEmits<{
  "update:modelValue": [value: boolean];
  confirm: [];
}>();

const dialogRef = ref<HTMLElement | null>(null);
let previouslyFocusedElement: HTMLElement | null = null;

function cancel() {
  emit("update:modelValue", false);
}

function getFocusableElements(): HTMLElement[] {
  if (!dialogRef.value) return [];
  return Array.from(
    dialogRef.value.querySelectorAll<HTMLElement>(
      'button:not([disabled]), [href], input:not([disabled]), [tabindex]:not([tabindex="-1"])'
    )
  );
}

function onKeydown(e: KeyboardEvent) {
  if (e.key === "Escape") {
    cancel();
    return;
  }

  if (e.key === "Tab") {
    const focusable = getFocusableElements();
    if (focusable.length === 0) return;

    const first = focusable[0];
    const last = focusable[focusable.length - 1];

    if (e.shiftKey) {
      if (document.activeElement === first) {
        e.preventDefault();
        last.focus();
      }
    } else {
      if (document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
    }
  }
}

watch(
  () => props.modelValue,
  (isOpen) => {
    if (isOpen) {
      previouslyFocusedElement = document.activeElement as HTMLElement | null;
      nextTick(() => {
        dialogRef.value?.focus();
      });
    } else {
      previouslyFocusedElement?.focus();
      previouslyFocusedElement = null;
    }
  }
);

onBeforeUnmount(() => {
  emit("update:modelValue", false);
});
</script>

<style scoped>
.cd-overlay {
  position: fixed;
  inset: 0;
  z-index: 100;
  display: flex;
  align-items: center;
  justify-content: center;
}

.cd-backdrop {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.45);
}

.cd-modal {
  position: relative;
  width: calc(100% - 48px);
  max-width: 320px;
  border-radius: 16px;
  background: var(--color-surface);
  box-shadow:
    0 16px 48px rgba(0, 0, 0, 0.12),
    0 2px 8px rgba(0, 0, 0, 0.06);
  outline: none;
}

.cd-modal:focus-visible {
  outline: 2px solid var(--vglist-theme);
  outline-offset: 2px;
}

.cd-body {
  padding: 28px 24px 24px;
  text-align: center;
}

.cd-icon {
  width: 48px;
  height: 48px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 16px;
  background: var(--r-50);
  color: var(--r-500);
}

.cd-title {
  font-size: 17px;
  font-weight: 600;
  color: var(--color-text-primary);
  margin-bottom: 8px;
}

.cd-desc {
  font-size: 14px;
  line-height: 1.55;
  color: var(--color-text-secondary);
}

.cd-desc :deep(strong) {
  font-weight: 600;
  color: var(--color-text-primary);
}

.cd-actions {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 0 24px 24px;
}

.cd-btn {
  width: 100%;
  padding: 12px;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 500;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border: none;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.15s;
}

.cd-btn:active {
  transform: scale(0.98);
}

.cd-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.cd-btn-danger {
  background: var(--r-500);
  color: #fff;
}

.cd-btn-danger:active:not(:disabled) {
  background: #c93c3b;
}

.cd-btn-cancel {
  background: var(--color-bg-subtle);
  color: var(--color-text-secondary);
}

.cd-btn-cancel:hover {
  background: var(--color-border);
}

/* Transition */
.confirm-dialog-enter-active {
  transition: opacity 0.2s ease;
}

.confirm-dialog-enter-active .cd-modal {
  transition:
    opacity 0.2s ease,
    transform 0.2s ease;
}

.confirm-dialog-leave-active {
  transition: opacity 0.15s ease;
}

.confirm-dialog-leave-active .cd-modal {
  transition:
    opacity 0.15s ease,
    transform 0.15s ease;
}

.confirm-dialog-enter-from {
  opacity: 0;
}

.confirm-dialog-enter-from .cd-modal {
  opacity: 0;
  transform: scale(0.95);
}

.confirm-dialog-leave-to {
  opacity: 0;
}

.confirm-dialog-leave-to .cd-modal {
  opacity: 0;
  transform: scale(0.95);
}

/* Dark mode */
@media (prefers-color-scheme: dark) {
  .cd-modal {
    box-shadow:
      0 16px 48px rgba(0, 0, 0, 0.35),
      0 2px 8px rgba(0, 0, 0, 0.2);
    border: 1px solid var(--s-300);
  }

  .cd-icon {
    background: rgba(226, 75, 74, 0.15);
    color: var(--r-200);
  }

  .cd-btn-cancel {
    background: var(--s-500);
    color: var(--s-200);
  }

  .cd-btn-cancel:hover {
    background: var(--s-600);
  }
}
</style>
