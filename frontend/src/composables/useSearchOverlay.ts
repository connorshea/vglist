import { ref } from "vue";

const isOpen = ref(false);

// Text typed into a search box outside the overlay (the navbar's, or the home
// page's) before the overlay opened, so the overlay can start with it.
let initialQuery = "";

export function useSearchOverlay() {
  function open(query = "") {
    initialQuery = query;
    isOpen.value = true;
  }

  function close() {
    isOpen.value = false;
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
