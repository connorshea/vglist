import { readonly, ref, type Ref } from "vue";

const REDUCED_MOTION_QUERY = "(prefers-reduced-motion: reduce)";

function reducedMotionQuery(): MediaQueryList | undefined {
  if (typeof window === "undefined" || typeof window.matchMedia !== "function") {
    return undefined;
  }
  return window.matchMedia(REDUCED_MOTION_QUERY);
}

let state: Ref<boolean> | null = null;

/**
 * A shared, reactive flag for the OS-level "reduce motion" setting. CSS can
 * use the media query directly; this is for motion driven from script, like
 * timers that start animations. It updates if the user changes the setting
 * while the page is open.
 */
export function useReducedMotion(): Readonly<Ref<boolean>> {
  if (!state) {
    const query = reducedMotionQuery();
    const reduced = ref(query?.matches === true);
    query?.addEventListener("change", (event) => {
      reduced.value = event.matches;
    });
    state = reduced;
  }
  return readonly(state);
}

/** Test helper: forget the shared state so the next call re-detects. */
export function resetReducedMotionForTests(): void {
  state = null;
}
