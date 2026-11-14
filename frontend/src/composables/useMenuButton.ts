import { nextTick, onBeforeUnmount, ref, watch } from "vue";

/**
 * Keyboard and pointer behaviour for a button that opens a `role="menu"`
 * (the ARIA menu button pattern):
 *
 * - Clicking the button, or Enter/Space on it, toggles the menu and focuses
 *   its first item. ArrowDown/ArrowUp on the button open it on the first/last
 *   item.
 * - In the menu, ArrowDown/ArrowUp move between items (wrapping), Home/End
 *   jump to the first/last one, and Escape closes it and returns focus to
 *   the button.
 * - Focus leaving the menu and button (Tab, or a click elsewhere) closes it.
 *
 * Bind the returned refs as `ref="wrapRef"` on an element holding both the
 * button and the menu, `ref="buttonRef"` on the button and `ref="menuRef"` on
 * the menu, then wire up the handlers:
 *
 *     <div ref="wrapRef" @focusout="onFocusout">
 *       <button ref="buttonRef" aria-haspopup="menu" :aria-expanded="isOpen"
 *         @click="toggle" @keydown="onButtonKeydown">…</button>
 *       <div v-if="isOpen" ref="menuRef" role="menu" @keydown="onMenuKeydown">…</div>
 *     </div>
 *
 * Items are the menu's visible `[role="menuitem"]` elements.
 */
export function useMenuButton() {
  const isOpen = ref(false);
  const wrapRef = ref<HTMLElement | null>(null);
  const buttonRef = ref<HTMLElement | null>(null);
  const menuRef = ref<HTMLElement | null>(null);

  // Items hidden with CSS (e.g. a phone-only item on a desktop) are skipped.
  function items(): HTMLElement[] {
    return Array.from(menuRef.value?.querySelectorAll<HTMLElement>('[role="menuitem"]') ?? []).filter((item) =>
      typeof item.checkVisibility === "function" ? item.checkVisibility() : true
    );
  }

  function open(focus: "first" | "last" = "first") {
    isOpen.value = true;
    void nextTick(() => {
      const all = items();
      all[focus === "first" ? 0 : all.length - 1]?.focus();
    });
  }

  function close(returnFocus = true) {
    if (!isOpen.value) {
      return;
    }
    isOpen.value = false;
    if (returnFocus) {
      buttonRef.value?.focus();
    }
  }

  function toggle() {
    if (isOpen.value) {
      close();
    } else {
      open();
    }
  }

  function onButtonKeydown(event: KeyboardEvent) {
    switch (event.key) {
      case "ArrowDown":
        event.preventDefault();
        open("first");
        break;
      case "ArrowUp":
        event.preventDefault();
        open("last");
        break;
      case "Escape":
        if (isOpen.value) {
          event.preventDefault();
          close();
        }
        break;
    }
  }

  function onMenuKeydown(event: KeyboardEvent) {
    const all = items();
    if (all.length === 0) {
      return;
    }
    const index = all.indexOf(document.activeElement as HTMLElement);
    switch (event.key) {
      case "ArrowDown":
        event.preventDefault();
        all[(index + 1) % all.length].focus();
        break;
      case "ArrowUp":
        event.preventDefault();
        all[(index - 1 + all.length) % all.length].focus();
        break;
      case "Home":
        event.preventDefault();
        all[0].focus();
        break;
      case "End":
        event.preventDefault();
        all[all.length - 1].focus();
        break;
      case "Escape":
        event.preventDefault();
        close();
        break;
    }
  }

  // Closes the menu once focus lands outside the button and menu. When focus
  // just leaves the page (relatedTarget null, e.g. switching windows), the
  // pointer handler below still catches a later click elsewhere.
  function onFocusout(event: FocusEvent) {
    const next = event.relatedTarget as Node | null;
    if (next && !wrapRef.value?.contains(next)) {
      close(false);
    }
  }

  function onDocumentPointerDown(event: PointerEvent) {
    if (wrapRef.value && !wrapRef.value.contains(event.target as Node)) {
      close(false);
    }
  }

  watch(isOpen, (value) => {
    if (value) {
      document.addEventListener("pointerdown", onDocumentPointerDown);
    } else {
      document.removeEventListener("pointerdown", onDocumentPointerDown);
    }
  });

  onBeforeUnmount(() => document.removeEventListener("pointerdown", onDocumentPointerDown));

  return { isOpen, wrapRef, buttonRef, menuRef, open, close, toggle, onButtonKeydown, onMenuKeydown, onFocusout };
}
