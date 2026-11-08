<template>
  <div>
    <section class="set-card" aria-labelledby="connected-heading">
      <h2 id="connected-heading" class="set-card-title">Connected accounts</h2>
      <p class="set-card-desc">Link a store account to import your library from it.</p>

      <p v-if="error" class="set-error" role="alert">Failed to load connected accounts: {{ error.message }}</p>

      <div class="set-row">
        <span class="import-account">
          <span class="import-account-logo" aria-hidden="true"><span class="import-steam-logo"></span></span>
          <span>
            <span class="set-row-title">Steam</span>
            <span class="set-row-desc">
              <template v-if="loading && !data">Loading…</template>
              <a v-else-if="steamProfileUrl" :href="steamProfileUrl" target="_blank" rel="noopener noreferrer">
                {{ steamProfileUrl }}
              </a>
              <template v-else>Not connected</template>
            </span>
          </span>
        </span>
        <button
          v-if="steamProfileUrl"
          type="button"
          class="set-btn is-muted"
          :disabled="disconnecting"
          @click="showDisconnectConfirm = true"
        >
          <span>Disconnect</span>
        </button>
      </div>

      <form v-if="data && !steamProfileUrl" class="import-connect" @submit.prevent="connectSteam">
        <div class="set-field">
          <label for="steam-username">Steam username</label>
          <input
            id="steam-username"
            v-model="steamUsername"
            class="set-input"
            type="text"
            autocomplete="off"
            spellcheck="false"
            required
            aria-describedby="steam-username-help"
          />
          <span id="steam-username-help" class="set-help">
            The custom URL name from your profile, as in steamcommunity.com/id/<b>username</b>.
          </span>
        </div>
        <button type="submit" class="set-btn" :disabled="connecting || steamUsername.trim() === ''">
          <span>{{ connecting ? "Connecting…" : "Connect" }}</span>
        </button>
      </form>
    </section>

    <form
      v-if="steamProfileUrl"
      class="set-card"
      aria-labelledby="steam-import-heading"
      @submit.prevent="importLibrary"
    >
      <h2 id="steam-import-heading" class="set-card-title">Import from Steam</h2>
      <p class="set-card-desc">
        Adds the games in your Steam library that vglist knows about. Your Steam profile's game details need to be
        public.
      </p>

      <label class="set-switch">
        <input v-model="updateHours" type="checkbox" role="switch" />
        Update hours played for games already in my library
      </label>

      <div v-if="importResult" class="import-result" role="status">
        <p>
          Added <strong>{{ importResult.addedGamesCount }}</strong> {{ pluralize(importResult.addedGamesCount) }},
          updated <strong>{{ importResult.updatedGamesCount }}</strong> {{ pluralize(importResult.updatedGamesCount) }}.
        </p>
        <p v-if="importResult.unmatchedCount > 0" class="set-help">
          {{ importResult.unmatchedCount }} {{ pluralize(importResult.unmatchedCount) }} couldn't be matched to a game
          on vglist. They're listed under Import results below.
        </p>
      </div>

      <div class="set-actions">
        <button type="submit" class="set-btn is-primary" :disabled="importing">
          <span>{{ importing ? "Importing…" : "Import library" }}</span>
        </button>
      </div>
    </form>

    <SteamImportResults v-if="importResult" :result="importResult" />

    <ConfirmDialog
      v-model="showDisconnectConfirm"
      title="Disconnect Steam?"
      confirm-label="Disconnect"
      loading-label="Disconnecting…"
      :loading="disconnecting"
      @confirm="disconnectSteam"
    >
      Games you've already imported stay in your library.
    </ConfirmDialog>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from "vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";
import SteamImportResults from "@/components/settings/SteamImportResults.vue";
import { useMutation, useQuery } from "@/composables/useGraphQL";
import { useSnackbar } from "@/composables/useSnackbar";
import { CONNECT_STEAM, DISCONNECT_STEAM, IMPORT_STEAM_LIBRARY } from "@/graphql/mutations/users-settings";
import { GET_CURRENT_USER_STEAM_ACCOUNT } from "@/graphql/queries/users";
import type {
  ConnectSteamMutation,
  DisconnectSteamMutation,
  GetCurrentUserSteamAccountQuery,
  ImportSteamLibraryMutation
} from "@/types/graphql";
import { extractGqlError } from "@/utils/graphql-errors";

type ImportResult = ImportSteamLibraryMutation["importSteamLibrary"];

const { show: showSnackbar } = useSnackbar();

const { data, loading, error, refetch } = useQuery<GetCurrentUserSteamAccountQuery>(GET_CURRENT_USER_STEAM_ACCOUNT);

const userId = computed(() => data.value?.currentUser?.id);
const steamProfileUrl = computed(() => data.value?.currentUser?.steamProfileUrl ?? null);

function pluralize(count: number) {
  return count === 1 ? "game" : "games";
}

// Connect
const steamUsername = ref("");
const { mutate: connectMutate, loading: connecting } = useMutation<ConnectSteamMutation>(CONNECT_STEAM);

async function connectSteam() {
  if (!userId.value) {
    return;
  }

  try {
    await connectMutate({ userId: userId.value, steamUsername: steamUsername.value.trim() });
    steamUsername.value = "";
    await refetch();
    showSnackbar("Steam account connected.");
  } catch (e) {
    showSnackbar(`Failed to connect Steam: ${extractGqlError(e)}`, "error");
  }
}

// Disconnect
const showDisconnectConfirm = ref(false);
const { mutate: disconnectMutate, loading: disconnecting } = useMutation<DisconnectSteamMutation>(DISCONNECT_STEAM);

async function disconnectSteam() {
  if (!userId.value) {
    return;
  }

  try {
    await disconnectMutate({ userId: userId.value });
    showDisconnectConfirm.value = false;
    importResult.value = null;
    await refetch();
    showSnackbar("Steam account disconnected.");
  } catch (e) {
    showSnackbar(`Failed to disconnect Steam: ${extractGqlError(e)}`, "error");
  }
}

// Import
const updateHours = ref(false);
const importResult = ref<ImportResult | null>(null);
const { mutate: importMutate, loading: importing } = useMutation<ImportSteamLibraryMutation>(IMPORT_STEAM_LIBRARY);

async function importLibrary() {
  if (!userId.value) {
    return;
  }
  importResult.value = null;

  try {
    const response = await importMutate({ userId: userId.value, updateHours: updateHours.value });
    importResult.value = response.importSteamLibrary;
  } catch (e) {
    showSnackbar(`Failed to import your Steam library: ${extractGqlError(e)}`, "error");
  }
}
</script>

<style scoped>
.import-account {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
}

.import-account-logo {
  width: 36px;
  height: 36px;
  flex-shrink: 0;
  border-radius: 10px;
  border: 1px solid var(--color-border);
  background: var(--color-bg-subtle);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--color-text-primary);
}

/* The Steam logo as a mask, so it takes the text colour in both themes. */
.import-steam-logo {
  width: 20px;
  height: 20px;
  background: currentColor;
  mask: url("../../assets/images/steam-logo.svg") center / contain no-repeat;
}

.import-account .set-row-desc a {
  overflow-wrap: anywhere;
}

.import-connect {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  flex-wrap: wrap;
  padding-top: 12px;
  border-top: 1px solid var(--color-border);
}

.import-connect .set-field {
  flex: 1 1 260px;
  margin-bottom: 0;
}

/* Line the button up with the input, below its label. */
.import-connect .set-btn {
  height: 38px;
  margin-top: 24px;
}

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
</style>
