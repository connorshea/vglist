<template>
  <AuthLayout>
    <!-- After a passkey sign-in, confirm it worked before moving on. -->
    <div v-if="passkeySignedIn" class="auth-success" role="status">
      <span class="auth-success-icon" aria-hidden="true">
        <Check :size="28" :stroke-width="2.5" />
      </span>
      <h1 ref="successHeading" tabindex="-1">You're signed in</h1>
      <p class="auth-sub">
        Your passkey worked{{ passkeySignedIn.username ? `. Welcome back, ${passkeySignedIn.username}!` : "!" }}
      </p>
      <p class="auth-status">
        {{ redirectTarget === "/" ? "Taking you to vglist…" : "Taking you back to where you were…" }}
      </p>
    </div>

    <template v-else>
      <h1>Sign in</h1>
      <p class="auth-sub">New here? <router-link to="/signup" class="auth-link">Create an account</router-link></p>

      <div v-if="errors.length" class="notification is-danger" role="alert">
        <ul>
          <li v-for="error in errors" :key="error">{{ error }}</li>
        </ul>
      </div>

      <div v-if="passkeyError" class="auth-alert" role="alert">
        <CircleAlert :size="16" :stroke-width="2" aria-hidden="true" />
        <span>
          <b>That passkey didn't work.</b>
          {{ passkeyError }} Try again, or sign in with your email and password.
        </span>
      </div>

      <form @submit.prevent="handleSubmit">
        <div class="auth-field">
          <label for="login-email">Email</label>
          <!-- "webauthn" lets the browser offer passkeys in this field's autofill. -->
          <input
            id="login-email"
            v-model="email"
            class="auth-input"
            type="email"
            autocomplete="username webauthn"
            required
          />
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

      <template v-if="passkeysSupported">
        <div class="auth-or">or</div>
        <button
          class="auth-passkey"
          type="button"
          :disabled="passkeyWaiting"
          aria-describedby="passkey-status"
          @click="handlePasskeyButton"
        >
          <LoaderCircle v-if="passkeyWaiting" class="auth-spin" :size="18" :stroke-width="2" aria-hidden="true" />
          <KeyRound v-else :size="18" :stroke-width="2" aria-hidden="true" />
          {{ passkeyWaiting ? "Waiting for your passkey…" : "Sign in with a passkey" }}
        </button>
        <p id="passkey-status" class="auth-status" role="status">
          <template v-if="passkeyWaiting">Finish in your browser's prompt, or cancel it to use your password.</template>
        </p>
      </template>

      <div class="auth-footer">
        <router-link to="/confirmation/resend" class="auth-link">Didn't get a confirmation email?</router-link>
      </div>
    </template>
  </AuthLayout>
</template>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from "vue";
import { useRouter, useRoute } from "vue-router";
import {
  browserSupportsWebAuthn,
  browserSupportsWebAuthnAutofill,
  WebAuthnAbortService
} from "@simplewebauthn/browser";
import { Check, CircleAlert, KeyRound, LoaderCircle } from "@lucide/vue";
import { useAuth, type PasskeySignInResult } from "@/composables/useAuth";
import AuthLayout from "@/components/auth/AuthLayout.vue";

// The server's passkey challenges expire after five minutes, so the pending
// autofill request is swapped for a fresh one a little before that.
const AUTOFILL_REFRESH_MS = 4 * 60 * 1000;

// How long the "You're signed in" confirmation shows after a passkey sign-in
// before moving on, so the jump to the next page isn't abrupt.
const PASSKEY_SUCCESS_DELAY_MS = 2000;

const router = useRouter();
const route = useRoute();
const { signIn, signInWithPasskey } = useAuth();

const email = ref("");
const password = ref("");
const errors = ref<string[]>([]);
const isLoading = ref(false);

