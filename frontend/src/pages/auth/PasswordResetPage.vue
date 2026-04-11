<template>
  <div class="columns is-centered">
    <div class="column is-4">
      <h1 class="title">Reset Password</h1>

      <div v-if="message" class="notification is-success">{{ message }}</div>

      <form v-if="!message" @submit.prevent="handleSubmit">
        <div class="field">
          <label class="label">Email</label>
          <div class="control">
            <input v-model="email" class="input" type="email" placeholder="Email" required />
          </div>
        </div>

        <div class="field">
          <div class="control">
            <button class="button is-primary" type="submit" :disabled="isLoading">
              {{ isLoading ? "Sending..." : "Send Reset Instructions" }}
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
