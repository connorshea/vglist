import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    // Public pages
    {
      path: '/',
      name: 'home',
      component: () => import('@/pages/HomePage.vue'),
    },
    {
      path: '/about',
      name: 'about',
      component: () => import('@/pages/AboutPage.vue'),
    },

    // Auth
    {
      path: '/login',
      name: 'login',
      component: () => import('@/pages/auth/LoginPage.vue'),
      meta: { guestOnly: true },
    },
    {
      path: '/signup',
      name: 'signup',
      component: () => import('@/pages/auth/SignupPage.vue'),
      meta: { guestOnly: true },
    },
    {
      path: '/password/reset',
      name: 'passwordReset',
      component: () => import('@/pages/auth/PasswordResetPage.vue'),
      meta: { guestOnly: true },
    },

    // Games
    {
      path: '/games',
      name: 'games',
      component: () => import('@/pages/games/GameListPage.vue'),
    },
    {
      path: '/games/new',
      name: 'gameNew',
      component: () => import('@/pages/games/GameFormPage.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/games/:id',
      name: 'game',
      component: () => import('@/pages/games/GameShowPage.vue'),
    },
    {
      path: '/games/:id/edit',
      name: 'gameEdit',
      component: () => import('@/pages/games/GameFormPage.vue'),
      meta: { requiresAuth: true },
    },

    // Users
    {
      path: '/users',
      name: 'users',
      component: () => import('@/pages/users/UserListPage.vue'),
    },
    {
      path: '/users/:id',
      name: 'user',
      component: () => import('@/pages/users/UserShowPage.vue'),
    },
    {
      path: '/users/:id/favorites',
      name: 'userFavorites',
      component: () => import('@/pages/users/UserFavoritesPage.vue'),
    },
    {
      path: '/users/:id/following',
      name: 'userFollowing',
      component: () => import('@/pages/users/UserFollowingPage.vue'),
    },
    {
      path: '/users/:id/followers',
      name: 'userFollowers',
      component: () => import('@/pages/users/UserFollowersPage.vue'),
    },
    {
      path: '/users/:id/activity',
      name: 'userActivity',
      component: () => import('@/pages/users/UserActivityPage.vue'),
    },

    // Platforms
    {
      path: '/platforms',
      name: 'platforms',
      component: () => import('@/pages/platforms/PlatformListPage.vue'),
    },
    {
      path: '/platforms/:id',
      name: 'platform',
      component: () => import('@/pages/platforms/PlatformShowPage.vue'),
    },

    // Companies
    {
      path: '/companies',
      name: 'companies',
      component: () => import('@/pages/companies/CompanyListPage.vue'),
    },
    {
      path: '/companies/:id',
      name: 'company',
      component: () => import('@/pages/companies/CompanyShowPage.vue'),
    },

    // Engines
    {
      path: '/engines',
      name: 'engines',
      component: () => import('@/pages/engines/EngineListPage.vue'),
    },
    {
      path: '/engines/:id',
      name: 'engine',
      component: () => import('@/pages/engines/EngineShowPage.vue'),
    },

    // Genres
    {
      path: '/genres',
      name: 'genres',
      component: () => import('@/pages/genres/GenreListPage.vue'),
    },
    {
      path: '/genres/:id',
      name: 'genre',
      component: () => import('@/pages/genres/GenreShowPage.vue'),
    },

    // Series
    {
      path: '/series',
      name: 'seriesList',
      component: () => import('@/pages/series/SeriesListPage.vue'),
    },
    {
      path: '/series/:id',
      name: 'series',
      component: () => import('@/pages/series/SeriesShowPage.vue'),
    },

    // Stores
    {
      path: '/stores',
      name: 'stores',
      component: () => import('@/pages/stores/StoreListPage.vue'),
    },
    {
      path: '/stores/:id',
      name: 'store',
      component: () => import('@/pages/stores/StoreShowPage.vue'),
    },

    // Activity
    {
      path: '/activity',
      name: 'activity',
      component: () => import('@/pages/activity/ActivityPage.vue'),
    },

    // Search
    {
      path: '/search',
      name: 'search',
      component: () => import('@/pages/SearchPage.vue'),
    },

    // Settings
    {
      path: '/settings',
      name: 'settings',
      component: () => import('@/pages/settings/SettingsPage.vue'),
      meta: { requiresAuth: true },
      redirect: { name: 'settingsProfile' },
      children: [
        {
          path: 'profile',
          name: 'settingsProfile',
          component: () => import('@/pages/settings/ProfileSettings.vue'),
        },
        {
          path: 'account',
          name: 'settingsAccount',
          component: () => import('@/pages/settings/AccountSettings.vue'),
        },
        {
          path: 'import',
          name: 'settingsImport',
          component: () => import('@/pages/settings/ImportSettings.vue'),
        },
        {
          path: 'export',
          name: 'settingsExport',
          component: () => import('@/pages/settings/ExportSettings.vue'),
        },
        {
          path: 'api-token',
          name: 'settingsApiToken',
          component: () => import('@/pages/settings/ApiTokenSettings.vue'),
        },
      ],
    },

    // Admin
    {
      path: '/admin',
      name: 'admin',
      component: () => import('@/pages/admin/AdminDashboardPage.vue'),
      meta: { requiresAuth: true, requiresAdmin: true },
    },

    // Catch-all 404
    {
      path: '/:pathMatch(.*)*',
      name: 'notFound',
      component: () => import('@/pages/NotFoundPage.vue'),
    },
  ],
  scrollBehavior(_to, _from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    }
    return { top: 0 }
  },
})

// Navigation guards
router.beforeEach((to) => {
  const authStore = useAuthStore()

  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }

  if (to.meta.requiresAdmin && !authStore.isAdmin) {
    return { name: 'home' }
  }

  if (to.meta.guestOnly && authStore.isAuthenticated) {
    return { name: 'home' }
  }
})

export default router
