<template>
  <div>
    <form class="set-card" aria-labelledby="email-heading" @submit.prevent="handleUpdateEmail">
      <h2 id="email-heading" class="set-card-title">Email</h2>
      <p class="set-card-desc">We'll send a confirmation link to your new address before it changes.</p>
      <div class="set-field">
        <label for="current-email">Current email</label>
        <input id="current-email" class="set-input" type="email" :value="authStore.user?.email" disabled />
      </div>
      <div class="set-field">
        <label for="new-email">New email</label>
        <input id="new-email" v-model="newEmail" class="set-input" type="email" autocomplete="email" required />
      </div>
      <div class="set-field">
        <label for="email-password">Current password</label>
        <input
          id="email-password"
          v-model="emailPassword"
          class="set-input"
          type="password"
          autocomplete="current-password"
          required
        />
      </div>
      <div class="set-actions">
        <button class="set-btn is-primary" type="submit" :disabled="updatingEmail">
          <span>{{ updatingEmail ? "Updating…" : "Update email" }}</span>
        </button>
      </div>
    </form>

    <form class="set-card" aria-labelledby="password-heading" @submit.prevent="handleUpdatePassword">
      <h2 id="password-heading" class="set-card-title">Password</h2>
      <p class="set-card-desc">Use at least 8 characters.</p>
      <div class="set-field">
        <label for="pw-current">Current password</label>
        <input
          id="pw-current"
          v-model="currentPassword"
          class="set-input"
          type="password"
          autocomplete="current-password"
          required
        />
      </div>
      <div class="set-field">
        <label for="pw-new">New password</label>
        <input
          id="pw-new"
          v-model="newPassword"
          class="set-input"
          type="password"
          autocomplete="new-password"
          required
          minlength="8"
        />
      </div>
      <div class="set-field">
        <label for="pw-confirm">Confirm new password</label>
        <input
          id="pw-confirm"
          v-model="newPasswordConfirmation"
          class="set-input"
          type="password"
          autocomplete="new-password"
          required
          minlength="8"
        />
      </div>
      <div class="set-actions">
        <button class="set-btn is-primary" type="submit" :disabled="updatingPassword">
          <span>{{ updatingPassword ? "Updating…" : "Update password" }}</span>
        </button>
      </div>
    </form>

    <PasskeysCard />

    <section class="set-card" aria-labelledby="danger-heading">
      <h2 id="danger-heading" class="set-card-title is-danger">Danger zone</h2>
      <p class="set-card-desc">These can't be undone.</p>

      <div class="set-row">
        <span>
          <span class="set-row-title">Reset game library</span>
          <span class="set-row-desc">Remove every game from your library, including ratings, statuses and notes.</span>
        </span>
        <button type="button" class="set-btn is-danger" :disabled="resettingLibrary" @click="showResetConfirm = true">
          <span>Reset library</span>
        </button>
      </div>

      <div class="set-row">
        <span>
          <span class="set-row-title">Delete account</span>
          <span class="set-row-desc">Permanently delete your account and all associated data.</span>
        </span>
        <button type="button" class="set-btn is-danger" :disabled="deletingAccount" @click="showDeleteConfirm = true">
          <span>Delete account</span>
        </button>
      </div>
    </section>

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
import PasskeysCard from "@/components/settings/PasskeysCard.vue";
import { CircleAlert } from "@lucide/vue";

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
      showSnackbar("A confirmation email has been sent to your new address.");
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
.set-row-desc {
  display: block;
  max-width: 420px;
}
</style>
