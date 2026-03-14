<template>
  <div class="columns is-centered">
    <div class="column is-4">
      <h1 class="title">Sign In</h1>

      <div v-if="errors.length" class="notification is-danger">
        <ul>
          <li v-for="error in errors" :key="error">{{ error }}</li>
        </ul>
      </div>

      <form @submit.prevent="handleSubmit">
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
              placeholder="Password"
              required
            />
          </div>
        </div>

        <div class="field">
          <div class="control">
            <button class="button is-primary" type="submit" :disabled="isLoading">
              {{ isLoading ? "Signing in..." : "Sign In" }}
            </button>
          </div>
        </div>

        <p>
          <router-link to="/password/reset">Forgot your password?</router-link>
        </p>
        <p>Don't have an account? <router-link to="/signup">Sign up</router-link></p>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { useRouter, useRoute } from "vue-router";
import { useAuth } from "@/composables/useAuth";

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
    router.push(redirect || "/");
  } else {
    errors.value = result.errors;
  }

  isLoading.value = false;
}
</script>
