<template>
  <div>
    <h2 class="title is-4">Account Settings</h2>

    <!-- Change email -->
    <form class="mb-5" @submit.prevent="handleUpdateEmail">
      <h3 class="title is-5">Change Email</h3>
      <div class="field">
        <label class="label" for="current-email">Current email</label>
        <div class="control">
          <input id="current-email" class="input" type="email" :value="authStore.user?.email" disabled />
        </div>
      </div>
      <div class="field">
        <label class="label" for="new-email">New email</label>
        <div class="control">
          <input id="new-email" v-model="newEmail" class="input" type="email" required />
        </div>
      </div>
      <div class="field">
        <label class="label" for="email-password">Current password</label>
        <div class="control">
          <input id="email-password" v-model="emailPassword" class="input" type="password" required />
        </div>
      </div>
      <button
        class="button is-primary"
        type="submit"
        :class="{ 'is-loading': updatingEmail }"
        :disabled="updatingEmail"
      >
        Update email
      </button>
    </form>

    <hr />

    <!-- Change password -->
    <form class="mb-5" @submit.prevent="handleUpdatePassword">
      <h3 class="title is-5">Change Password</h3>
      <div class="field">
        <label class="label" for="pw-current">Current password</label>
        <div class="control">
          <input id="pw-current" v-model="currentPassword" class="input" type="password" required />
        </div>
      </div>
      <div class="field">
        <label class="label" for="pw-new">New password</label>
        <div class="control">
          <input id="pw-new" v-model="newPassword" class="input" type="password" required minlength="8" />
        </div>
        <p class="help">Minimum 8 characters.</p>
      </div>
      <div class="field">
        <label class="label" for="pw-confirm">Confirm new password</label>
        <div class="control">
          <input
            id="pw-confirm"
            v-model="newPasswordConfirmation"
            class="input"
            type="password"
            required
            minlength="8"
          />
        </div>
      </div>
      <button
        class="button is-primary"
        type="submit"
        :class="{ 'is-loading': updatingPassword }"
        :disabled="updatingPassword"
      >
        Update password
      </button>
    </form>

    <hr />

    <!-- Danger zone -->
    <h3 class="title is-5 has-text-danger">Danger Zone</h3>

    <div class="danger-zone">
      <div class="danger-item">
        <div>
          <strong>Reset game library</strong>
          <p class="has-text-grey is-size-7">Remove all games from your library. This cannot be undone.</p>
        </div>
        <button class="button is-warning is-outlined" :disabled="resettingLibrary" @click="showResetConfirm = true">
          Reset library
        </button>
      </div>

      <div class="danger-item">
        <div>
          <strong>Delete account</strong>
          <p class="has-text-grey is-size-7">Permanently delete your account and all associated data.</p>
        </div>
        <button class="button is-danger is-outlined" :disabled="deletingAccount" @click="showDeleteConfirm = true">
          Delete account
        </button>
      </div>
    </div>

    <!-- Reset library confirmation -->
    <ConfirmDialog
      v-model="showResetConfirm"
      title="Reset game library?"
      confirm-label="Reset library"
      loading-label="Resetting…"
      :loading="resettingLibrary"
      @confirm="handleResetLibrary"
    >
      <template #icon>
        <CircleAlert :size="22" :stroke-width="1.8" />
      </template>
      This will <strong>permanently remove all games</strong> from your library, including ratings, statuses, and notes.
      This action cannot be undone.
    </ConfirmDialog>

    <!-- Delete account confirmation -->
    <ConfirmDialog
      v-model="showDeleteConfirm"
      title="Delete your account?"
      confirm-label="Delete account"
      loading-label="Deleting…"
      :loading="deletingAccount"
      @confirm="handleDeleteAccount"
    >
      <template #icon>
        <CircleAlert :size="22" :stroke-width="1.8" />
      </template>
      This will <strong>permanently delete your account</strong> and all associated data, including your game library,
      favorites, and activity history. This action cannot be undone.
    </ConfirmDialog>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { useRouter } from "vue-router";
