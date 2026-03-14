import { ref, nextTick } from "vue";

const isOpen = ref(false);

function withViewTransition(callback: () => void): void {
  if ("startViewTransition" in document) {
    (document as { startViewTransition: (cb: () => Promise<void>) => void }).startViewTransition(async () => {
      callback();
      await nextTick();
    });
  } else {
    callback();
  }
}

export function useSearchOverlay() {
  function open() {
    withViewTransition(() => {
      isOpen.value = true;
    });
  }

  function close() {
    withViewTransition(() => {
      isOpen.value = false;
    });
  }

  function toggle() {
    if (isOpen.value) {
      close();
    } else {
      open();
    }
  }

  return { isOpen, open, close, toggle };
}
