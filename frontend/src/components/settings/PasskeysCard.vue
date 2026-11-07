<template>
  <section id="passkeys" class="set-card" aria-labelledby="passkeys-heading">
    <h2 id="passkeys-heading" class="set-card-title">Passkeys</h2>
    <p class="set-card-desc">
      Sign in with your fingerprint, face, screen lock or a security key instead of typing your password. Your password
      keeps working too.
    </p>

    <div v-if="addError" class="pk-note" role="alert">
      <CircleAlert :size="16" :stroke-width="2" aria-hidden="true" />
      <span>{{ addError }}</span>
    </div>

    <p v-if="loading && !passkeys.length" class="pk-loading">Loading passkeys…</p>
    <p v-else-if="error" class="set-error">Couldn't load your passkeys: {{ error }}</p>

    <ul v-else-if="passkeys.length" class="pk-keys" aria-label="Your passkeys">
      <li
        v-for="passkey in passkeys"
        :key="passkey.id"
        class="pk-key"
        :class="{ 'is-new': passkey.id === newPasskeyId }"
      >
        <span class="pk-tile" aria-hidden="true">
          <KeyRound :size="20" :stroke-width="1.8" />
        </span>
        <div class="pk-info">
          <div class="pk-name">
            {{ passkey.nickname }}
            <span v-if="passkey.id === newPasskeyId" class="pk-badge is-ok">New</span>
            <span v-else-if="passkey.backedUp" class="pk-badge">Synced</span>
            <span v-else class="pk-badge is-neutral">This device only</span>
          </div>
          <div class="pk-meta">{{ describe(passkey) }}</div>
        </div>
        <div class="pk-acts">
          <button
            class="set-btn pk-icon-btn"
            type="button"
            :aria-label="`Rename ${passkey.nickname}`"
            @click="openRename(passkey)"
          >
            <Pencil :size="16" :stroke-width="2" aria-hidden="true" />
          </button>
          <button
            class="set-btn pk-icon-btn"
            type="button"
            :aria-label="`Remove ${passkey.nickname}`"
            @click="openRemove(passkey)"
          >
            <Trash2 :size="16" :stroke-width="2" aria-hidden="true" />
          </button>
        </div>
      </li>
    </ul>

    <div v-else class="pk-empty">
      <span class="pk-tile" aria-hidden="true">
        <KeyRound :size="20" :stroke-width="1.8" />
      </span>
      <span>
        <b>No passkeys yet</b>
        Add one and you can sign in from the email field with one tap.
      </span>
    </div>

    <div class="set-actions">
      <span v-if="!supported" class="set-help pk-help">This browser doesn't support passkeys.</span>
      <button class="set-btn is-primary" type="button" :disabled="!supported || adding" @click="openAdd">
        <LoaderCircle v-if="adding" class="pk-spin" :size="16" :stroke-width="2" aria-hidden="true" />
        <Plus v-else :size="16" :stroke-width="2" aria-hidden="true" />
        <span>{{ adding ? "Waiting for your browser…" : "Add a passkey" }}</span>
      </button>
    </div>

    <!-- Confirm the password before adding a passkey -->
    <ConfirmDialog
      v-model="showPasswordDialog"
      variant="primary"
      title="Confirm your password"
      confirm-label="Continue"
      loading-label="Checking…"
      :loading="adding"
      initial-focus="#passkey-password"
      @confirm="handleAdd"
    >
      <template #icon>
        <KeyRound :size="22" :stroke-width="1.8" />
      </template>
      Enter your password to add a passkey. Then your browser will ask you to create it.
      <form class="pk-field" @submit.prevent="handleAdd">
        <label for="passkey-password">Current password</label>
        <input
          id="passkey-password"
          v-model="passwordInput"
          class="set-input"
          type="password"
          autocomplete="current-password"
          :aria-invalid="passwordError ? true : undefined"
          :aria-describedby="passwordError ? 'passkey-password-error' : undefined"
        />
        <p v-if="passwordError" id="passkey-password-error" class="pk-field-error" role="alert">{{ passwordError }}</p>
      </form>
    </ConfirmDialog>

    <!-- Name a new passkey, or rename an existing one -->
    <ConfirmDialog
      v-model="showNameDialog"
      variant="primary"
      :title="naming?.isNew ? 'Passkey added' : 'Rename passkey'"
      :confirm-label="naming?.isNew ? 'Save name' : 'Rename'"
      loading-label="Saving…"
      :cancel-label="naming?.isNew ? 'Skip' : 'Cancel'"
      :loading="savingName"
      initial-focus="#passkey-name"
      @confirm="handleSaveName"
    >
      <template #icon>
        <KeyRound :size="22" :stroke-width="1.8" />
      </template>
      <template v-if="naming?.isNew">
        Next time, pick it from the email field when you sign in. Give it a name so you can tell your passkeys apart.
      </template>
      <template v-else>Give this passkey a name so you can tell your passkeys apart.</template>
      <div class="pk-field">
        <label for="passkey-name">Name</label>
        <input
          id="passkey-name"
          v-model="nameInput"
          class="set-input"
          type="text"
          :maxlength="NICKNAME_MAX_LENGTH"
          autocomplete="off"
          @keydown.enter.prevent="handleSaveName"
        />
      </div>
    </ConfirmDialog>

    <!-- Remove confirmation -->
    <ConfirmDialog
      v-model="showRemoveDialog"
      title="Remove this passkey?"
      confirm-label="Remove passkey"
      loading-label="Removing…"
      :loading="removing"
      @confirm="handleRemove"
    >
      <template #icon>
        <CircleAlert :size="22" :stroke-width="1.8" />
      </template>
      You won't be able to sign in with <strong>{{ removingPasskey?.nickname }}</strong> anymore. Your password and
      other passkeys still work. To clear it off the device too, delete it in your password manager.
    </ConfirmDialog>
  </section>
