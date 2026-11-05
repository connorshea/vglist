<template>
  <div class="columns is-centered">
    <div class="column is-4">
      <h1 class="title">Resend Confirmation Email</h1>

      <div v-if="message" class="notification is-success" role="status">{{ message }}</div>

      <div v-if="errors.length" class="notification is-danger" role="alert">
        <ul>
          <li v-for="error in errors" :key="error">{{ error }}</li>
        </ul>
      </div>

      <form v-if="!message" @submit.prevent="handleSubmit">
        <div class="field">
          <label class="label" for="confirmation-resend-email">Email</label>
          <div class="control">
            <input
              id="confirmation-resend-email"
              v-model="email"
              class="input"
              type="email"
              placeholder="Email"
              autocomplete="email"
              required
            />
          </div>
        </div>

        <div class="field">
          <div class="control">
            <button class="button is-primary" type="submit" :disabled="isLoading">
              {{ isLoading ? "Sending..." : "Resend Confirmation Email" }}
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
import { useAuth } from "@/composables/useAuth";

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
