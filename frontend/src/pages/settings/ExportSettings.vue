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
        <div class="export-json-wrap">
          <pre class="export-json" tabindex="0" aria-label="Exported library JSON">{{ exportData }}</pre>
          <button
            type="button"
            class="export-copy"
            :class="{ 'is-copied': copyState === 'copied' }"
            aria-label="Copy JSON to clipboard"
            @click="copyJson"
          >
            <Check v-if="copyState === 'copied'" :size="14" :stroke-width="2" aria-hidden="true" />
            <Copy v-else :size="14" :stroke-width="2" aria-hidden="true" />
            <span aria-hidden="true">{{ copyButtonText }}</span>
          </button>
          <span class="is-sr-only" role="status">{{ copyAnnouncement }}</span>
        </div>
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
import { computed, onBeforeUnmount, ref, watch } from "vue";
import { Check, Copy, Download } from "@lucide/vue";
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
  if (copyResetTimer) clearTimeout(copyResetTimer);
});

type CopyState = "idle" | "copied" | "failed";

const copyState = ref<CopyState>("idle");
let copyResetTimer: ReturnType<typeof setTimeout> | undefined;

const copyButtonText = computed(() =>
  copyState.value === "copied" ? "Copied" : copyState.value === "failed" ? "Copy failed" : "Copy"
);

const copyAnnouncement = computed(() =>
  copyState.value === "copied"
    ? "JSON copied to clipboard"
    : copyState.value === "failed"
      ? "Couldn't copy the JSON. Select it and copy manually."
      : ""
);

async function copyJson() {
  if (copyResetTimer) clearTimeout(copyResetTimer);
  try {
    await navigator.clipboard.writeText(exportData.value);
    copyState.value = "copied";
  } catch {
    copyState.value = "failed";
  }
  copyResetTimer = setTimeout(() => {
    copyState.value = "idle";
  }, 2000);
}

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

.export-json-wrap {
  position: relative;
}

.export-json:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.export-copy {
  position: absolute;
  top: 8px;
  right: 8px;
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 4px 8px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface);
  color: var(--color-text-secondary);
  font: inherit;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
}

.export-copy:hover {
  color: var(--color-text-primary);
  background: var(--color-bg-subtle);
}

.export-copy:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.export-copy.is-copied {
  color: var(--color-accent);
}

a.set-btn {
  text-decoration: none;
}
</style>
