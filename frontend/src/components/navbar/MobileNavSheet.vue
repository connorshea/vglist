<template>
  <Teleport to="body">
    <!-- Backdrop -->
    <div class="mn-backdrop" :class="{ visible: isOpen }" @click="close" />

    <!-- Bottom sheet -->
    <div ref="sheetEl" class="mn-sheet" :class="{ open: isOpen, dragging: isDragging }" :style="dragStyle">
      <div class="mn-handle-area" @pointerdown="onPointerDown">
        <div class="mn-handle" />
      </div>

      <div class="mn-body">
        <!-- Nav links -->
        <ul class="mn-nav-list">
          <li class="mn-stagger">
            <router-link class="mn-nav-item" to="/activity" @click="close">
              <div class="mn-nav-icon ic-activity">
                <svg
                  viewBox="0 0 18 18"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="1.6"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <path d="M3 9h2l2-5 3 10 2-5h3" />
                </svg>
              </div>
              Activity
              <svg
                class="mn-arrow"
                width="16"
                height="16"
                viewBox="0 0 16 16"
                fill="none"
                stroke="currentColor"
                stroke-width="1.4"
                stroke-linecap="round"
              >
                <path d="M6 4l4 4-4 4" />
              </svg>
            </router-link>
          </li>
          <li class="mn-stagger">
            <router-link class="mn-nav-item" to="/games" @click="close">
              <div class="mn-nav-icon ic-games">
                <svg
                  viewBox="0 0 18 18"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="1.6"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <rect x="2" y="3" width="14" height="12" rx="2" />
                  <path d="M6 7h1M11 7h1M6 11c1 1 5 1 6 0" />
                </svg>
              </div>
              Games
              <svg
                class="mn-arrow"
                width="16"
                height="16"
                viewBox="0 0 16 16"
                fill="none"
                stroke="currentColor"
                stroke-width="1.4"
                stroke-linecap="round"
              >
                <path d="M6 4l4 4-4 4" />
              </svg>
            </router-link>
          </li>
          <li class="mn-stagger">
            <router-link class="mn-nav-item" to="/users" @click="close">
              <div class="mn-nav-icon ic-users">
                <svg
                  viewBox="0 0 18 18"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="1.6"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <circle cx="9" cy="6" r="3.5" />
                  <path d="M3 16c0-3 2.7-5 6-5s6 2 6 5" />
                </svg>
              </div>
              Users
              <svg
                class="mn-arrow"
                width="16"
                height="16"
                viewBox="0 0 16 16"
                fill="none"
                stroke="currentColor"
                stroke-width="1.4"
                stroke-linecap="round"
              >
                <path d="M6 4l4 4-4 4" />
              </svg>
            </router-link>
          </li>
        </ul>

        <div class="mn-divider mn-stagger" />

        <!-- Browse -->
        <div class="mn-section mn-stagger">Browse</div>
        <div class="mn-browse mn-stagger">
          <router-link class="mn-chip" to="/platforms" @click="close">Platforms</router-link>
          <router-link class="mn-chip" to="/genres" @click="close">Genres</router-link>
          <router-link class="mn-chip" to="/companies" @click="close">Companies</router-link>
          <router-link class="mn-chip" to="/engines" @click="close">Engines</router-link>
          <router-link class="mn-chip" to="/series" @click="close">Series</router-link>
          <router-link class="mn-chip" to="/stores" @click="close">Stores</router-link>
        </div>

        <div class="mn-divider mn-stagger" />

        <!-- User row (authenticated) -->
        <div v-if="authStore.isAuthenticated" class="mn-user mn-stagger">
          <div class="mn-avatar">
            {{ authStore.user?.username?.charAt(0).toUpperCase() }}
          </div>
          <router-link class="mn-user-info" :to="`/users/${authStore.user?.slug}`" @click="close">
            <div class="mn-user-name">{{ authStore.user?.username }}</div>
            <div class="mn-user-sub">View profile</div>
          </router-link>
          <div class="mn-user-actions">
            <button class="mn-ubtn" aria-label="Sign out" @click="handleSignOut">
              <svg
                viewBox="0 0 16 16"
                fill="none"
                stroke="currentColor"
                stroke-width="1.4"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <path d="M6 14H3.5a1 1 0 01-1-1V3a1 1 0 011-1H6M11 11l3-3-3-3M14 8H6" />
              </svg>
            </button>
          </div>
        </div>

        <!-- Auth buttons (not authenticated) -->
        <div v-else class="mn-auth-buttons mn-stagger">
          <router-link class="mn-auth-btn mn-auth-signin" to="/login" @click="close"> Sign in </router-link>
          <router-link class="mn-auth-btn mn-auth-signup" to="/signup" @click="close"> Create account </router-link>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, watch, computed, onMounted, onUnmounted } from "vue";
