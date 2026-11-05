<template>
  <AuthLayout>
    <h1>Set a new password</h1>
    <p class="auth-sub">Choose a password with at least 8 characters.</p>

    <div v-if="message" class="notification is-success" role="status">
      {{ message }}
      <p class="mt-2"><router-link to="/login">Sign in</router-link></p>
    </div>

    <div v-if="errors.length" class="notification is-danger" role="alert">
      <ul>
        <li v-for="error in errors" :key="error">{{ error }}</li>
      </ul>
    </div>

    <form v-if="!message" @submit.prevent="handleSubmit">
      <div class="auth-field">
        <label for="password-reset-new">New password</label>
        <input
          id="password-reset-new"
          v-model="password"
          class="auth-input"
          type="password"
          autocomplete="new-password"
          required
          minlength="8"
        />
      </div>

      <div class="auth-field">
        <label for="password-reset-confirm">Confirm password</label>
        <input
          id="password-reset-confirm"
          v-model="passwordConfirmation"
          class="auth-input"
          type="password"
          autocomplete="new-password"
          required
          minlength="8"
        />
      </div>

      <button class="auth-submit" type="submit" :disabled="isLoading">
        {{ isLoading ? "Resetting..." : "Reset password" }}
      </button>
    </form>

    <div v-if="!message" class="auth-footer">
      <router-link to="/login" class="auth-link">Back to sign in</router-link>
    </div>
  </AuthLayout>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { useRoute } from "vue-router";
import { useAuth } from "@/composables/useAuth";
import AuthLayout from "@/components/auth/AuthLayout.vue";

const route = useRoute();
const { resetPassword } = useAuth();

const password = ref("");
const passwordConfirmation = ref("");
const errors = ref<string[]>([]);
const message = ref("");
const isLoading = ref(false);

async function handleSubmit() {
  isLoading.value = true;
  errors.value = [];

  const token = route.query.reset_password_token as string;
  if (!token) {
    errors.value = ["Missing password reset token."];
    isLoading.value = false;
    return;
  }

  const result = await resetPassword(token, password.value, passwordConfirmation.value);

  if (result.success) {
    message.value = "Your password has been reset successfully.";
  } else {
    errors.value = result.errors;
  }

  isLoading.value = false;
}
</script>