import { useAuthStore } from "@/stores/auth";
import { useSnackbar } from "@/composables/useSnackbar";
import { gqlClient } from "@/graphql/client";
import { DELETE_USER, RESET_USER_LIBRARY, UPDATE_EMAIL, UPDATE_PASSWORD } from "@/graphql/mutations/users-settings";
import { extractGqlError } from "@/utils/graphql-errors";
import ConfirmDialog from "@/components/ConfirmDialog.vue";
import { CircleAlert } from "lucide-vue-next";

interface MutationResult {
  updateEmail?: { user?: { id: string } | null; errors: string[] } | null;
  updatePassword?: { user?: { id: string } | null; errors: string[] } | null;
}

const router = useRouter();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

// Email change
const newEmail = ref("");
const emailPassword = ref("");
const updatingEmail = ref(false);

async function handleUpdateEmail() {
  updatingEmail.value = true;

  try {
    const data = await gqlClient.request<MutationResult>(UPDATE_EMAIL, {
      newEmail: newEmail.value,
      currentPassword: emailPassword.value
    });

    const result = data.updateEmail;
    if (result?.errors && result.errors.length > 0) {
      showSnackbar(result.errors.join(", "), "error");
    } else {
      authStore.updateUser({ email: newEmail.value });
      showSnackbar("Email updated successfully.");
      newEmail.value = "";
      emailPassword.value = "";
    }
  } catch (err) {
    showSnackbar(`Failed to update email: ${extractGqlError(err)}`, "error");
  } finally {
    updatingEmail.value = false;
  }
}

// Password change
const currentPassword = ref("");
const newPassword = ref("");
const newPasswordConfirmation = ref("");
const updatingPassword = ref(false);

async function handleUpdatePassword() {
  updatingPassword.value = true;

  try {
    const data = await gqlClient.request<MutationResult>(UPDATE_PASSWORD, {
      currentPassword: currentPassword.value,
      newPassword: newPassword.value,
      newPasswordConfirmation: newPasswordConfirmation.value
    });

    const result = data.updatePassword;
    if (result?.errors && result.errors.length > 0) {
      showSnackbar(result.errors.join(", "), "error");
    } else {
      showSnackbar("Password updated successfully.");
      currentPassword.value = "";
      newPassword.value = "";
      newPasswordConfirmation.value = "";
    }
  } catch (err) {
    showSnackbar(`Failed to update password: ${extractGqlError(err)}`, "error");
  } finally {
    updatingPassword.value = false;
  }
}

// Reset library
const showResetConfirm = ref(false);
const resettingLibrary = ref(false);

async function handleResetLibrary() {
  if (!authStore.user) return;
  resettingLibrary.value = true;

  try {
    await gqlClient.request(RESET_USER_LIBRARY, { userId: authStore.user.id });
    showSnackbar("Your game library has been reset.");
    showResetConfirm.value = false;
  } catch (err) {
    showSnackbar(`Failed to reset library: ${extractGqlError(err)}`, "error");
  } finally {
    resettingLibrary.value = false;
  }
}

// Delete account
const showDeleteConfirm = ref(false);
const deletingAccount = ref(false);

async function handleDeleteAccount() {
  if (!authStore.user) return;
  deletingAccount.value = true;

  try {
    await gqlClient.request(DELETE_USER, { userId: authStore.user.id });
    showDeleteConfirm.value = false;
    authStore.clearAuth();
    router.replace({ name: "home" });
    showSnackbar("Your account has been deleted.");
  } catch (err) {
    showSnackbar(`Failed to delete account: ${extractGqlError(err)}`, "error");
    deletingAccount.value = false;
  }
}
</script>

<style scoped>
.danger-zone {
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg, 8px);
  overflow: hidden;
}

.danger-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 1rem 1.25rem;
}

.danger-item + .danger-item {
  border-top: 1px solid var(--color-border);
}
</style>
