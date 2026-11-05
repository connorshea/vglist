<template>
  <AuthLayout>
    <h1>Sign in</h1>
    <p class="auth-sub">New to vglist? <router-link to="/signup" class="auth-link">Create an account</router-link></p>

    <div v-if="errors.length" class="notification is-danger" role="alert">
      <ul>
        <li v-for="error in errors" :key="error">{{ error }}</li>
      </ul>
    </div>

    <form @submit.prevent="handleSubmit">
      <div class="auth-field">
        <label for="login-email">Email</label>
        <input id="login-email" v-model="email" class="auth-input" type="email" autocomplete="email" required />
      </div>

      <div class="auth-field">
        <div class="auth-label-row">
          <label for="login-password">Password</label>
          <router-link to="/password/reset" class="auth-link auth-link-small">Forgot your password?</router-link>
        </div>
        <input
          id="login-password"
          v-model="password"
          class="auth-input"
          type="password"
          autocomplete="current-password"
          required
        />
      </div>

      <button class="auth-submit" type="submit" :disabled="isLoading">
        {{ isLoading ? "Signing in..." : "Sign in" }}
      </button>
    </form>

    <div class="auth-footer">
      <router-link to="/confirmation/resend" class="auth-link">Didn't get a confirmation email?</router-link>
    </div>
  </AuthLayout>
</template>
<script setup lang="ts">
import { ref } from "vue";
import { useRouter, useRoute } from "vue-router";
import { useAuth } from "@/composables/useAuth";
import AuthLayout from "@/components/auth/AuthLayout.vue";

const router = useRouter();
const route = useRoute();
const { signIn } = useAuth();

const email = ref("");
const password = ref("");
const errors = ref<string[]>([]);
const isLoading = ref(false);

async function handleSubmit() {
  isLoading.value = true;
  errors.value = [];

  const result = await signIn(email.value, password.value);

  if (result.success) {
    const redirect = route.query.redirect as string;
    // Only allow relative paths to prevent open redirect attacks.
    const safeRedirect = redirect && redirect.startsWith("/") && !redirect.startsWith("//") ? redirect : "/";
    router.push(safeRedirect);
  } else {
    errors.value = result.errors;
  }

  isLoading.value = false;
}
</script>
