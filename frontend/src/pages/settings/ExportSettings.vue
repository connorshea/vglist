<template>
  <div>
    <section class="set-card" aria-labelledby="export-heading">
      <h2 id="export-heading" class="set-card-title">Export library</h2>
      <p class="set-card-desc">
        Download your whole game library as JSON, including ratings, statuses and hours played.
      </p>

      <p v-if="exportError" class="set-error" role="alert">{{ exportError }}</p>

      <div v-if="exportData" class="export-result">
        <p class="set-help" role="status">Export complete. Download it, or copy the JSON below.</p>
        <pre class="export-json" tabindex="0" aria-label="Exported library JSON">{{ exportData }}</pre>
      </div>

      <div class="set-actions">
        <a v-if="downloadUrl" class="set-btn" :href="downloadUrl" download="vglist-library.json">
          <Download :size="15" :stroke-width="2" aria-hidden="true" />
          Download JSON
        </a>
        <button type="button" class="set-btn is-primary" :disabled="exporting" @click="exportLibrary">
          {{ exporting ? "Exporting…" : exportData ? "Export again" : "Export library" }}
        </button>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, ref, watch } from "vue";
import { Download } from "@lucide/vue";
import { useMutation } from "@/composables/useGraphQL";
import { EXPORT_LIBRARY } from "@/graphql/mutations/users-settings";
import type { ExportLibraryMutation } from "@/types/graphql";
import { extractGqlError } from "@/utils/graphql-errors";

const exportData = ref("");
const exportError = ref("");
const downloadUrl = ref<string | null>(null);

const { mutate, loading: exporting } = useMutation<ExportLibraryMutation>(EXPORT_LIBRARY);

// Keep a blob URL for the current export so it can be downloaded as a file,
// and release the old one whenever it changes.
watch(exportData, (json) => {
  if (downloadUrl.value) URL.revokeObjectURL(downloadUrl.value);
  downloadUrl.value = json ? URL.createObjectURL(new Blob([json], { type: "application/json" })) : null;
});

onBeforeUnmount(() => {
  if (downloadUrl.value) URL.revokeObjectURL(downloadUrl.value);
});

// The API returns compact JSON on one line; indent it so the preview is
// readable and the copied or downloaded file is easy to diff.
function prettyPrint(json: string): string {
  try {
    return JSON.stringify(JSON.parse(json), null, 2);
  } catch {
    return json;
  }
}

async function exportLibrary() {
  exportError.value = "";
  exportData.value = "";

  try {
    const response = await mutate();
    const result = response?.exportLibrary;

    if (result?.errors && result.errors.length > 0) {
      exportError.value = result.errors.join(", ");
    } else if (result?.libraryJson) {
      exportData.value = prettyPrint(result.libraryJson);
    }
  } catch (e) {
    exportError.value = extractGqlError(e);
  }
}
</script>

<style scoped>
.export-json {
  max-height: 400px;
  overflow: auto;
  margin-top: 8px;
  padding: 12px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-bg-subtle);
  color: var(--color-text-primary);
  font-family: var(--font-mono, monospace);
  font-size: 12px;
  line-height: 1.5;
  white-space: pre;
}

.export-json:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

a.set-btn {
  text-decoration: none;
}
</style>
