import type { RouteRecordInfo } from "vue-router";

declare module "vue-router" {
  interface TypesConfig {
    RouteNamedMap: {
      // Public
      home: RouteRecordInfo<"home", "/", Record<never, never>, Record<never, never>>;
      about: RouteRecordInfo<"about", "/about", Record<never, never>, Record<never, never>>;

      // Auth
      login: RouteRecordInfo<"login", "/login", Record<never, never>, Record<never, never>>;
      signup: RouteRecordInfo<"signup", "/signup", Record<never, never>, Record<never, never>>;
      passwordReset: RouteRecordInfo<"passwordReset", "/password/reset", Record<never, never>, Record<never, never>>;

      // Games
      games: RouteRecordInfo<"games", "/games", Record<never, never>, Record<never, never>>;
      gameNew: RouteRecordInfo<"gameNew", "/games/new", Record<never, never>, Record<never, never>>;
      game: RouteRecordInfo<"game", "/games/:id", { id: string | number }, { id: string }>;
      gameEdit: RouteRecordInfo<"gameEdit", "/games/:id/edit", { id: string | number }, { id: string }>;

      // Users
      users: RouteRecordInfo<"users", "/users", Record<never, never>, Record<never, never>>;
      user: RouteRecordInfo<"user", "/users/:slug", { slug: string }, { slug: string }>;
      userFavorites: RouteRecordInfo<"userFavorites", "/users/:slug/favorites", { slug: string }, { slug: string }>;
      userFollowing: RouteRecordInfo<"userFollowing", "/users/:slug/following", { slug: string }, { slug: string }>;
      userFollowers: RouteRecordInfo<"userFollowers", "/users/:slug/followers", { slug: string }, { slug: string }>;
      userActivity: RouteRecordInfo<"userActivity", "/users/:slug/activity", { slug: string }, { slug: string }>;

      // Platforms
      platforms: RouteRecordInfo<"platforms", "/platforms", Record<never, never>, Record<never, never>>;
      platform: RouteRecordInfo<"platform", "/platforms/:id", { id: string | number }, { id: string }>;

      // Companies
      companies: RouteRecordInfo<"companies", "/companies", Record<never, never>, Record<never, never>>;
      company: RouteRecordInfo<"company", "/companies/:id", { id: string | number }, { id: string }>;

      // Engines
      engines: RouteRecordInfo<"engines", "/engines", Record<never, never>, Record<never, never>>;
      engine: RouteRecordInfo<"engine", "/engines/:id", { id: string | number }, { id: string }>;

      // Genres
      genres: RouteRecordInfo<"genres", "/genres", Record<never, never>, Record<never, never>>;
      genre: RouteRecordInfo<"genre", "/genres/:id", { id: string | number }, { id: string }>;

      // Series
      seriesList: RouteRecordInfo<"seriesList", "/series", Record<never, never>, Record<never, never>>;
      series: RouteRecordInfo<"series", "/series/:id", { id: string | number }, { id: string }>;

      // Stores
      stores: RouteRecordInfo<"stores", "/stores", Record<never, never>, Record<never, never>>;
      store: RouteRecordInfo<"store", "/stores/:id", { id: string | number }, { id: string }>;

      // Activity
      activity: RouteRecordInfo<"activity", "/activity", Record<never, never>, Record<never, never>>;

      // Settings
      settings: RouteRecordInfo<"settings", "/settings", Record<never, never>, Record<never, never>>;
      settingsProfile: RouteRecordInfo<
        "settingsProfile",
        "/settings/profile",
        Record<never, never>,
        Record<never, never>,
        "settings"
      >;
      settingsAccount: RouteRecordInfo<
        "settingsAccount",
        "/settings/account",
        Record<never, never>,
        Record<never, never>,
        "settings"
      >;
      settingsImport: RouteRecordInfo<
        "settingsImport",
        "/settings/import",
        Record<never, never>,
        Record<never, never>,
        "settings"
      >;
      settingsExport: RouteRecordInfo<
        "settingsExport",
        "/settings/export",
        Record<never, never>,
        Record<never, never>,
        "settings"
      >;
      settingsApiToken: RouteRecordInfo<
        "settingsApiToken",
        "/settings/api-token",
        Record<never, never>,
        Record<never, never>,
        "settings"
      >;

      // Admin
      admin: RouteRecordInfo<"admin", "/admin", Record<never, never>, Record<never, never>>;

      // Catch-all
      notFound: RouteRecordInfo<"notFound", "/:pathMatch(.*)*", { pathMatch: string[] }, { pathMatch: string[] }>;
    };
  }
}
