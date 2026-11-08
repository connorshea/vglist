import { toValue, watch, type MaybeRefOrGetter } from "vue";
import type { RouteLocationNormalized, Router } from "vue-router";

export const SITE_NAME = "vglist";

/** "Hollow Knight" → "Hollow Knight | vglist"; nothing → "vglist". */
export function formatPageTitle(title?: string | null): string {
  const trimmed = title?.trim();
  return trimmed ? `${trimmed} | ${SITE_NAME}` : SITE_NAME;
}

/**
 * Sets each page's title from its route's `meta.title` after navigation, and
 * resets it to the site name on pages without one until the page calls
 * `usePageTitle()` with its data.
 *
 * A navigation that only changes the query or hash keeps the current title, so
 * data-driven titles survive e.g. a sort change on the same page. A page that
 * swaps itself for the 404 page keeps its path but changes route, so that
 * still gets a new title.
 */
export function installPageTitles(router: Router): void {
  router.afterEach((to: RouteLocationNormalized, from: RouteLocationNormalized, failure) => {
    if (failure) {
      return;
    }
    if (from.matched.length > 0 && to.path === from.path && to.name === from.name) {
      return;
    }
    document.title = formatPageTitle(to.meta.title);
  });
}

/**
 * Sets the document title for a data-driven page, e.g.
 * `usePageTitle(() => game.value?.name)`. Until the source has a value (while
 * loading), the title the router set is left alone.
 */
export function usePageTitle(source: MaybeRefOrGetter<string | null | undefined>): void {
  watch(
    () => toValue(source),
    (title) => {
      if (title) {
        document.title = formatPageTitle(title);
      }
    },
    { immediate: true }
  );
}
