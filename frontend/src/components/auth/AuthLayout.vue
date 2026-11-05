<template>
  <div class="auth">
    <div class="auth-art">
      <div class="mosaic" aria-hidden="true">
        <div v-for="tile in tiles" :key="tile.id" class="mosaic-tile" :style="{ background: tile.color }"></div>
      </div>
      <div class="auth-vignette" aria-hidden="true"></div>
      <div class="auth-brand">
        <router-link to="/" class="auth-logo-link">
          <img src="@/assets/images/vglist-logo.svg" alt="vglist home" class="auth-logo" />
        </router-link>
        <p class="auth-tagline">Track your entire video game library across every store and platform.</p>
      </div>
    </div>
    <div class="auth-form">
      <div class="auth-card">
        <slot />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const PALETTE = [
  "#2f4858",
  "#86bbd8",
  "#d1495b",
  "#edae49",
  "#00798c",
  "#30638e",
  "#3a2e39",
  "#8e7dbe",
  "#99c1b9",
  "#f2d0a9",
  "#1e1e24",
  "#92140c",
  "#5c4d7d",
  "#4f6d7a",
  "#c0d6df",
  "#e8a87c"
];

// A fixed, deterministic set of colored tiles. The auth pages don't fetch
// covers, so they render instantly and identically for everyone.
const tiles = Array.from({ length: 108 }, (_, k) => ({
  id: k,
  color: PALETTE[(k * 5 + (k >> 2)) % PALETTE.length]
}));
</script>

<style scoped>
/* Break out of App's .section > .container wrapper to fill the viewport. */
.auth {
  width: 100vw;
  position: relative;
  left: 50%;
  right: 50%;
  margin-left: -50vw;
  margin-right: -50vw;
  margin-top: -3rem;
  margin-bottom: -3rem;
  display: flex;
  flex-wrap: wrap;
  min-height: calc(100vh - 52px);
}

.auth-art {
  flex: 1 1 520px;
  position: relative;
  overflow: hidden;
  background: #110b24;
  display: flex;
  align-items: flex-end;
  padding: 48px;
  color: #fff;
  min-height: 320px;
}

.mosaic {
  position: absolute;
  top: -30%;
  left: -40%;
  width: 160%;
  display: grid;
  grid-template-columns: repeat(18, 110px);
  gap: 10px;
  transform: perspective(410px) rotateX(12deg) rotateZ(-23deg);
  opacity: 0.59;
  pointer-events: none;
}

.mosaic-tile {
  aspect-ratio: 3 / 4;
  border-radius: 5px;
  box-shadow: 0 1px 6px rgba(0, 0, 0, 0.3);
}

.auth-vignette {
  position: absolute;
  inset: 0;
  background: radial-gradient(
    ellipse 75% 60% at 50% 45%,
    rgba(89, 87, 214, 0.4) 0%,
    rgba(45, 28, 110, 0.7) 45%,
    rgba(17, 11, 36, 0.97) 100%
  );
}

.auth-brand {
  position: relative;
  z-index: 2;
  max-width: 420px;
}

.auth-logo-link {
  display: inline-block;
  border-radius: var(--radius-sm);
}

.auth-logo-link:focus-visible {
  outline: 2px solid #fff;
  outline-offset: 4px;
}

.auth-logo {
  height: 48px;
  filter: drop-shadow(0 4px 20px rgba(0, 0, 0, 0.5));
}

.auth-tagline {
  font-size: 20px;
  line-height: 1.4;
  margin: 20px 0 0;
  color: rgba(255, 255, 255, 0.85);
}

.auth-form {
  flex: 1 1 480px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 48px 24px;
}

.auth-card {
  width: 100%;
  max-width: 380px;
}

/* ── Shared form styles for the pages rendered in the slot ── */

.auth-card :slotted(h1) {
  font-size: 28px;
  font-weight: 700;
  line-height: 1.2;
  margin: 0 0 6px;
  color: var(--color-text-primary);
}

.auth-card :slotted(.auth-sub) {
  font-size: 14px;
  color: var(--color-text-secondary);
  margin: 0 0 28px;
}

.auth-card :slotted(.auth-field) {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-bottom: 18px;
}

.auth-card :slotted(.auth-label-row) {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.auth-card :slotted(.auth-field label) {
  font-size: 12px;
  font-weight: 500;
  color: var(--color-text-secondary);
}

.auth-card :slotted(.auth-input) {
  height: 38px;
  width: 100%;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface);
  color: var(--color-text-primary);
  font: inherit;
  font-size: 14px;
  padding: 0 10px;
}

.auth-card :slotted(.auth-input:focus-visible) {
  outline: 2px solid var(--color-accent);
  outline-offset: 1px;
  border-color: var(--color-accent);
}

.auth-card :slotted(.auth-link) {
  color: var(--color-accent);
  font-weight: 500;
}

.auth-card :slotted(.auth-link-small) {
  font-size: 12px;
}

.auth-card :slotted(.auth-submit) {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  margin-top: 6px;
  padding: 11px 20px;
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  color: #fff;
  background: var(--p-500);
  border: 1px solid var(--p-500);
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: opacity var(--transition-fast);
}

.auth-card :slotted(.auth-submit:hover:not(:disabled)) {
  opacity: 0.9;
}

.auth-card :slotted(.auth-submit:focus-visible) {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.auth-card :slotted(.auth-submit:disabled) {
  opacity: 0.6;
  cursor: default;
}

.auth-card :slotted(.auth-footer) {
  margin-top: 24px;
  font-size: 13px;
  color: var(--color-text-secondary);
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.auth-card :slotted(.notification) {
  font-size: 14px;
}

@media (max-width: 768px) {
  .auth {
    margin-top: -3rem;
  }

  .auth-art {
    padding: 32px 24px;
    min-height: 220px;
  }

  .auth-logo {
    height: 40px;
  }

  .auth-tagline {
    font-size: 16px;
  }
}
</style>
