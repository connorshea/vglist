import { readonly, ref, type Ref } from "vue";

/**
 * The bits of the Network Information API we use. It isn't in TypeScript's
 * DOM lib because only Chromium-based browsers ship it.
 */
interface NetworkInformation extends EventTarget {
  readonly saveData?: boolean;
}

const REDUCED_DATA_QUERY = "(prefers-reduced-data: reduce)";

function connection(): NetworkInformation | undefined {
  if (typeof navigator === "undefined") {
    return undefined;
  }
  return (navigator as Navigator & { connection?: NetworkInformation }).connection;
}

function reducedDataQuery(): MediaQueryList | undefined {
  if (typeof window === "undefined" || typeof window.matchMedia !== "function") {
    return undefined;
  }
  return window.matchMedia(REDUCED_DATA_QUERY);
}

/**
 * Whether the browser says the user wants to use less data, from either:
 *
 * - `navigator.connection.saveData`: the "Data Saver" / "Lite mode" setting
 *   in Chromium-based browsers (Chrome on Android, Edge, Opera, Samsung
 *   Internet). The same setting sends a `Save-Data: on` request header.
 * - the `prefers-reduced-data: reduce` media query, which no browser ships by
 *   default yet but is the standard way to ask for this going forward.
 */
export function detectSaveData(): boolean {
  return connection()?.saveData === true || reducedDataQuery()?.matches === true;
}

let state: Ref<boolean> | null = null;

/**
 * A shared, reactive flag for "the user asked to save data". Decorative
 * images (like the cover collages) should be skipped while it's true.
 * It updates if the user toggles the setting while the page is open.
 */
export function useSaveData(): Readonly<Ref<boolean>> {
  if (!state) {
    const saveData = ref(detectSaveData());
    const update = () => {
      saveData.value = detectSaveData();
    };
    connection()?.addEventListener("change", update);
    reducedDataQuery()?.addEventListener("change", update);
    state = saveData;
  }
  return readonly(state);
}

/** Test helper: forget the shared state so the next call re-detects. */
export function resetSaveDataForTests(): void {
  state = null;
}
