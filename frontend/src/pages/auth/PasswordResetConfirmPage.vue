<template>
  <div class="columns is-centered">
    <div class="column is-4">
      <h1 class="title">Set New Password</h1>

      <div v-if="message" class="notification is-success">
        {{ message }}
        <p class="mt-2"><router-link to="/login">Sign in</router-link></p>
      </div>

      <div v-if="errors.length" class="notification is-danger">
        <ul>
          <li v-for="error in errors" :key="error">{{ error }}</li>
        </ul>
      </div>

      <form v-if="!message" @submit.prevent="handleSubmit">
        <div class="field">
          <label class="label">New Password</label>
          <div class="control">
            <input v-model="password" class="input" type="password" placeholder="New password" required minlength="8" />
          </div>
        </div>

        <div class="field">
          <label class="label">Confirm Password</label>
          <div class="control">
            <input
              v-model="passwordConfirmation"
              class="input"
              type="password"
              placeholder="Confirm password"
              required
              minlength="8"
            />
          </div>
        </div>

        <div class="field">
          <div class="control">
            <button class="button is-primary" type="submit" :disabled="isLoading">
              {{ isLoading ? "Resetting..." : "Reset Password" }}
            </button>
          </div>
        </div>

        <p><router-link to="/login">Back to Sign In</router-link></p>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { useRoute } from "vue-router";
import { useAuth } from "@/composables/useAuth";

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
