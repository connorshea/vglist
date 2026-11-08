<template>
  <div
    ref="rootEl"
    class="navbar-item has-dropdown"
    :class="{ 'is-active': isOpen }"
    @mouseenter="onMouseEnter"
    @mouseleave="onMouseLeave"
    @focusout="onFocusOut"
    @keydown="onKeydown"
  >
    <button
      ref="triggerEl"
      type="button"
      class="navbar-link nav-dropdown-trigger"
      :class="triggerClass"
      :aria-expanded="isOpen"
      :aria-controls="menuId"
      @click="onTriggerClick"
    >
      <slot name="trigger" />
    </button>
    <div
      :id="menuId"
      ref="menuEl"
      class="navbar-dropdown nav-menu"
      :class="[menuClass, { 'is-right': alignRight }]"
      @click="onMenuClick"
    >
      <slot />
    </div>
  </div>
</template>

<script setup lang="ts">
import { nextTick, ref, useId, watch } from "vue";
import { useRoute } from "vue-router";

// A navbar dropdown that works with the mouse and the keyboard (the ARIA
// disclosure pattern): hover or click the trigger to open it, Enter/Space to
// toggle, ArrowDown/ArrowUp to open it and move through the items, Home/End
// to jump, and Escape to close it and return focus to the trigger. Tabbing
// out or picking an item closes it.
withDefaults(
  defineProps<{
    alignRight?: boolean;
    triggerClass?: string;
    menuClass?: string;
  }>(),
  { alignRight: false, triggerClass: "", menuClass: "" }
);

const isOpen = ref(false);
// Set while the menu is open only because the pointer is over it, so a click
// on the trigger then keeps it open instead of toggling it shut.
const openedByHover = ref(false);
const rootEl = ref<HTMLElement | null>(null);
const triggerEl = ref<HTMLButtonElement | null>(null);
const menuEl = ref<HTMLElement | null>(null);
const menuId = `nav-dropdown-${useId()}`;

const route = useRoute();
watch(
  () => route.path,
  () => {
    isOpen.value = false;
  }
);

watch(isOpen, (open) => {
  if (!open) {
    openedByHover.value = false;
  }
});

function onMouseEnter() {
  if (isOpen.value) {
    return;
  }
  isOpen.value = true;
  openedByHover.value = true;
}

function onMouseLeave() {
  isOpen.value = false;
  openedByHover.value = false;
}

function onTriggerClick() {
  if (openedByHover.value) {
    openedByHover.value = false;
    return;
  }
  isOpen.value = !isOpen.value;
}

function items(): HTMLElement[] {
  return Array.from(menuEl.value?.querySelectorAll<HTMLElement>("a[href], button:not([disabled])") ?? []);
}

async function openAndFocus(which: "first" | "last") {
  isOpen.value = true;
  await nextTick();
  const all = items();
  all[which === "first" ? 0 : all.length - 1]?.focus();
}

function moveFocus(step: 1 | -1) {
  const all = items();
  if (all.length === 0) {
    return;
  }
  const current = all.indexOf(document.activeElement as HTMLElement);
  const next = current === -1 ? 0 : (current + step + all.length) % all.length;
  all[next].focus();
}

function onKeydown(event: KeyboardEvent) {
  const inMenu = menuEl.value?.contains(event.target as Node) ?? false;

  switch (event.key) {
    case "Escape":
      if (!isOpen.value) {
        return;
      }
      event.preventDefault();
      isOpen.value = false;
      triggerEl.value?.focus();
      break;
    case "ArrowDown":
      event.preventDefault();
      if (inMenu) {
        moveFocus(1);
      } else {
        void openAndFocus("first");
      }
      break;
    case "ArrowUp":
      event.preventDefault();
      if (inMenu) {
        moveFocus(-1);
      } else {
        void openAndFocus("last");
      }
      break;
    case "Home":
    case "End":
      if (!inMenu) {
        return;
      }
      event.preventDefault();
      void openAndFocus(event.key === "Home" ? "first" : "last");
      break;
  }
}

// Close when focus moves somewhere outside the dropdown (e.g. Tab past the last item).
function onFocusOut(event: FocusEvent) {
  const next = event.relatedTarget as Node | null;
  if (next && rootEl.value?.contains(next)) {
    return;
  }
  isOpen.value = false;
}

// Picking an item closes the menu, including links that open a new tab.
function onMenuClick(event: MouseEvent) {
  if ((event.target as HTMLElement).closest("a, button")) {
    isOpen.value = false;
  }
}
</script>

<style scoped>
.nav-dropdown-trigger {
  border: 0;
  background: none;
  color: inherit;
  font: inherit;
  cursor: pointer;
}

.nav-dropdown-trigger:focus-visible {
  outline: 2px solid #fff;
  outline-offset: -8px;
  border-radius: 8px;
}

/* Navbar dropdowns are cards that follow the page theme, with rounded items. */
.navbar-dropdown.nav-menu {
  --nav-menu-muted: var(--n-500);
  min-width: 200px;
  padding: 6px;
  border: 1px solid var(--color-border);
  border-radius: 12px;
  background-color: var(--color-surface);
  box-shadow:
    0 16px 48px rgba(0, 0, 0, 0.12),
    0 2px 8px rgba(0, 0, 0, 0.06);
  color: var(--color-text-primary);
  font-size: 0.875rem;
}

@media (prefers-color-scheme: dark) {
  .navbar-dropdown.nav-menu {
    --nav-menu-muted: var(--s-100);
    box-shadow:
      0 16px 48px rgba(0, 0, 0, 0.4),
      0 2px 8px rgba(0, 0, 0, 0.25);
  }
}
</style>