import { useRoute } from "vue-router";
import { useAuthStore } from "@/stores/auth";
import { useAuth } from "@/composables/useAuth";

const props = defineProps<{ isOpen: boolean }>();
const emit = defineEmits<{ (e: "close"): void }>();

const route = useRoute();
const authStore = useAuthStore();
const { signOut } = useAuth();

const sheetEl = ref<HTMLElement | null>(null);
const isDragging = ref(false);
const dragY = ref(0);

const dragStyle = computed(() => {
  if (!isDragging.value || dragY.value === 0) return {};
  return { transform: `translateY(${dragY.value}px)` };
});

function close() {
  emit("close");
}

function handleSignOut() {
  close();
  signOut();
}

// Close on route change
watch(() => route.path, close);

// Close on Escape
function onKeydown(e: KeyboardEvent) {
  if (e.key === "Escape" && props.isOpen) close();
}

onMounted(() => document.addEventListener("keydown", onKeydown));
onUnmounted(() => document.removeEventListener("keydown", onKeydown));

// Lock body scroll when open
watch(
  () => props.isOpen,
  (open) => {
    document.body.style.overflow = open ? "hidden" : "";
  }
);

// Drag to dismiss
let startY = 0;

function onPointerDown(e: PointerEvent) {
  startY = e.clientY;
  isDragging.value = true;
  dragY.value = 0;
  (e.target as HTMLElement).setPointerCapture(e.pointerId);

  const onMove = (ev: PointerEvent) => {
    const dy = ev.clientY - startY;
    if (dy < 0) {
      // Dragging up: apply rubber-band resistance, cap at -60px
      dragY.value = Math.max(-60, dy * 0.3);
    } else {
      // Dragging down: dismiss gesture
      dragY.value = dy;
    }
  };

  const onUp = () => {
    isDragging.value = false;
    if (dragY.value > 120) {
      close();
    }
    dragY.value = 0;
    document.removeEventListener("pointermove", onMove);
    document.removeEventListener("pointerup", onUp);
  };

  document.addEventListener("pointermove", onMove);
  document.addEventListener("pointerup", onUp);
}
</script>

<style scoped>
/* Backdrop */
.mn-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.4);
  z-index: 80;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.35s ease;
  -webkit-tap-highlight-color: transparent;
}

.mn-backdrop.visible {
  opacity: 1;
  pointer-events: auto;
}

/* Bottom sheet */
.mn-sheet {
  position: fixed;
  left: 0;
  right: 0;
  bottom: -80px;
  z-index: 90;
  background: var(--color-surface);
  border-radius: var(--radius-pill) var(--radius-pill) 0 0;
  padding: 0 0 calc(80px + env(safe-area-inset-bottom, 0));
  transform: translateY(100%);
  transition: transform 0.4s cubic-bezier(0.32, 0.72, 0, 1);
  will-change: transform;
  max-height: calc(85vh + 80px);
  overflow-y: auto;
  overscroll-behavior: contain;
  -webkit-overflow-scrolling: touch;
  box-shadow: 0 -4px 32px rgba(0, 0, 0, 0.12);
}

.mn-sheet.open {
  transform: translateY(0);
}

.mn-sheet.dragging {
  transition: none;
}

/* Handle */
.mn-handle-area {
  display: flex;
  justify-content: center;
  padding: 12px 0 6px;
  cursor: grab;
  -webkit-tap-highlight-color: transparent;
  touch-action: none;
}

.mn-handle {
  width: 36px;
  height: 4px;
  border-radius: 2px;
  background: var(--color-border);
}

.mn-body {
  padding: 4px 20px 24px;
}

/* Nav links */
.mn-nav-list {
  list-style: none;
  margin: 0;
  padding: 0;
  margin-bottom: 18px;
}

.mn-nav-item {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 13px 12px;
  border-radius: var(--radius-lg);
  text-decoration: none;
  color: var(--color-text-primary);
  font-size: 15px;
  font-weight: 500;
  transition: background 0.15s;
  -webkit-tap-highlight-color: transparent;
}

.mn-nav-item:active {
  background: var(--color-bg-subtle);
}

@media (prefers-color-scheme: dark) {
  .mn-nav-item:active {
    background: rgba(255, 255, 255, 0.08);
  }
}

