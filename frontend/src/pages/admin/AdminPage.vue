<template>
  <div class="admin-page">
    <div class="admin-header">
      <h1 class="admin-heading">Admin</h1>
      <button type="button" class="button admin-export" @click="showExportConfirm = true">
        <Download :size="16" aria-hidden="true" />
        <span>Export games</span>
      </button>
    </div>

    <ConfirmDialog
      v-model="showExportConfirm"
      title="Export the games database?"
      confirm-label="Export"
      loading-label="Exporting…"
      variant="primary"
      :loading="exportingGames"
      @confirm="downloadGamesExport"
    >
      <template #icon>
        <Download :size="20" :stroke-width="2" aria-hidden="true" />
      </template>
      This downloads every game's name, vglist ID, Steam app IDs, and Wikidata ID as a JSON file.
    </ConfirmDialog>

    <nav class="admin-tabs scroll-fade-x" aria-label="Admin sections">
      <router-link
        v-for="section in sections"
        :key="section.name"
        :to="{ name: section.name }"
        class="admin-tab"
        exact-active-class="is-active"
        :aria-current="route.name === section.name ? 'page' : undefined"
      >
        {{ section.label }}
      </router-link>
    </nav>

    <router-view />
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { useRoute } from "vue-router";
import { Download } from "@lucide/vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";
import { useSnackbar } from "@/composables/useSnackbar";
import { useAuthStore } from "@/stores/auth";

const route = useRoute();
const { show: showSnackbar } = useSnackbar();

const sections = [
  { name: "admin", label: "Dashboard" },
  { name: "adminWikidataBlocklist", label: "Wikidata blocklist" },
  { name: "adminSteamBlocklist", label: "Steam blocklist" },
  { name: "adminUnmatchedGames", label: "Unmatched games" }
] as const;

// Games export. This is a REST endpoint rather than GraphQL, so fetch it with
// the JWT directly and hand the response to the browser as a file download.
const authStore = useAuthStore();
const showExportConfirm = ref(false);
const exportingGames = ref(false);

async function downloadGamesExport() {
  exportingGames.value = true;
  try {
    const response = await fetch(`${import.meta.env.VITE_API_URL}/api/admin/games_export`, {
      headers: { Accept: "application/json", Authorization: `Bearer ${authStore.token}` }
    });
    if (!response.ok) {
      throw new Error(`Export failed (HTTP ${response.status}).`);
    }

    const url = URL.createObjectURL(await response.blob());
    const link = document.createElement("a");
    link.href = url;
    link.download = `vglist-games-${new Date().toISOString().slice(0, 10)}.json`;
    link.click();
    // Revoke on the next tick: Safari can cancel the download if the URL is
    // revoked synchronously after the click.
    setTimeout(() => URL.revokeObjectURL(url), 0);
    showExportConfirm.value = false;
  } catch (err) {
    showSnackbar(err instanceof Error ? err.message : "Export failed.", "error");
  } finally {
    exportingGames.value = false;
  }
}
</script>

<style scoped>
.admin-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 1.25rem;
}

.admin-heading {
  font-size: 24px;
  font-weight: 600;
  letter-spacing: -0.3px;
  color: var(--color-text-primary);
  margin: 0;
}

.admin-export {
  gap: 8px;
  font-size: 0.875rem;
  font-weight: 500;
  border-radius: var(--radius-md);
}

.admin-tabs {
  display: flex;
  overflow-x: auto;
  border-bottom: 1px solid var(--color-border);
  margin-bottom: 1.75rem;
}

.admin-tab {
  padding: 10px 16px;
  font-size: 0.875rem;
  white-space: nowrap;
  color: var(--color-text-secondary);
  border-bottom: 2px solid transparent;
  /* Sits on top of the nav's bottom border. */
  margin-bottom: -1px;
}

.admin-tab:hover {
  color: var(--color-text-primary);
}

.admin-tab.is-active {
  color: var(--color-accent);
  border-bottom-color: var(--color-accent);
  font-weight: 500;
}

.admin-tab:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: -2px;
  border-radius: var(--radius-sm) var(--radius-sm) 0 0;
}

@media (max-width: 768px) {
  .admin-tab {
    padding: 12px;
  }
}
</style>
