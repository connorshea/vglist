<template>
  <div class="columns is-centered">
    <div class="column is-4">
      <h1 class="title">Sign Up</h1>

      <div v-if="successMessage" class="notification is-success">{{ successMessage }}</div>
      <div v-if="errors.length" class="notification is-danger">
        <ul>
          <li v-for="error in errors" :key="error">{{ error }}</li>
        </ul>
      </div>

      <form v-if="!successMessage" @submit.prevent="handleSubmit">
        <div class="field">
          <label class="label">Username</label>
          <div class="control">
            <input
              v-model="username"
              class="input"
              type="text"
              placeholder="Username (3-20 characters)"
              required
            />
          </div>
        </div>

        <div class="field">
          <label class="label">Email</label>
          <div class="control">
            <input v-model="email" class="input" type="email" placeholder="Email" required />
          </div>
        </div>

        <div class="field">
          <label class="label">Password</label>
          <div class="control">
            <input
              v-model="password"
              class="input"
              type="password"
              placeholder="Password (minimum 8 characters)"
              required
            />
          </div>
        </div>

        <div class="field">
          <label class="label">Password Confirmation</label>
          <div class="control">
            <input
              v-model="passwordConfirmation"
              class="input"
              type="password"
              placeholder="Confirm password"
              required
            />
          </div>
        </div>

        <div class="field">
          <div class="control">
            <button class="button is-primary" type="submit" :disabled="isLoading">
              {{ isLoading ? "Creating account..." : "Sign Up" }}
            </button>
          </div>
        </div>

        <p>Already have an account? <router-link to="/login">Sign in</router-link></p>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { useAuth } from "@/composables/useAuth";

const { signUp } = useAuth();

const username = ref("");
const email = ref("");
const password = ref("");
const passwordConfirmation = ref("");
const errors = ref<string[]>([]);
const successMessage = ref("");
const isLoading = ref(false);

async function handleSubmit() {
  isLoading.value = true;
  errors.value = [];

  const result = await signUp(
    username.value,
    email.value,
    password.value,
    passwordConfirmation.value
  );

  if (result.success) {
    successMessage.value =
      "Account created successfully! Please check your email to confirm your account.";
  } else {
    errors.value = result.errors;
  }

  isLoading.value = false;
}
</script>
