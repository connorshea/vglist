<template>
  <AuthLayout>
    <h1>Reset password</h1>
    <p class="auth-sub">Enter your email and we'll send you a link to set a new password.</p>

    <div v-if="message" class="notification is-success" role="status">{{ message }}</div>

    <form v-if="!message" @submit.prevent="handleSubmit">
      <div class="auth-field">
        <label for="password-reset-email">Email</label>
        <input
          id="password-reset-email"
          v-model="email"
          class="auth-input"
          type="email"
          autocomplete="email"
          required
        />
      </div>

      <button class="auth-submit" type="submit" :disabled="isLoading">
        {{ isLoading ? "Sending..." : "Send reset instructions" }}
      </button>
    </form>

    <div class="auth-footer">
      <router-link to="/login" class="auth-link">Back to sign in</router-link>
    </div>
  </AuthLayout>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { useAuth } from "@/composables/useAuth";
import AuthLayout from "@/components/auth/AuthLayout.vue";

const { requestPasswordReset } = useAuth();

const email = ref("");
const message = ref("");
const isLoading = ref(false);

async function handleSubmit() {
  isLoading.value = true;
  message.value = await requestPasswordReset(email.value);
  isLoading.value = false;
}
</script>