</template>

<script setup lang="ts">
import { computed, ref } from "vue";
import {
  browserSupportsWebAuthn,
  startRegistration,
  type PublicKeyCredentialCreationOptionsJSON
} from "@simplewebauthn/browser";
import { CircleAlert, KeyRound, LoaderCircle, Pencil, Plus, Trash2 } from "@lucide/vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";
import { gqlClient } from "@/graphql/client";
import { useQuery } from "@/composables/useGraphQL";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_CURRENT_USER_PASSKEYS } from "@/graphql/queries/users";
import {
  DELETE_PASSKEY,
  PASSKEY_REGISTRATION_OPTIONS,
  REGISTER_PASSKEY,
  RENAME_PASSKEY
} from "@/graphql/mutations/passkeys";
import { extractGqlError } from "@/utils/graphql-errors";
import { timeAgo } from "@/utils/time";
import { guessPasskeyNickname, isPasskeyCancellation, passkeyRegistrationErrorMessage } from "@/utils/passkeys";
import type {
  DeletePasskeyMutation,
  GetCurrentUserPasskeysQuery,
  PasskeyRegistrationOptionsMutation,
  RegisterPasskeyMutation,
  RenamePasskeyMutation
} from "@/types/graphql";

type Passkey = NonNullable<NonNullable<GetCurrentUserPasskeysQuery["currentUser"]>["passkeys"]>[number];

// Matches WebauthnCredential::NICKNAME_MAX_LENGTH on the server.
const NICKNAME_MAX_LENGTH = 60;

const { show: showSnackbar } = useSnackbar();
const supported = browserSupportsWebAuthn();

const { data, loading, error, refetch } = useQuery<GetCurrentUserPasskeysQuery>(GET_CURRENT_USER_PASSKEYS);
const passkeys = computed<Passkey[]>(() => data.value?.currentUser?.passkeys ?? []);

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
}

function describe(passkey: Passkey): string {
  const added = `Added ${formatDate(passkey.createdAt)}`;
  return passkey.lastUsedAt ? `${added} · Last used ${timeAgo(passkey.lastUsedAt)}` : `${added} · Not used yet`;
}

// ── Adding ──────────────────────────────────────────────────────────

const adding = ref(false);
const addError = ref("");
const newPasskeyId = ref<string | null>(null);

// The server asks for the current password before it hands out registration
// options, so a stolen session token alone can't add a passkey.
const showPasswordDialog = ref(false);
const passwordInput = ref("");
const passwordError = ref("");

