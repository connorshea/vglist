<template>
  <form class="set-card" aria-labelledby="backloggd-import-heading" @submit.prevent="startImport">
    <h2 id="backloggd-import-heading" class="set-card-title">Import from Backloggd</h2>
    <p class="set-card-desc">
      Adds the games on your Backloggd profile that vglist knows about, matched by their IGDB ID. Played games are
      marked Completed, Playing as In progress and Backlog as Unplayed, and your star ratings come along. Games already
      in your library only get a status or rating they don't have yet. Wishlisted games aren't imported.
    </p>

    <div class="set-field">
      <label for="backloggd-username">Backloggd username</label>
      <input
        id="backloggd-username"
        v-model="username"
        class="set-input"
        type="text"
        autocomplete="off"
        spellcheck="false"
        required
        :disabled="inProgress"
        aria-describedby="backloggd-username-help"
      />
      <span id="backloggd-username-help" class="set-help">
        Your username, or a link to your profile, as in backloggd.com/u/<b>username</b>.
      </span>
    </div>

    <div v-if="backloggdImport" class="import-result" :class="{ 'is-error': failed }" role="status">
      <p v-if="inProgress" class="backloggd-progress">
        <LoaderCircle :size="16" class="backloggd-spinner" aria-hidden="true" />
        <span>
          Importing from <strong>{{ backloggdImport.username }}</strong>… Big lists can take a minute or two. You can
          leave this page and come back.
        </span>
      </p>
      <p v-else-if="failed">{{ backloggdImport.errorMessage ?? "The import didn't finish. Try again." }}</p>
      <template v-else>
        <p>
          Added <strong>{{ backloggdImport.addedGames.length }}</strong>
          {{ pluralize(backloggdImport.addedGames.length) }}, updated
          <strong>{{ backloggdImport.updatedGames.length }}</strong>
          {{ pluralize(backloggdImport.updatedGames.length) }} from <strong>{{ backloggdImport.username }}</strong>'s
          Backloggd.
        </p>
        <p v-if="backloggdImport.unmatchedGames.length > 0" class="set-help">
          {{ backloggdImport.unmatchedGames.length }} {{ pluralize(backloggdImport.unmatchedGames.length) }} couldn't be
          matched to a game on vglist. They're listed under Backloggd import results below.
        </p>
      </template>
    </div>

    <div class="set-actions">
      <button type="submit" class="set-btn is-primary" :disabled="starting || inProgress || username.trim() === ''">
        <span>{{ inProgress ? "Importing…" : "Import games" }}</span>
      </button>
    </div>
  </form>

  <ImportResults
    v-if="backloggdImport && succeeded"
    id-prefix="backloggd-results"
    title="Backloggd import results"
    updated-title="Filled in status or rating"
    :added-games="backloggdImport.addedGames"
    :updated-games="backloggdImport.updatedGames"
    :unmatched-games="unmatchedGames"
    unmatched-note="These games from your Backloggd profile don't match a game on vglist yet, or the game on vglist doesn't have an IGDB ID."
    nothing-changed-message="Everything vglist recognizes from your Backloggd profile is already in your library."
  />
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from "vue";
import { LoaderCircle } from "@lucide/vue";
import ImportResults from "@/components/settings/ImportResults.vue";
import { useMutation, useQuery } from "@/composables/useGraphQL";
import { useSnackbar } from "@/composables/useSnackbar";
import { IMPORT_BACKLOGGD_LIBRARY } from "@/graphql/mutations/users-settings";
import { GET_BACKLOGGD_IMPORT } from "@/graphql/queries/users";
import type { GetBackloggdImportQuery, ImportBackloggdLibraryMutation } from "@/types/graphql";
import { extractGqlError } from "@/utils/graphql-errors";

// How often to check on an import that's running.
const POLL_INTERVAL_MS = 3000;

const props = defineProps<{
  userId: string;
}>();

const { show: showSnackbar } = useSnackbar();

const { data, refetch } = useQuery<GetBackloggdImportQuery>(GET_BACKLOGGD_IMPORT, { cache: false });

const backloggdImport = computed(() => data.value?.currentUser?.backloggdImport ?? null);
const inProgress = computed(
  () => backloggdImport.value?.status === "QUEUED" || backloggdImport.value?.status === "RUNNING"
);
const failed = computed(() => backloggdImport.value?.status === "FAILED");
const succeeded = computed(() => backloggdImport.value?.status === "SUCCEEDED");

function pluralize(count: number) {
  return count === 1 ? "game" : "games";
}

// Start with the username from the last import, so importing again is one click.
const username = ref("");
watch(
  () => backloggdImport.value?.username,
  (last) => {
    if (last && username.value === "") {
      username.value = last;
    }
  },
  { immediate: true }
);

// Poll while the import runs.
let pollTimer: ReturnType<typeof setTimeout> | null = null;

function stopPolling() {
  if (pollTimer !== null) {
    clearTimeout(pollTimer);
    pollTimer = null;
  }
}

function schedulePoll() {
  stopPolling();
  pollTimer = setTimeout(async () => {
    pollTimer = null;
    try {
      await refetch();
    } finally {
      if (inProgress.value) {
        schedulePoll();
      }
    }
  }, POLL_INTERVAL_MS);
}

watch(inProgress, (running) => (running ? schedulePoll() : stopPolling()), { immediate: true });
onBeforeUnmount(stopPolling);

const { mutate, loading: starting } = useMutation<ImportBackloggdLibraryMutation>(IMPORT_BACKLOGGD_LIBRARY);

async function startImport() {
  try {
    await mutate({ userId: props.userId, backloggdUsername: username.value.trim() });
    await refetch();
  } catch (e) {
    showSnackbar(`Failed to import from Backloggd: ${extractGqlError(e)}`, "error");
  }
}

const unmatchedGames = computed(() =>
  (backloggdImport.value?.unmatchedGames ?? []).map((game) => ({
    key: game.slug,
    name: game.name,
    url: game.url,
    linkLabel: "View on Backloggd"
  }))
);
</script>

<style scoped>
.import-result {
  margin-top: 16px;
  padding: 12px 14px;
  border-radius: var(--radius-sm);
  background: var(--color-bg-subtle);
  font-size: 14px;
}

.import-result p + p {
  margin-top: 4px;
}

.import-result.is-error {
  color: var(--color-danger-text);
}

.backloggd-progress {
  display: flex;
  align-items: flex-start;
  gap: 8px;
}

.backloggd-spinner {
  flex-shrink: 0;
  margin-top: 2px;
  animation: backloggd-spin 1s linear infinite;
}

@keyframes backloggd-spin {
  to {
    transform: rotate(360deg);
  }
}

@media (prefers-reduced-motion: reduce) {
  .backloggd-spinner {
    animation: none;
  }
}
</style>
