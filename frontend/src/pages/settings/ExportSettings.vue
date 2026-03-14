<template>
  <div>
    <h2 class="title is-4">Export Library</h2>

    <p class="mb-4">Export your game library as JSON.</p>

    <div v-if="exportError" class="notification is-danger">
      <p>{{ exportError }}</p>
    </div>

    <div v-if="exportData" class="mb-4">
      <div class="notification is-success">
        <p>Export complete. Copy the JSON below or download it.</p>
      </div>
      <pre class="box" style="max-height: 400px; overflow: auto;">{{ exportData }}</pre>
    </div>

    <button
      class="button is-primary"
      :class="{ 'is-loading': exporting }"
      :disabled="exporting"
      @click="exportLibrary"
    >
      Export Library
    </button>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useMutation } from '@/composables/useGraphQL'
import { EXPORT_LIBRARY } from '@/graphql/mutations/users'
import type { ExportLibraryData } from '@/types/graphql'

const exportData = ref('')
const exportError = ref('')

const { mutate, loading: exporting } = useMutation<ExportLibraryData>(EXPORT_LIBRARY)

async function exportLibrary() {
  exportError.value = ''
  exportData.value = ''

  try {
    const response = await mutate()
    const result = response?.exportLibrary

    if (result?.errors && result.errors.length > 0) {
      exportError.value = result.errors.join(', ')
    } else if (result?.libraryJson) {
      exportData.value = result.libraryJson
    }
  } catch (e) {
    exportError.value = e instanceof Error ? e.message : 'An unexpected error occurred.'
  }
}
</script>