.mn-nav-icon {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.mn-nav-icon svg {
  width: 18px;
  height: 18px;
}

.mn-nav-icon.ic-activity {
  background: var(--p-100);
  color: var(--p-700);
}

.mn-nav-icon.ic-games {
  background: var(--p-50);
  color: var(--p-600);
}

.mn-nav-icon.ic-users {
  background: var(--p-100);
  color: var(--p-600);
}

.mn-arrow {
  margin-left: auto;
  color: var(--color-border);
  flex-shrink: 0;
}

/* Divider */
.mn-divider {
  height: 0.5px;
  background: var(--color-border);
  margin: 2px 12px 16px;
}

/* Section label */
.mn-section {
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.6px;
  color: var(--color-text-tertiary);
  padding: 0 12px;
  margin-bottom: 10px;
}

/* Browse chips */
.mn-browse {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  padding: 0 8px;
  margin-bottom: 20px;
}

.mn-chip {
  padding: 8px 16px;
  border-radius: var(--radius-pill);
  background: var(--color-bg-subtle);
  border: 0.5px solid var(--color-border);
  color: var(--color-text-secondary);
  font-size: 13px;
  font-weight: 500;
  text-decoration: none;
  transition:
    background 0.15s,
    border-color 0.15s;
  -webkit-tap-highlight-color: transparent;
}

@media (prefers-color-scheme: dark) {
  .mn-chip {
    background: rgba(255, 255, 255, 0.08);
    border-color: rgba(255, 255, 255, 0.15);
    color: var(--color-text-secondary);
  }
}

.mn-chip:active {
  background: var(--n-100);
  border-color: var(--color-text-tertiary);
}

/* User row */
.mn-user {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 12px;
  border-radius: var(--radius-lg);
  background: var(--color-bg-subtle);
  margin-top: 4px;
}

@media (prefers-color-scheme: dark) {
  .mn-user {
    background: rgba(255, 255, 255, 0.06);
  }
}

.mn-avatar {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  background: var(--p-500);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 15px;
  color: #fff;
  flex-shrink: 0;
}

.mn-user-info {
  flex: 1;
  min-width: 0;
  text-decoration: none;
}

.mn-user-name {
  font-size: 14px;
  font-weight: 600;
  color: var(--color-text-primary);
}

.mn-user-sub {
  font-size: 12px;
  color: var(--color-text-secondary);
}

.mn-user-actions {
  display: flex;
  gap: 6px;
}

.mn-ubtn {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  border: 0.5px solid var(--color-border);
  background: var(--color-surface);
  color: var(--color-text-secondary);
  display: flex;
  align-items: center;
  justify-content: center;
  text-decoration: none;
  cursor: pointer;
  -webkit-tap-highlight-color: transparent;
  transition: background 0.15s;
}

@media (prefers-color-scheme: dark) {
  .mn-ubtn {
    border-color: var(--color-border);
  }
}

.mn-ubtn:active {
  background: var(--n-100);
}

.mn-ubtn svg {
  width: 15px;
  height: 15px;
}

/* Auth buttons (logged out) */
.mn-auth-buttons {
  display: flex;
  gap: 10px;
  margin-top: 4px;
}

.mn-auth-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 12px 16px;
  border-radius: var(--radius-lg);
  font-size: 14px;
  font-weight: 600;
  text-decoration: none;
  transition: background 0.15s;
  -webkit-tap-highlight-color: transparent;
}

.mn-auth-signin {
  background: var(--color-bg-subtle);
  border: 0.5px solid var(--color-border);
  color: var(--color-text-primary);
}

.mn-auth-signin:active {
  background: var(--n-100);
}

.mn-auth-signup {
  background: var(--p-500);
  border: 0.5px solid var(--p-500);
  color: #fff;
}

.mn-auth-signup:active {
  background: var(--p-600);
}

/* Stagger animation */
.mn-sheet.open .mn-stagger {
  animation: mn-stagger-up 0.35s cubic-bezier(0.32, 0.72, 0, 1) both;
}

.mn-sheet.open .mn-stagger:nth-child(1) {
  animation-delay: 0.06s;
}

.mn-sheet.open .mn-stagger:nth-child(2) {
  animation-delay: 0.09s;
}

.mn-sheet.open .mn-stagger:nth-child(3) {
  animation-delay: 0.12s;
}

.mn-sheet.open .mn-stagger:nth-child(4) {
  animation-delay: 0.15s;
}

.mn-sheet.open .mn-stagger:nth-child(5) {
  animation-delay: 0.18s;
}

.mn-sheet.open .mn-stagger:nth-child(6) {
  animation-delay: 0.21s;
}

.mn-sheet.open .mn-stagger:nth-child(7) {
  animation-delay: 0.24s;
}

@keyframes mn-stagger-up {
  from {
    opacity: 0;
    transform: translateY(12px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Only show on touch/mobile */
@media screen and (min-width: 1024px) {
  .mn-backdrop,
  .mn-sheet {
    display: none !important;
  }
}
</style>