function openAdd() {
  addError.value = "";
  passwordInput.value = "";
  passwordError.value = "";
  showPasswordDialog.value = true;
}

async function handleAdd() {
  if (adding.value) return;
  if (passwordInput.value === "") {
    passwordError.value = "Enter your current password.";
    return;
  }

  adding.value = true;
  passwordError.value = "";

  try {
    const optionsData = await gqlClient.request<PasskeyRegistrationOptionsMutation>(PASSKEY_REGISTRATION_OPTIONS, {
      currentPassword: passwordInput.value
    });
    const optionsResult = optionsData.passkeyRegistrationOptions;
    if (!optionsResult?.options || optionsResult.errors.length > 0) {
      // Keep the dialog open so a mistyped password can be fixed.
      passwordError.value = optionsResult?.errors.join(" ") || "Couldn't start adding a passkey.";
      return;
    }
    showPasswordDialog.value = false;
    passwordInput.value = "";

    let response;
    try {
      response = await startRegistration({
        optionsJSON: optionsResult.options as PublicKeyCredentialCreationOptionsJSON
      });
    } catch (e) {
      if (!isPasskeyCancellation(e)) addError.value = passkeyRegistrationErrorMessage(e);
      return;
    }

    const nickname = guessPasskeyNickname();
    const registerData = await gqlClient.request<RegisterPasskeyMutation>(REGISTER_PASSKEY, { response, nickname });
    const result = registerData.registerPasskey;
    if (!result?.passkey || result.errors.length > 0) {
      addError.value = result?.errors.join(" ") || "Couldn't add the passkey.";
      return;
    }

    newPasskeyId.value = result.passkey.id;
    await refetch();
    openName({ ...result.passkey, isNew: true });
  } catch (e) {
    const message = `Couldn't add the passkey: ${extractGqlError(e)}`;
    if (showPasswordDialog.value) passwordError.value = message;
    else addError.value = message;
  } finally {
    adding.value = false;
  }
}

// ── Naming / renaming ───────────────────────────────────────────────

const showNameDialog = ref(false);
const naming = ref<{ id: string; nickname: string; isNew: boolean } | null>(null);
const nameInput = ref("");
const savingName = ref(false);

function openName(target: { id: string; nickname: string; isNew: boolean }) {
  naming.value = target;
  nameInput.value = target.nickname;
  showNameDialog.value = true;
}

function openRename(passkey: Passkey) {
  openName({ id: passkey.id, nickname: passkey.nickname, isNew: false });
}

async function handleSaveName() {
  const target = naming.value;
  if (!target || savingName.value) return;

  const nickname = nameInput.value.trim();
  if (nickname === "" || nickname === target.nickname) {
    showNameDialog.value = false;
    return;
  }

  savingName.value = true;
  try {
    const result = (await gqlClient.request<RenamePasskeyMutation>(RENAME_PASSKEY, { id: target.id, nickname }))
      .renamePasskey;
    if (!result?.passkey || result.errors.length > 0) {
      showSnackbar(result?.errors.join(", ") || "Couldn't rename the passkey.", "error");
      return;
    }
    showNameDialog.value = false;
    await refetch();
  } catch (e) {
    showSnackbar(`Couldn't rename the passkey: ${extractGqlError(e)}`, "error");
  } finally {
    savingName.value = false;
  }
}

// ── Removing ────────────────────────────────────────────────────────

const showRemoveDialog = ref(false);
const removingPasskey = ref<Passkey | null>(null);
const removing = ref(false);

function openRemove(passkey: Passkey) {
  removingPasskey.value = passkey;
  showRemoveDialog.value = true;
}

async function handleRemove() {
  const target = removingPasskey.value;
  if (!target) return;

  removing.value = true;
  try {
    await gqlClient.request<DeletePasskeyMutation>(DELETE_PASSKEY, { id: target.id });
    showRemoveDialog.value = false;
    if (newPasskeyId.value === target.id) newPasskeyId.value = null;
    showSnackbar("Passkey removed.");
    await refetch();
  } catch (e) {
    showSnackbar(`Couldn't remove the passkey: ${extractGqlError(e)}`, "error");
  } finally {
    removing.value = false;
  }
}
</script>

