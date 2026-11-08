import { createRouter, createWebHistory } from "vue-router";
import { useAuthStore } from "@/stores/auth";
import { installPageTitles } from "@/composables/usePageTitle";
import { installRouteFocus } from "@/composables/useRouteFocus";
import { useSearchOverlay } from "@/composables/useSearchOverlay";
import { waitForScrollableTo } from "@/utils/scroll-restore";
import { isChunkLoadError, reloadForStaleChunk } from "@/utils/chunk-reload";

const router = createRouter({
  history: createWebHistory(),
  routes: [
    // Public pages
    {
      path: "/",
      name: "home",
      component: () => import("@/pages/HomePage.vue")
    },
    {
      path: "/about",
      name: "about",
      component: () => import("@/pages/AboutPage.vue"),
      meta: { title: "About" }
    },
    // Target of the OpenSearch description (public/opensearch.xml), so
    // browsers can use vglist as a search engine. Opens the search overlay
    // with the query over the home page.
    {
      path: "/search",
      name: "search",
      redirect: (to) => {
        const query = typeof to.query.query === "string" ? to.query.query : "";
        useSearchOverlay().open(query);
        return { name: "home", query: {} };
      }
    },

    // Auth
    {
      path: "/login",
      name: "login",
      component: () => import("@/pages/auth/LoginPage.vue"),
      meta: { title: "Sign in", guestOnly: true, layout: "bare" }
    },
    {
      path: "/signup",
      name: "signup",
      component: () => import("@/pages/auth/SignupPage.vue"),
      meta: { title: "Sign up", guestOnly: true, layout: "bare" }
    },
    {
      path: "/password/reset",
      name: "passwordReset",
      component: () => import("@/pages/auth/PasswordResetPage.vue"),
      meta: { title: "Forgot your password?", guestOnly: true, layout: "bare" }
    },
    {
      path: "/password/reset/confirm",
      name: "passwordResetConfirm",
      component: () => import("@/pages/auth/PasswordResetConfirmPage.vue"),
      meta: { title: "Set a new password", guestOnly: true, layout: "bare" }
    },
    {
      path: "/confirmation/resend",
      name: "confirmationResend",
      component: () => import("@/pages/auth/ConfirmationResendPage.vue"),
      meta: { title: "Resend confirmation email", guestOnly: true, layout: "bare" }
    },

    // Games
    {
      path: "/games",
      name: "games",
      component: () => import("@/pages/games/GamesIndexPage.vue"),
      meta: { title: "Games" }
    },
    {
      path: "/games/new",
      name: "gameNew",
      component: () => import("@/pages/games/GameFormPage.vue"),
      meta: { title: "Create a new game", requiresAuth: true, requiresModerator: true }
    },
    {
      path: "/games/:id",
      name: "game",
      component: () => import("@/pages/games/GameShowPage.vue")
    },
    {
      path: "/games/:id/edit",
      name: "gameEdit",
      component: () => import("@/pages/games/GameFormPage.vue"),
      meta: { requiresAuth: true, requiresModerator: true }
    },

    // Users
    {
      path: "/users",
      name: "users",
      component: () => import("@/pages/users/UserListPage.vue"),
      meta: { title: "Users" }
    },
    // Comparing two users' libraries. `/users/:slug/compare` compares the
    // signed-in user with that user, so the profile's button can link to it.
    {
      path: "/users/:slug/compare/:otherSlug",
      name: "userCompare",
      component: () => import("@/pages/users/UserComparePage.vue")
    },
    {
      path: "/users/:slug/compare",
      name: "userCompareWithMe",
      redirect: (to) => {
        const authStore = useAuthStore();
        const slug = "slug" in to.params ? to.params.slug : "";
        const viewer = authStore.isAuthenticated ? authStore.user : null;
        if (!viewer || viewer.slug === slug) {
          return { name: "user", params: { slug } };
        }
        return { name: "userCompare", params: { slug: viewer.slug, otherSlug: slug } };
      }
    },
    // A user's profile: one header and tab bar, with each tab a child route.
    {
      path: "/users/:slug",
      component: () => import("@/pages/users/UserProfileLayout.vue"),
      children: [
        {
          path: "",
          name: "user",
          component: () => import("@/pages/users/UserOverviewPage.vue")
        },
        {
          path: "library",
          name: "userLibrary",
          component: () => import("@/pages/users/UserLibraryPage.vue")
        },
        {
          path: "favorites",
          name: "userFavorites",
          component: () => import("@/pages/users/UserFavoritesPage.vue")
        },
        {
          path: "activity",
          name: "userActivity",
          component: () => import("@/pages/users/UserActivityPage.vue")
        },
        {
          path: "followers",
          name: "userFollowers",
          component: () => import("@/pages/users/UserFollowersPage.vue")
        },
        {
          path: "following",
          name: "userFollowing",
          component: () => import("@/pages/users/UserFollowingPage.vue")
        }
      ]
    },

    // Platforms
    {
      path: "/platforms",
      name: "platforms",
      component: () => import("@/pages/platforms/PlatformListPage.vue"),
      meta: { title: "Platforms" }
    },
    {
      path: "/platforms/new",
      name: "platformNew",
      component: () => import("@/pages/platforms/PlatformFormPage.vue"),
      meta: { title: "Create a new platform", requiresAuth: true, requiresModerator: true }
    },
    {
      path: "/platforms/:id",
      name: "platform",
      component: () => import("@/pages/platforms/PlatformShowPage.vue")
    },
    {
      path: "/platforms/:id/edit",
      name: "platformEdit",
      component: () => import("@/pages/platforms/PlatformFormPage.vue"),
      meta: { requiresAuth: true, requiresModerator: true }
    },

    // Companies
    {
      path: "/companies",
      name: "companies",
      component: () => import("@/pages/companies/CompanyListPage.vue"),
      meta: { title: "Companies" }
    },
    {
      path: "/companies/new",
      name: "companyNew",
      component: () => import("@/pages/companies/CompanyFormPage.vue"),
      meta: { title: "Create a new company", requiresAuth: true, requiresModerator: true }
    },
    {
      path: "/companies/:id",
      name: "company",
      component: () => import("@/pages/companies/CompanyShowPage.vue")
    },
    {
      path: "/companies/:id/edit",
      name: "companyEdit",
      component: () => import("@/pages/companies/CompanyFormPage.vue"),
      meta: { requiresAuth: true, requiresModerator: true }
    },

    // Engines
    {
      path: "/engines",
      name: "engines",
      component: () => import("@/pages/engines/EngineListPage.vue"),
      meta: { title: "Engines" }
    },
    {
      path: "/engines/new",
      name: "engineNew",
      component: () => import("@/pages/engines/EngineFormPage.vue"),
      meta: { title: "Create a new engine", requiresAuth: true, requiresModerator: true }
    },
    {
      path: "/engines/:id",
      name: "engine",
      component: () => import("@/pages/engines/EngineShowPage.vue")
    },
    {
      path: "/engines/:id/edit",
      name: "engineEdit",
      component: () => import("@/pages/engines/EngineFormPage.vue"),
      meta: { requiresAuth: true, requiresModerator: true }
    },

    // Genres
    {
      path: "/genres",
      name: "genres",
      component: () => import("@/pages/genres/GenreListPage.vue"),
      meta: { title: "Genres" }
    },
    {
      path: "/genres/new",
      name: "genreNew",
      component: () => import("@/pages/genres/GenreFormPage.vue"),
      meta: { title: "Create a new genre", requiresAuth: true, requiresModerator: true }
    },
    {
      path: "/genres/:id",
      name: "genre",
      component: () => import("@/pages/genres/GenreShowPage.vue")
    },
    {
      path: "/genres/:id/edit",
      name: "genreEdit",
      component: () => import("@/pages/genres/GenreFormPage.vue"),
      meta: { requiresAuth: true, requiresModerator: true }
    },

    // Series
    {
      path: "/series",
      name: "seriesList",
      component: () => import("@/pages/series/SeriesListPage.vue"),
      meta: { title: "Series" }
    },
    {
      path: "/series/new",
      name: "seriesNew",
      component: () => import("@/pages/series/SeriesFormPage.vue"),
      meta: { title: "Create a new series", requiresAuth: true, requiresModerator: true }
    },
    {
      path: "/series/:id",
      name: "series",
      component: () => import("@/pages/series/SeriesShowPage.vue")
    },
    {
      path: "/series/:id/edit",
      name: "seriesEdit",
      component: () => import("@/pages/series/SeriesFormPage.vue"),
      meta: { requiresAuth: true, requiresModerator: true }
    },

    // Stores
    {
      path: "/stores",
      name: "stores",
      component: () => import("@/pages/stores/StoreListPage.vue"),
      meta: { title: "Stores" }
    },
    {
      path: "/stores/new",
      name: "storeNew",
      component: () => import("@/pages/stores/StoreFormPage.vue"),
      meta: { title: "Create a new store", requiresAuth: true, requiresModerator: true }
    },
    // Stores have no page of their own; send old links to the list.
    {
      path: "/stores/:id",
      // A plain path, so the :id param isn't carried over to /stores (which
      // has none) and logged as discarded.
      redirect: "/stores"
    },
    {
      path: "/stores/:id/edit",
      name: "storeEdit",
      component: () => import("@/pages/stores/StoreFormPage.vue"),
      meta: { requiresAuth: true, requiresModerator: true }
    },

    // Activity
    {
      path: "/activity",
      name: "activity",
      component: () => import("@/pages/activity/ActivityPage.vue"),
      meta: { title: "Activity" }
    },

    // Settings
    {
      path: "/settings",
      name: "settings",
      component: () => import("@/pages/settings/SettingsPage.vue"),
      meta: { requiresAuth: true },
      redirect: { name: "settingsProfile" },
      children: [
        {
          path: "profile",
          name: "settingsProfile",
          component: () => import("@/pages/settings/ProfileSettings.vue"),
          meta: { title: "Profile Settings" }
        },
        {
          path: "account",
          name: "settingsAccount",
          component: () => import("@/pages/settings/AccountSettings.vue"),
          meta: { title: "Account Settings" }
        },
        {
          path: "import",
          name: "settingsImport",
          component: () => import("@/pages/settings/ImportSettings.vue"),
          meta: { title: "Import Settings" }
        },
        {
          path: "export",
          name: "settingsExport",
          component: () => import("@/pages/settings/ExportSettings.vue"),
          meta: { title: "Export Library" }
        }
      ]
    },

    // Admin
    {
      path: "/admin",
      component: () => import("@/pages/admin/AdminPage.vue"),
      meta: { requiresAuth: true, requiresAdmin: true },
      children: [
        {
          path: "",
          name: "admin",
          component: () => import("@/pages/admin/AdminDashboardPage.vue"),
          meta: { title: "Admin Dashboard" }
        },
        {
          path: "wikidata-blocklist",
          name: "adminWikidataBlocklist",
          component: () => import("@/pages/admin/AdminWikidataBlocklistPage.vue"),
          meta: { title: "Wikidata Blocklist" }
        },
        {
          path: "steam-blocklist",
          name: "adminSteamBlocklist",
          component: () => import("@/pages/admin/AdminSteamBlocklistPage.vue"),
          meta: { title: "Steam Blocklist" }
        },
        {
          path: "unmatched-games",
          name: "adminUnmatchedGames",
          component: () => import("@/pages/admin/AdminUnmatchedGamesPage.vue"),
          meta: { title: "Unmatched Games" }
        }
      ]
    },

    // Catch-all 404
    {
      path: "/:pathMatch(.*)*",
      name: "notFound",
      component: () => import("@/pages/NotFoundPage.vue"),
      meta: { title: "Page not found" }
    }
  ],
  scrollBehavior(_to, _from, savedPosition) {
    if (savedPosition) {
      // Back/Forward: wait for the page to load enough to reach the old
      // position, rather than clamping it against a short loading skeleton.
      return waitForScrollableTo(savedPosition.top).then(() => savedPosition);
    }
    return { top: 0 };
  }
});

// Navigation guards
router.beforeEach((to) => {
  const authStore = useAuthStore();

  if (to.matched.some((r) => r.meta.requiresAuth) && !authStore.isAuthenticated) {
    return { name: "login", query: { redirect: to.fullPath } };
  }

  if (to.matched.some((r) => r.meta.requiresModerator) && !authStore.isModerator) {
    return { name: "home" };
  }

  if (to.matched.some((r) => r.meta.requiresAdmin) && !authStore.isAdmin) {
    return { name: "home" };
  }

  if (to.meta.guestOnly && authStore.isAuthenticated) {
    return { name: "home" };
  }
});

// A link to a page whose chunk is gone after a deploy would otherwise do
// nothing. See utils/chunk-reload.ts.
router.onError((error, to) => {
  if (isChunkLoadError(error)) {
    reloadForStaleChunk(to.fullPath);
  }
});

installPageTitles(router);
installRouteFocus(router);

export default router;
