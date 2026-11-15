<template>
  <div v-if="!error && libraryEmpty && ownLibrary" class="library-start" role="status">
    <div class="library-start-art" aria-hidden="true">
      <span class="library-start-slot"></span>
      <span class="library-start-slot"></span>
      <span class="library-start-slot"></span>
      <span class="library-start-slot"></span>
      <span class="library-start-steam"><span class="steam-mark"></span></span>
    </div>
    <p class="library-start-title">Your library is empty</p>
    <p class="library-start-desc">
      Import your Steam library to fill it in one go, or search for games and add them one at a time.
    </p>
    <div class="library-start-actions">
      <router-link :to="{ name: 'settingsImport' }" class="library-start-btn is-primary">
        <span class="steam-mark is-small" aria-hidden="true"></span>
        Import from Steam
      </router-link>
      <button type="button" class="library-start-btn" aria-haspopup="dialog" @click="openSearch()">
        <Search :size="16" aria-hidden="true" />
        Search games
      </button>
    </div>
  </div>
  <div v-else class="library-empty" role="status">
    <template v-if="error">
      <p class="library-empty-title">Couldn't load this library</p>
      <p>{{ error.message }}</p>
    </template>
    <template v-else-if="libraryEmpty">
      <p class="library-empty-title">No games in this library yet</p>
    </template>
    <template v-else>
      <p class="library-empty-title">No games match these filters</p>
      <p>Try a different status, or remove a filter.</p>
    </template>
  </div>
</template>

<script setup lang="ts">
import { Search } from "@lucide/vue";
import { useSearchOverlay } from "@/composables/useSearchOverlay";

withDefaults(
  defineProps<{
    error: Error | null;
    // Whether the whole library is empty, rather than just the filtered view.
    libraryEmpty: boolean;
    // Whether it's the signed-in user's own library. An empty one of their own
    // gets a way to start filling it instead of a bare "no games".
    ownLibrary?: boolean;
  }>(),
  { ownLibrary: false }
);

const { open: openSearch } = useSearchOverlay();
</script>

<style scoped>
.library-empty {
  padding: 48px 16px;
  color: var(--color-text-secondary);
  font-size: 0.875rem;
  text-align: center;
}

.library-empty-title {
  margin-bottom: 4px;
  color: var(--color-text-primary);
  font-size: 1rem;
  font-weight: 600;
}

.library-start {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40px 20px 44px;
  border: 1px dashed var(--color-border);
  border-radius: var(--radius-lg);
  text-align: center;
}

.library-start-art {
  position: relative;
  display: flex;
  gap: 8px;
  margin-bottom: 20px;
}

.library-start-slot {
  width: 52px;
  height: 70px;
  border: 2px dashed var(--color-border);
  border-radius: 6px;
}

.library-start-steam {
  position: absolute;
  top: 50%;
  left: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 48px;
  margin: -24px 0 0 -24px;
  border: 3px solid var(--color-surface);
  border-radius: 50%;
  background: #1b2838;
  color: #fff;
}

.steam-mark {
  width: 24px;
  height: 24px;
  background: currentColor;
  mask: url("../../assets/images/steam-logo.svg") center / contain no-repeat;
}

.steam-mark.is-small {
  width: 16px;
  height: 16px;
}

.library-start-title {
  margin-bottom: 4px;
  color: var(--color-text-primary);
  font-size: 1.125rem;
  font-weight: 700;
}

.library-start-desc {
  max-width: 400px;
  color: var(--color-text-secondary);
  font-size: 0.9375rem;
}

/* One column per button, so both are as wide as the wider one. */
.library-start-actions {
  display: grid;
  grid-auto-columns: 1fr;
  grid-auto-flow: column;
  gap: 10px;
  margin-top: 20px;
}

.library-start-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  min-height: 44px;
  padding: 0 18px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-button);
  background: var(--color-surface);
  color: var(--color-text-primary);
  font: inherit;
  font-weight: 600;
  cursor: pointer;
}

.library-start-btn:hover {
  background: var(--color-bg-subtle);
  color: var(--color-text-primary);
}

.library-start-btn.is-primary {
  border-color: transparent;
  background: var(--p-500);
  color: #fff;
}

.library-start-btn.is-primary:hover {
  background: var(--p-600);
  color: #fff;
}

.library-start-btn:focus-visible {
  outline: 2px solid var(--p-500);
  outline-offset: 2px;
}

@media (max-width: 600px) {
  .library-start-actions {
    grid-auto-flow: row;
    width: 100%;
    max-width: 320px;
  }
}
</style>
