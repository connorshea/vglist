<template>
  <div class="settings-page">
    <h1 class="settings-heading">Settings</h1>
    <div class="settings-split">
      <nav class="settings-nav" aria-label="Settings sections">
        <router-link v-for="section in sections" :key="section.name" :to="{ name: section.name }">
          <component :is="section.icon" :size="18" :stroke-width="1.8" aria-hidden="true" />
          {{ section.label }}
        </router-link>
      </nav>
      <div class="settings-main">
        <router-view />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { Download, Mail, Upload, User } from "@lucide/vue";

const sections = [
  { name: "settingsProfile", label: "Profile", icon: User },
  { name: "settingsAccount", label: "Account", icon: Mail },
  { name: "settingsImport", label: "Import", icon: Upload },
  { name: "settingsExport", label: "Export", icon: Download }
] as const;
</script>

<style scoped>
.settings-heading {
  font-size: 24px;
  font-weight: 600;
  letter-spacing: -0.3px;
  color: var(--color-text-primary);
  margin: 0;
}

.settings-split {
  display: flex;
  flex-wrap: wrap;
  gap: 32px;
  align-items: flex-start;
  padding: 24px 0 64px;
}

.settings-nav {
  flex: 1 1 200px;
  max-width: 220px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.settings-nav a {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 9px 12px;
  border-radius: var(--radius-md);
  font-size: 14px;
  color: var(--color-text-secondary);
}

.settings-nav a:hover {
  background: var(--color-bg-subtle);
  color: var(--color-text-primary);
}

.settings-nav a:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.settings-nav a.router-link-active {
  background: var(--p-100);
  color: var(--p-700);
  font-weight: 500;
}

.settings-main {
  flex: 999 1 560px;
  min-width: 0;
  max-width: 720px;
}

/* On narrow screens the rail sits above the content as a row of four tabs. */
@media (max-width: 768px) {
  .settings-split {
    gap: 16px;
    padding-top: 16px;
  }

  .settings-nav {
    flex-basis: 100%;
    max-width: none;
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 4px;
  }

  .settings-nav a {
    flex-direction: column;
    gap: 4px;
    padding: 8px 4px;
    font-size: 12px;
  }
}

@media (prefers-color-scheme: dark) {
  .settings-nav a.router-link-active {
    background: color-mix(in srgb, var(--p-300) 18%, transparent);
    color: var(--p-200);
  }
}
</style>

<!--
  Shared by every settings section, which all render inside .settings-page.
  Kept unscoped (but namespaced) so the sections don't each repeat it.
-->
<style>
.settings-page .set-card {
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 24px;
  margin-bottom: 16px;
  color: var(--color-text-primary);
}

.settings-page .set-card-title {
  font-size: 16px;
  font-weight: 600;
  margin: 0 0 4px;
  color: var(--color-text-primary);
}

.settings-page .set-card-title.is-danger {
  color: var(--r-500);
}

.settings-page .set-card-desc {
  font-size: 13px;
  color: var(--color-text-secondary);
  margin: 0 0 20px;
}

.settings-page .set-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-bottom: 18px;
  max-width: 460px;
}

.settings-page .set-field > label,
.settings-page .set-field > .set-label {
  font-size: 12px;
  font-weight: 500;
  color: var(--color-text-secondary);
}

.settings-page .set-input,
.settings-page .set-textarea {
  width: 100%;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  font: inherit;
  font-size: 14px;
  color: var(--color-text-primary);
  background: var(--color-surface);
}

.settings-page .set-input {
  height: 38px;
  padding: 0 10px;
}

.settings-page .set-input:disabled {
  background: var(--color-bg-subtle);
  color: var(--color-text-secondary);
}

.settings-page .set-textarea {
  min-height: 88px;
  padding: 10px;
  resize: vertical;
}

.settings-page .set-input:focus-visible,
.settings-page .set-textarea:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 0;
  border-color: var(--color-accent);
}

.settings-page .set-help {
  font-size: 12px;
  color: var(--color-text-tertiary);
}

.settings-page .set-error {
  font-size: 13px;
  color: var(--r-500);
  margin: 0 0 12px;
}

.settings-page .set-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid var(--color-border);
}

.settings-page .set-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: wrap;
  padding: 12px 0;
  border-top: 1px solid var(--color-border);
}

.settings-page .set-row-title {
  display: block;
  font-size: 14px;
  font-weight: 600;
}

.settings-page .set-row-desc {
  font-size: 12px;
  color: var(--color-text-secondary);
}

/* Buttons */
.settings-page .set-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 7px 14px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface);
  color: var(--color-text-primary);
  font: inherit;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  white-space: nowrap;
}

.settings-page .set-btn:hover:not(:disabled) {
  background: var(--color-bg-subtle);
}

.settings-page .set-btn:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.settings-page .set-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.settings-page .set-btn.is-muted {
  color: var(--color-text-secondary);
}

.settings-page .set-btn.is-primary {
  background: var(--p-500);
  border-color: var(--p-500);
  color: #fff;
  font-size: 14px;
  padding: 9px 22px;
}

.settings-page .set-btn.is-primary:hover:not(:disabled) {
  background: var(--p-600);
  border-color: var(--p-600);
}

/* A soft red tint at rest that fills solid red on hover, so the
   destructive action reads clearly without shouting. */
.settings-page .set-btn.is-danger {
  background: var(--r-50);
  border-color: color-mix(in srgb, var(--r-500) 30%, transparent);
  color: var(--r-700);
}

.settings-page .set-btn.is-danger:hover:not(:disabled) {
  background: var(--r-600);
  border-color: var(--r-600);
  color: #fff;
}

@media (prefers-color-scheme: dark) {
  .settings-page .set-btn.is-danger {
    background: color-mix(in srgb, var(--r-500) 14%, transparent);
    border-color: color-mix(in srgb, var(--r-500) 45%, transparent);
    color: var(--r-200);
  }
}

/* Toggle switch: a native checkbox styled as a switch. */
.settings-page .set-switch {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 14px;
  margin-bottom: 8px;
  cursor: pointer;
  width: fit-content;
}

.settings-page .set-switch input {
  appearance: none;
  margin: 0;
  width: 36px;
  height: 20px;
  border-radius: 10px;
  background: var(--color-border);
  position: relative;
  flex-shrink: 0;
  cursor: pointer;
  transition: background 0.15s;
}

.settings-page .set-switch input::after {
  content: "";
  position: absolute;
  top: 2px;
  left: 2px;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: #fff;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
  transition: left 0.15s;
}

.settings-page .set-switch input:checked {
  background: var(--p-500);
}

.settings-page .set-switch input:checked::after {
  left: 18px;
}

.settings-page .set-switch input:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

@media (prefers-reduced-motion: reduce) {
  .settings-page .set-switch input,
  .settings-page .set-switch input::after {
    transition: none;
  }
}
</style>
