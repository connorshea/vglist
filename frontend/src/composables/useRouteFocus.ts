import { nextTick } from "vue";
import type { RouteLocationNormalized, Router } from "vue-router";

export const MAIN_CONTENT_ID = "main-content";

/**
 * Moves keyboard/screen-reader focus to the page's `<main>` landmark. It has
 * `tabindex="-1"`, so it takes focus programmatically without joining the Tab
 * order. Scrolling is left to the router's `scrollBehavior`.
 */
export function focusMainContent(): void {
  document.getElementById(MAIN_CONTENT_ID)?.focus({ preventScroll: true });
}

/**
 * After a client-side navigation to a new page, moves focus to `<main>`, the
 * way a full page load would reset it. Without this, focus stays on the link
 * that was activated (or falls to `<body>` once it unmounts), and screen
 * readers don't notice the page changed.
 *
 * Left alone: the initial load, failed navigations, and navigations that only
 * change the query or hash (sorting and filtering a list mustn't pull focus
 * away from the control being used).
 */
export function installRouteFocus(router: Router): void {
  router.afterEach((to: RouteLocationNormalized, from: RouteLocationNormalized, failure) => {
    if (failure) return;
    if (from.matched.length === 0) return;
    if (to.path === from.path) return;
    void nextTick(focusMainContent);
  });
}
