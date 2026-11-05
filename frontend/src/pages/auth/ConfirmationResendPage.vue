<template>
  <AuthLayout>
    <h1>Resend confirmation email</h1>
    <p class="auth-sub">Didn't get the email to confirm your account? We'll send you another one.</p>

    <div v-if="message" class="notification is-success" role="status">{{ message }}</div>

    <div v-if="errors.length" class="notification is-danger" role="alert">
      <ul>
        <li v-for="error in errors" :key="error">{{ error }}</li>
      </ul>
    </div>

    <form v-if="!message" @submit.prevent="handleSubmit">
      <div class="auth-field">
        <label for="confirmation-resend-email">Email</label>
        <input
          id="confirmation-resend-email"
          v-model="email"
          class="auth-input"
          type="email"
          autocomplete="email"
          required
        />
      </div>

      <button class="auth-submit" type="submit" :disabled="isLoading">
        {{ isLoading ? "Sending..." : "Resend confirmation email" }}
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

const { resendConfirmation } = useAuth();

const email = ref("");
const message = ref("");
const errors = ref<string[]>([]);
const isLoading = ref(false);

async function handleSubmit() {
  isLoading.value = true;
  errors.value = [];

  const result = await resendConfirmation(email.value);
  if (result.success) {
    message.value = result.message;
  } else {
    errors.value = result.errors;
  }

  isLoading.value = false;
}
</script>
