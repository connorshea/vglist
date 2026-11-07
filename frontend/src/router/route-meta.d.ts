import "vue-router";

export {};

declare module "vue-router" {
  interface RouteMeta {
    /** Redirect to the login page when the visitor isn't signed in. */
    requiresAuth?: boolean;
    /** Redirect home unless the signed-in user is a moderator (or admin). */
    requiresModerator?: boolean;
    /** Redirect home unless the signed-in user is an admin. */
    requiresAdmin?: boolean;
    /** Redirect home when the visitor is already signed in. */
    guestOnly?: boolean;
    /**
     * Which app shell to render around the page.
     *
     * - `"default"` (or unset): the global navbar, with the page inside
     *   `main.section > .container`.
     * - `"bare"`: no navbar and no section/container wrapper. The page fills
     *   the viewport and is responsible for its own layout and for giving
     *   keyboard users a way home.
     */
    layout?: "default" | "bare";
  }
}
