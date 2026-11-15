<template>
  <aside v-if="visible" class="steam-banner" aria-labelledby="steam-banner-title">
    <span class="steam-banner-logo" aria-hidden="true"><span class="steam-banner-logo-mark"></span></span>
    <div class="steam-banner-text">
      <p id="steam-banner-title" class="steam-banner-title">Get your library started</p>
      <p>Import the games you own on Steam, along with your hours played. You can add anything else by hand later.</p>
    </div>
    <router-link :to="{ name: 'settingsImport' }" class="steam-banner-btn">Import from Steam</router-link>
    <button type="button" class="steam-banner-close" aria-label="Dismiss" @click="dismiss">
      <X :size="18" aria-hidden="true" />
    </button>
  </aside>
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { X } from "@lucide/vue";
import { useQuery } from "@/composables/useGraphQL";
import { GET_STEAM_IMPORT_PROMPT } from "@/graphql/queries/users";
import { useAuthStore } from "@/stores/auth";
import type { GetSteamImportPromptQuery } from "@/types/graphql";
import { safeLocalStorage } from "@/utils/safe-storage";

// Suggests importing from Steam to a signed-in user whose library is still
// empty and who hasn't connected Steam, which in practice means someone who
// has only just signed up. Importing (or adding any game) hides it for good;
// dismissing it hides it in this browser.

const DISMISSED_KEY_PREFIX = "vglist-steam-import-banner-dismissed-";

const authStore = useAuthStore();

const dismissedKey = computed(() => (authStore.user ? `${DISMISSED_KEY_PREFIX}${authStore.user.id}` : null));
const dismissed = ref(false);
watch(
  dismissedKey,
  (key) => {
    dismissed.value = key !== null && safeLocalStorage.getItem(key) !== null;
  },
  { immediate: true }
);

// No stale-while-revalidate: a cached "library is empty" from before an import
// would flash the banner on the way back to the home page.
const { data } = useQuery<GetSteamImportPromptQuery>(GET_STEAM_IMPORT_PROMPT, {
  enabled: () => authStore.isAuthenticated && !dismissed.value,
  cache: false
});

const visible = computed(() => {
  const user = data.value?.currentUser;
  return (
    authStore.isAuthenticated &&
    !dismissed.value &&
    user != null &&
    user.steamProfileUrl == null &&
    user.gamePurchases.totalCount === 0
  );
});

function dismiss() {
  if (dismissedKey.value) {
    safeLocalStorage.setItem(dismissedKey.value, new Date().toISOString());
  }
  dismissed.value = true;
}
</script>

<style scoped>
.steam-banner {
  position: relative;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 16px;
  padding: 18px 56px 18px 24px;
  border-radius: var(--radius-lg);
  background: var(--p-50);
  color: var(--color-text-primary);
}

.steam-banner-logo {
  display: flex;
  flex-shrink: 0;
  align-items: center;
  justify-content: center;
  width: 44px;
  height: 44px;
  border-radius: 10px;
  background: #1b2838;
  color: #fff;
}

.steam-banner-logo-mark {
  width: 24px;
  height: 24px;
  background: currentColor;
  mask: url("../../assets/images/steam-logo.svg") center / contain no-repeat;
}

.steam-banner-text {
  flex: 1;
  min-width: 240px;
  color: var(--color-text-secondary);
  font-size: 0.9375rem;
  line-height: 1.45;
}

.steam-banner-title {
  color: var(--color-text-primary);
  font-size: 1rem;
  font-weight: 700;
}

.steam-banner-btn {
  display: inline-flex;
  align-items: center;
  min-height: 44px;
  padding: 0 22px;
  border-radius: var(--radius-button);
  background: var(--p-500);
  color: #fff;
  font-weight: 600;
  white-space: nowrap;
}

.steam-banner-btn:hover {
  background: var(--p-600);
  color: #fff;
}

.steam-banner-close {
  position: absolute;
  top: 10px;
  right: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border: 0;
  border-radius: 8px;
  background: transparent;
  color: var(--color-text-secondary);
  cursor: pointer;
}

.steam-banner-close:hover {
  background: var(--p-100);
  color: var(--color-text-primary);
}

.steam-banner-btn:focus-visible,
.steam-banner-close:focus-visible {
  outline: 2px solid var(--p-500);
  outline-offset: 2px;
}

@media (prefers-color-scheme: dark) {
  .steam-banner {
    background: var(--p-800);
  }

  .steam-banner-text {
    color: var(--p-100);
  }

  .steam-banner-close {
    color: var(--p-200);
  }

  .steam-banner-close:hover {
    background: var(--p-700);
    color: #fff;
  }
}

@media (max-width: 600px) {
  .steam-banner {
    align-items: flex-start;
    padding: 16px;
  }

  .steam-banner-text {
    flex-basis: calc(100% - 60px);
    min-width: 0;
    padding-right: 28px;
  }

  .steam-banner-btn {
    width: 100%;
    justify-content: center;
  }
}
</style>
