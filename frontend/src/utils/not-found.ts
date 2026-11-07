import type { LocationQuery, RouteLocationRaw } from "vue-router";

interface CurrentLocation {
  path: string;
  query: LocationQuery;
  hash: string;
}

/**
 * The location to `router.replace` with when a page discovers that the thing
 * it shows doesn't exist.
 *
 * Replacing with a bare `{ name: "notFound" }` leaves the catch-all's
 * `pathMatch` param empty, so the address bar is rewritten to `/`: the
 * missing URL is lost and reloading lands on the home page. Passing the
 * current path as `pathMatch` renders the 404 page while keeping the URL.
 */
export function notFoundLocation(route: CurrentLocation): RouteLocationRaw {
  return {
    name: "notFound",
    params: { pathMatch: route.path.substring(1).split("/") },
    query: route.query,
    hash: route.hash
  };
}
