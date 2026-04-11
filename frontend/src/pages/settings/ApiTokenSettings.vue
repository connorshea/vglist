<template>
  <div>
    <h2 class="title is-4">API Token</h2>

    <p class="mb-4">Reset your API token. This will invalidate your current token and generate a new one.</p>

    <div v-if="resetError" class="notification is-danger">
      <p>{{ resetError }}</p>
    </div>

    <div v-if="newToken" class="notification is-success is-light">
      <p class="mb-2"><strong>Your new API token:</strong></p>
      <code class="token-display">{{ newToken }}</code>
      <p class="mt-2 is-size-7 has-text-dark">
        Make sure to copy this token now. You will not be able to see it again.
      </p>
    </div>

    <button class="button is-warning" :disabled="resetting" @click="showConfirm = true">Reset API Token</button>

    <ConfirmDialog
      v-model="showConfirm"
      title="Reset API token?"
      confirm-label="Reset token"
      loading-label="Resetting…"
      :loading="resetting"
      @confirm="resetToken"
    >
      <template #icon>
        <KeyRound :size="22" :stroke-width="1.8" />
      </template>
      Your current API token will be <strong>permanently invalidated</strong>. Any applications using it will stop
      working.
    </ConfirmDialog>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { useMutation } from "@/composables/useGraphQL";
import { RESET_API_TOKEN } from "@/graphql/mutations/users-settings";
import { extractGqlError } from "@/utils/graphql-errors";
import ConfirmDialog from "@/components/ConfirmDialog.vue";
import { KeyRound } from "lucide-vue-next";
interface ResetApiTokenResult {
  resetApiToken?: {
    apiToken?: string | null;
    errors: string[];
  } | null;
}

const newToken = ref("");
const resetError = ref("");
const showConfirm = ref(false);

const { mutate, loading: resetting } = useMutation<ResetApiTokenResult>(RESET_API_TOKEN);

async function resetToken() {
  resetError.value = "";
  newToken.value = "";

  try {
    const response = await mutate();
    const result = response?.resetApiToken;

    if (result?.errors && result.errors.length > 0) {
      resetError.value = result.errors.join(", ");
    } else if (result?.apiToken) {
      newToken.value = result.apiToken;
    }
  } catch (e) {
    resetError.value = extractGqlError(e);
  } finally {
    showConfirm.value = false;
  }
}
</script>

<style scoped>
.token-display {
  display: block;
  padding: 0.5rem 0.75rem;
  background-color: var(--bulma-scheme-main, #fff);
  border: 1px solid var(--bulma-border, #dbdbdb);
  border-radius: 4px;
  font-size: 0.95rem;
  word-break: break-all;
  user-select: all;
}
</style>