const passkeysSupported = browserSupportsWebAuthn();
const passkeyWaiting = ref(false);
const passkeyError = ref("");
let autofillTimer: ReturnType<typeof setTimeout> | undefined;
let redirectTimer: ReturnType<typeof setTimeout> | undefined;
const passkeySignedIn = ref<{ username: string } | null>(null);
const successHeading = ref<HTMLElement | null>(null);
let unmounted = false;

const redirectTarget = computed(() => {
  const redirect = route.query.redirect as string;
  // Only allow relative paths to prevent open redirect attacks.
  return redirect && redirect.startsWith("/") && !redirect.startsWith("//") ? redirect : "/";
});

function redirectAfterSignIn() {
  clearTimeout(redirectTimer);
  router.push(redirectTarget.value);
}

async function handleSubmit() {
  isLoading.value = true;
  errors.value = [];
  passkeyError.value = "";

  const result = await signIn(email.value, password.value);

  if (result.success) {
    redirectAfterSignIn();
  } else {
    errors.value = result.errors;
  }

  isLoading.value = false;
}

// A cancelled prompt is silent: the user can just try again or use their
// password. Anything else shows the "That passkey didn't work" alert.
function handlePasskeyResult(result: PasskeySignInResult) {
  if (result.status === "success") {
    clearTimeout(autofillTimer);
    passkeySignedIn.value = { username: result.username };
    redirectTimer = setTimeout(redirectAfterSignIn, PASSKEY_SUCCESS_DELAY_MS);
    // The button that had focus is gone, so move focus to the confirmation.
    void nextTick(() => successHeading.value?.focus());
  } else if (result.status === "error") {
    errors.value = [];
    passkeyError.value = result.errors.join(" ");
  }
}

// Conditional UI: wait in the background for the user to pick a passkey from
// the email field's autofill.
async function startAutofill() {
  clearTimeout(autofillTimer);
  if (unmounted || !(await browserSupportsWebAuthnAutofill())) return;

  autofillTimer = setTimeout(() => void startAutofill(), AUTOFILL_REFRESH_MS);
  const result = await signInWithPasskey({ useBrowserAutofill: true });
  if (unmounted) return;

  // The options request or the browser's WebAuthn call failed before the
  // user did anything. Stay quiet (the button and password still work) and
  // don't retry straight away, which would loop and burn the sign-in rate
  // limit. A failed options request is retried by the refresh timer; a
  // browser failure won't fix itself, so give up on autofill.
  if (result.status === "error" && result.stage !== "verify") {
    if (result.stage === "browser") clearTimeout(autofillTimer);
    return;
  }

  handlePasskeyResult(result);
  // The user picked a passkey the server rejected: wait for another pick.
  if (result.status === "error") void startAutofill();
}

async function handlePasskeyButton() {
  clearTimeout(autofillTimer);
  passkeyError.value = "";
  passkeyWaiting.value = true;

  // This aborts the pending autofill request, which then resolves as cancelled.
  const result = await signInWithPasskey();
  if (unmounted) return;

  passkeyWaiting.value = false;
  handlePasskeyResult(result);
  if (result.status !== "success") void startAutofill();
}

onMounted(() => {
  if (passkeysSupported) void startAutofill();
});

onBeforeUnmount(() => {
  unmounted = true;
  clearTimeout(autofillTimer);
  clearTimeout(redirectTimer);
  if (passkeysSupported) WebAuthnAbortService.cancelCeremony();
});
</script>

<style scoped>
/* The check draws itself once AuthLayout's circle has popped in. The path is
   inside the Lucide component, so it needs :deep(). Its length is about 23. */
.auth-success-icon :deep(path) {
  stroke-dasharray: 24;
  stroke-dashoffset: 24;
  animation: draw-check 0.4s 0.25s ease-out forwards;
}

@keyframes draw-check {
  to {
    stroke-dashoffset: 0;
  }
}

@media (prefers-reduced-motion: reduce) {
  .auth-success-icon :deep(path) {
    animation: none;
    stroke-dashoffset: 0;
  }
}
</style>
