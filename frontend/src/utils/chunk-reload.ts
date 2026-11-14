import { safeSessionStorage } from "@/utils/safe-storage";

// A deploy replaces every hashed file in /assets/, so a tab opened before
// the deploy still references chunk names that no longer exist. Clicking a
// link then makes the router import a missing chunk, the import rejects, and
// Vue Router aborts the navigation: the URL and the page stay put. The fix is
// a full page load of the destination, which fetches the new index.html and
// the new chunk names.

// Each browser words the failed dynamic import differently.
const CHUNK_ERROR_PATTERNS = [
  /Failed to fetch dynamically imported module/i, // Chromium
  /error loading dynamically imported module/i, // Firefox
  /Importing a module script failed/i, // Safari
  /Unable to preload CSS/i, // Vite's CSS preload helper
  /Failed to load module script/i
];

export function isChunkLoadError(error: unknown): boolean {
  const message = error instanceof Error ? error.message : typeof error === "string" ? error : "";
  return CHUNK_ERROR_PATTERNS.some((pattern) => pattern.test(message));
}

const STORAGE_KEY = "vglist:chunk-reload-at";
// If a reload didn't fix it (e.g. the new build is still rolling out),
// don't keep reloading in a loop.
const RELOAD_COOLDOWN_MS = 10_000;

/**
 * Does a full page load of `path`, unless one was already done in the last
 * few seconds. Returns whether it reloaded.
 */
export function reloadForStaleChunk(path: string, now: number = Date.now()): boolean {
  // When storage is blocked this falls back to memory, which a reload
  // forgets: a loop is unlikely, and a dead link is worse.
  const last = Number(safeSessionStorage.getItem(STORAGE_KEY));
  if (last && now - last < RELOAD_COOLDOWN_MS) {
    return false;
  }
  safeSessionStorage.setItem(STORAGE_KEY, String(now));
  window.location.assign(path);
  return true;
}
