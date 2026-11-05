<template>
  <Teleport to="body">
    <div class="lsheet-scrim" aria-hidden="true" @click="emit('close')"></div>
    <div
      ref="sheetRef"
      class="lsheet"
      role="dialog"
      aria-modal="true"
      aria-labelledby="lsheet-title"
      tabindex="-1"
      @keydown="onKeydown"
    >
      <div class="lsheet-handle" aria-hidden="true"><span></span></div>
      <div class="lsheet-head">
        <img v-if="coverUrl" class="lsheet-cover" :src="coverUrl" alt="" />
        <div class="lsheet-titles">
          <h2 id="lsheet-title" class="lsheet-title">{{ title }}</h2>
          <p class="lsheet-subtitle">{{ gameName }}</p>
        </div>
        <button type="button" class="lsheet-close" aria-label="Close" @click="emit('close')">
          <X :size="22" :stroke-width="1.8" aria-hidden="true" />
        </button>
      </div>
      <div class="lsheet-body">
        <slot />
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { nextTick, onBeforeUnmount, onMounted, ref } from "vue";
import { X } from "@lucide/vue";

defineProps<{
  title: string;
  gameName: string;
  coverUrl: string | null;
}>();

const emit = defineEmits<{ close: [] }>();

const sheetRef = ref<HTMLElement | null>(null);

const FOCUSABLE =
  'a[href], button:not([disabled]), input:not([disabled]), textarea:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])';

function focusables(): HTMLElement[] {
  return Array.from(sheetRef.value?.querySelectorAll<HTMLElement>(FOCUSABLE) ?? []);
}

// Escape closes the sheet, and Tab stays inside it while it's open.
function onKeydown(e: KeyboardEvent) {
  if (e.key === "Escape") {
    e.preventDefault();
    emit("close");
    return;
  }
  if (e.key !== "Tab") return;
  const items = focusables();
  if (items.length === 0) return;
  const first = items[0];
  const last = items[items.length - 1];
  if (document.activeElement === sheetRef.value) {
    e.preventDefault();
    (e.shiftKey ? last : first).focus();
  } else if (e.shiftKey && document.activeElement === first) {
    e.preventDefault();
    last.focus();
  } else if (!e.shiftKey && document.activeElement === last) {
    e.preventDefault();
    first.focus();
  }
}

// Focus the sheet itself rather than its first field, so opening it doesn't
// pop up the on-screen keyboard. The page behind it doesn't scroll.
onMounted(() => {
  document.body.style.overflow = "hidden";
  void nextTick(() => sheetRef.value?.focus());
});

onBeforeUnmount(() => {
  document.body.style.overflow = "";
});
</script>

<style scoped>
.lsheet-scrim {
  position: fixed;
  inset: 0;
  z-index: 45;
  background: rgba(0, 0, 0, 0.45);
  animation: lsheet-fade 0.2s ease;
}

.lsheet {
  position: fixed;
  z-index: 50;
  left: 0;
  right: 0;
  bottom: 0;
  display: flex;
  flex-direction: column;
  max-height: 92dvh;
  background: var(--color-surface);
  color: var(--color-text-primary);
  border-radius: 20px 20px 0 0;
  box-shadow: 0 -4px 32px rgba(0, 0, 0, 0.12);
  outline: none;
  animation: lsheet-rise 0.25s ease;
}

.lsheet-handle {
  display: flex;
  justify-content: center;
  padding: 10px 0 6px;
}

.lsheet-handle span {
  width: 36px;
  height: 4px;
  border-radius: 2px;
  background: var(--color-border);
}

.lsheet-head {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 0 8px 12px 20px;
  border-bottom: 1px solid var(--color-border);
}

.lsheet-cover {
  width: 40px;
  aspect-ratio: 3 / 4;
  flex-shrink: 0;
  object-fit: cover;
  border-radius: 6px;
}

.lsheet-titles {
  min-width: 0;
}

.lsheet-title {
  margin: 0;
  font-size: 17px;
  font-weight: 700;
  line-height: 1.25;
}

.lsheet-subtitle {
  margin: 2px 0 0;
  overflow: hidden;
  font-size: 13px;
  color: var(--n-500);
  text-overflow: ellipsis;
  white-space: nowrap;
}

.lsheet-close {
  display: flex;
  flex-shrink: 0;
  align-items: center;
  justify-content: center;
  width: 44px;
  height: 44px;
  margin-left: auto;
  border: none;
  border-radius: 50%;
  background: transparent;
  color: var(--n-500);
  cursor: pointer;
}

.lsheet-close:focus-visible {
  outline: 2px solid var(--p-500);
  outline-offset: 2px;
}

.lsheet-body {
  flex: 1;
  min-height: 0;
  overflow-y: auto;
  overscroll-behavior: contain;
}

@keyframes lsheet-rise {
  from {
    transform: translateY(100%);
  }
}

@keyframes lsheet-fade {
  from {
    opacity: 0;
  }
}

@media (prefers-reduced-motion: reduce) {
  .lsheet,
  .lsheet-scrim {
    animation: none;
  }
}

@media (prefers-color-scheme: dark) {
  .lsheet-subtitle,
  .lsheet-close {
    color: var(--s-100);
  }
}
</style>
