<template>
  <div>
    <h2 class="title is-4">Export Library</h2>

    <p class="mb-4">Export your game library as a JSON file.</p>

    <div v-if="exportError" class="notification is-danger">
      <p>{{ exportError }}</p>
    </div>

    <div v-if="exportSuccess" class="notification is-success">
      <p>{{ exportSuccess }}</p>
    </div>

    <button class="button is-primary" :class="{ 'is-loading': exporting }" :disabled="exporting" @click="exportLibrary">
      Export Library
    </button>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { useMutation } from "@/composables/useGraphQL";
import { EXPORT_LIBRARY } from "@/graphql/mutations/users-settings";
import { extractGqlError } from "@/utils/graphql-errors";
import { useAuthStore } from "@/stores/auth";

interface ExportLibraryResult {
  exportLibrary?: {
    libraryJson?: string | null;
    errors: string[];
  } | null;
}

const authStore = useAuthStore();
const exportSuccess = ref("");
const exportError = ref("");

const { mutate, loading: exporting } = useMutation<ExportLibraryResult>(EXPORT_LIBRARY);

function downloadJson(jsonString: string) {
  const date = new Date().toISOString().slice(0, 10);
  const username = authStore.user?.username ?? "user";
  const filename = `vglist-export-${username}-${date}.json`;

  let games: unknown[];
  try {
    games = JSON.parse(jsonString) as unknown[];
  } catch {
    exportError.value = "The server returned invalid JSON. Please try again.";
    return null;
  }

  const exportPayload = {
    exportedAt: new Date().toISOString(),
    source: "vglist",
    version: 1,
    games
  };

  const formatted = JSON.stringify(exportPayload, null, 2);
  const blob = new Blob([formatted], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);

  return games.length;
}

async function exportLibrary() {
  exportError.value = "";
  exportSuccess.value = "";

  try {
    const response = await mutate();
    const result = response?.exportLibrary;

    if (result?.errors && result.errors.length > 0) {
      exportError.value = result.errors.join(", ");
    } else if (result?.libraryJson) {
      const gameCount = downloadJson(result.libraryJson);
      if (gameCount !== null) {
        exportSuccess.value = `Your library export (${gameCount} ${gameCount === 1 ? "game" : "games"}) has been downloaded.`;
      }
    }
  } catch (e) {
    exportError.value = extractGqlError(e);
  }
}
</script>
