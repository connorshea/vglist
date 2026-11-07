import { ref, nextTick } from "vue";

const isOpen = ref(false);

// Text typed into a search box outside the overlay (the navbar's, or the home
// page's) before the overlay opened, so the overlay can start with it.
let initialQuery = "";

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
  function open(query = "") {
    initialQuery = query;
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

  /** Returns the query the overlay was opened with, and forgets it. */
  function takeInitialQuery(): string {
    const query = initialQuery;
    initialQuery = "";
    return query;
  }

  return { isOpen, open, close, toggle, takeInitialQuery };
}
