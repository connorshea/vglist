import { onBeforeUnmount, onMounted, readonly, ref, type Ref } from "vue";

// How far outside the viewport an element counts as near, so its image is
// usually there by the time it scrolls into view.
const ROOT_MARGIN = "300px 0px";

// How long an element has to stay near the viewport before it counts. A fast
// scroll carries hundreds of tiles past in a second or two; without the wait
// each of them would start a download that the tiles the scroll stops on then
// queue behind.
export const NEAR_VIEWPORT_DWELL_MS = 150;

type Listener = (near: boolean) => void;

// One observer for every element, rather than one per tile.
let observer: IntersectionObserver | null = null;
const listeners = new Map<Element, Listener>();

function sharedObserver(): IntersectionObserver {
  if (!observer) {
    observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          listeners.get(entry.target)?.(entry.isIntersecting);
        }
      },
      { rootMargin: ROOT_MARGIN }
    );
  }
  return observer;
}

/**
 * Whether `target` has settled near the viewport: it turns true once the
 * element has stayed within {@link ROOT_MARGIN} of the viewport for
 * {@link NEAR_VIEWPORT_DWELL_MS}, and false as soon as it leaves. An element
 * that is already near the viewport when it mounts counts straight away,
 * since nothing is scrolling past it yet.
 *
 * `target` is read once, on mount, so it must point at an element that is
 * always rendered (not one behind a `v-if`).
 *
 * Always true when `enabled` is false, and without IntersectionObserver (old
 * browsers, jsdom).
 */
export function useNearViewport(target: Ref<Element | null>, enabled = true): Readonly<Ref<boolean>> {
  const supported = typeof IntersectionObserver !== "undefined";
  const near = ref(!enabled || !supported);
  if (near.value) {
    return readonly(near);
  }

  let timer: ReturnType<typeof setTimeout> | undefined;
  let observed: Element | null = null;
  let firstEntry = true;

  function onChange(intersecting: boolean) {
    clearTimeout(timer);
    if (intersecting && firstEntry) {
      near.value = true;
    } else if (intersecting) {
      timer = setTimeout(() => (near.value = true), NEAR_VIEWPORT_DWELL_MS);
    } else {
      near.value = false;
    }
    firstEntry = false;
  }

  onMounted(() => {
    observed = target.value;
    if (observed) {
      listeners.set(observed, onChange);
      sharedObserver().observe(observed);
    }
  });

  onBeforeUnmount(() => {
    clearTimeout(timer);
    if (observed) {
      listeners.delete(observed);
      observer?.unobserve(observed);
    }
  });

  return readonly(near);
}