<style scoped>
.pk-loading {
  font-size: 13px;
  color: var(--color-text-secondary);
}

.pk-keys {
  list-style: none;
  margin: 0;
  padding: 0;
}

.pk-key {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 0;
  border-top: 1px solid var(--color-border);
}

.pk-key.is-new {
  margin: 0 -12px;
  padding-left: 12px;
  padding-right: 12px;
  border-radius: var(--radius-sm);
  background: color-mix(in srgb, var(--p-300) 10%, transparent);
}

.pk-tile {
  width: 40px;
  height: 40px;
  border-radius: var(--radius-md);
  background: var(--color-bg-subtle);
  color: var(--color-text-secondary);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.pk-info {
  flex: 1;
  min-width: 0;
}

.pk-name {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  font-size: 14px;
  font-weight: 600;
  overflow-wrap: anywhere;
}

.pk-meta {
  font-size: 12px;
  color: var(--color-text-secondary);
  margin-top: 3px;
}

.pk-acts {
  display: flex;
  gap: 2px;
}

.settings-page .pk-icon-btn {
  width: 36px;
  padding: 0;
  color: var(--color-text-secondary);
  background: transparent;
  border-color: transparent;
}

.settings-page .pk-icon-btn:hover:not(:disabled) {
  color: var(--color-text-primary);
}

.pk-badge {
  display: inline-flex;
  align-items: center;
  font-size: 11px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: var(--radius-pill);
  background: var(--p-50);
  color: var(--p-600);
}

.pk-badge.is-neutral {
  background: var(--color-bg-subtle);
  color: var(--color-text-secondary);
}

.pk-badge.is-ok {
  background: #eaf3de;
  color: #27500a;
}

.pk-empty {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px;
  border: 1px dashed var(--color-border);
  border-radius: var(--radius-md);
  font-size: 13px;
  line-height: 1.45;
  color: var(--color-text-secondary);
}

.pk-empty b {
  display: block;
  color: var(--color-text-primary);
  font-size: 14px;
  font-weight: 600;
}

.pk-note {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 12px 14px;
  margin-bottom: 16px;
  border-radius: var(--radius-sm);
  background: #fff8db;
  color: #5c4900;
  font-size: 13px;
  line-height: 1.45;
}

.pk-note svg {
  flex-shrink: 0;
  margin-top: 2px;
}

.pk-help {
  margin-right: auto;
  align-self: center;
}

.pk-spin {
  animation: pk-spin 1s linear infinite;
}

@keyframes pk-spin {
  to {
    transform: rotate(360deg);
  }
}

@media (prefers-reduced-motion: reduce) {
  .pk-spin {
    animation: none;
  }
}

.pk-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-top: 18px;
  text-align: left;
}

.pk-field label {
  font-size: 12px;
  font-weight: 500;
  color: var(--color-text-secondary);
}

.pk-field-error {
  margin: 0;
  font-size: 13px;
  color: var(--color-danger-text);
}

/* ConfirmDialog teleports to <body>, outside .settings-page, so the inputs
   need their own copy of the settings input styles. */
.pk-field .set-input {
  height: 38px;
  width: 100%;
  padding: 0 10px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface);
  color: var(--color-text-primary);
  font: inherit;
  font-size: 14px;
}

.pk-field .set-input:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 0;
  border-color: var(--color-accent);
}

@media (max-width: 768px) {
  .settings-page .pk-icon-btn {
    width: 44px;
    min-height: 44px;
  }

  .pk-key {
    gap: 12px;
  }
}

@media (prefers-color-scheme: dark) {
  /* --color-bg-subtle is too close to the page background in dark mode. */
  .pk-tile,
  .pk-badge.is-neutral {
    background: color-mix(in srgb, var(--color-text-primary) 10%, transparent);
  }

  .pk-badge {
    background: color-mix(in srgb, var(--p-300) 18%, transparent);
    color: var(--p-200);
  }

  .pk-badge.is-ok {
    background: rgba(99, 153, 34, 0.2);
    color: #c0dd97;
  }

  .pk-note {
    background: rgba(239, 159, 39, 0.14);
    color: #fac775;
  }
}
</style>
