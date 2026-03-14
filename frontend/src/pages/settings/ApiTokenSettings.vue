<template>
  <div>
    <h2 class="title is-4">API Token</h2>

    <p class="mb-4">
      Reset your API token. This will invalidate your current token and generate a new one.
    </p>

    <div v-if="resetError" class="notification is-danger">
      <p>{{ resetError }}</p>
    </div>

    <div v-if="newToken" class="notification is-success">
      <p class="mb-2"><strong>Your new API token:</strong></p>
      <code>{{ newToken }}</code>
      <p class="mt-2 has-text-grey is-size-7">
        Make sure to copy this token now. You will not be able to see it again.
      </p>
    </div>

    <button
      class="button is-warning"
      :class="{ 'is-loading': resetting }"
      :disabled="resetting"
      @click="resetToken"
    >
      Reset API Token
    </button>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { useMutation } from "@/composables/useGraphQL";
import { RESET_API_TOKEN } from "@/graphql/mutations/users-settings";
import type { ResetApiTokenMutation } from "@/types/graphql";

const newToken = ref("");
const resetError = ref("");

const { mutate, loading: resetting } = useMutation<ResetApiTokenMutation>(RESET_API_TOKEN);

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
    resetError.value = e instanceof Error ? e.message : "An unexpected error occurred.";
  }
}
</script>
