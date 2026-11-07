import { ref, nextTick } from "vue";

const isOpen = ref(false);

// Text typed into a search box outside the overlay (the navbar's, or the home
// page's) before the overlay opened, so the overlay can start with it.
let initialQuery = "";

// Marks the document while a search view transition runs, so the stylesheet
// can turn off the page crossfade for it (see application.scss).
const SEARCH_TRANSITION_CLASS = "search-view-transition";

interface ViewTransitionLike {
  finished: Promise<void>;
}

let latestTransition: ViewTransitionLike | null = null;

function withViewTransition(callback: () => void): void {
  if ("startViewTransition" in document) {
    const root = document.documentElement;
    root.classList.add(SEARCH_TRANSITION_CLASS);
    const transition = (
      document as { startViewTransition: (cb: () => Promise<void>) => ViewTransitionLike }
    ).startViewTransition(async () => {
      callback();
      await nextTick();
    });
    latestTransition = transition;
    // A newer transition skips this one, so only the newest clears the class.
    void transition.finished.finally(() => {
      if (latestTransition === transition) root.classList.remove(SEARCH_TRANSITION_CLASS);
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
