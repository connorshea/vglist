<template>
  <AuthLayout>
    <h1>Create an account</h1>
    <p class="auth-sub">Already have an account? <router-link to="/login" class="auth-link">Sign in</router-link></p>

    <div v-if="successMessage" class="notification is-success" role="status">{{ successMessage }}</div>
    <div v-if="errors.length" class="notification is-danger" role="alert">
      <ul>
        <li v-for="error in errors" :key="error">{{ error }}</li>
      </ul>
    </div>

    <form v-if="!successMessage" @submit.prevent="handleSubmit">
      <div class="auth-field">
        <label for="signup-username">Username</label>
        <input
          id="signup-username"
          v-model="username"
          class="auth-input"
          type="text"
          placeholder="3 to 20 characters"
          autocomplete="username"
          required
        />
      </div>

      <div class="auth-field">
        <label for="signup-email">Email</label>
        <input id="signup-email" v-model="email" class="auth-input" type="email" autocomplete="email" required />
      </div>

      <div class="auth-field">
        <label for="signup-password">Password</label>
        <input
          id="signup-password"
          v-model="password"
          class="auth-input"
          type="password"
          placeholder="At least 8 characters"
          autocomplete="new-password"
          required
        />
      </div>

      <div class="auth-field">
        <label for="signup-password-confirmation">Confirm password</label>
        <input
          id="signup-password-confirmation"
          v-model="passwordConfirmation"
          class="auth-input"
          type="password"
          autocomplete="new-password"
          required
        />
      </div>

      <TurnstileWidget
        v-if="turnstileSiteKey"
        ref="turnstile"
        v-model="turnstileToken"
        :site-key="turnstileSiteKey"
        action="signup"
      />

      <button class="auth-submit" type="submit" :disabled="isLoading">
        {{ isLoading ? "Creating account..." : "Create account" }}
      </button>
    </form>
  </AuthLayout>
</template>

<script setup lang="ts">
import { ref, useTemplateRef } from "vue";
import { useAuth } from "@/composables/useAuth";
import AuthLayout from "@/components/auth/AuthLayout.vue";
import TurnstileWidget from "@/components/auth/TurnstileWidget.vue";

const { signUp } = useAuth();

const username = ref("");
const email = ref("");
const password = ref("");
const passwordConfirmation = ref("");
const errors = ref<string[]>([]);
const successMessage = ref("");
const isLoading = ref(false);

// Turnstile is on when a site key was baked into the build. The API rejects
// sign-ups without a valid token whenever its secret key is set.
const turnstileSiteKey = import.meta.env.VITE_TURNSTILE_SITE_KEY;
const turnstileToken = ref("");
const turnstile = useTemplateRef<InstanceType<typeof TurnstileWidget>>("turnstile");

async function handleSubmit() {
  errors.value = [];

  if (turnstileSiteKey && !turnstileToken.value) {
    errors.value = ["Please wait for the human verification check to finish, then try again."];
    return;
  }

  isLoading.value = true;

  const result = await signUp(
    username.value,
    email.value,
    password.value,
    passwordConfirmation.value,
    turnstileToken.value || undefined
  );

  if (result.success) {
    successMessage.value = "Account created successfully! Please check your email to confirm your account.";
  } else {
    errors.value = result.errors;
    // The server has spent the token, so get a fresh one for the next try.
    turnstile.value?.reset();
  }

  isLoading.value = false;
}
</script>
