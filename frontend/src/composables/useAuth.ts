import { useAuthStore } from "@/stores/auth";
import { useRouter } from "vue-router";
import { gqlClient } from "@/graphql/client";
import { SIGN_IN, SIGN_UP, REQUEST_PASSWORD_RESET } from "@/graphql/mutations/auth";
import { useSnackbar } from "@/composables/useSnackbar";
import { extractGqlError } from "@/utils/graphql-errors";

export function useAuth() {
  const authStore = useAuthStore();
  const router = useRouter();

  async function signIn(email: string, password: string) {
    try {
      const data = await gqlClient.request<{
        signIn: {
          token: string;
          userId: string;
          username: string;
          slug: string;
          role: string;
          errors: string[];
        };
      }>(SIGN_IN, { email, password });

      const result = data.signIn;
      if (result.errors.length > 0) {
        return { success: false, errors: result.errors };
      }

      authStore.setAuth(result.token, {
        id: result.userId,
        username: result.username,
        email,
        role: result.role.toUpperCase() as "MEMBER" | "MODERATOR" | "ADMIN",
        slug: result.slug
      });

      return { success: true, errors: [] as string[] };
    } catch (e) {
      return { success: false, errors: [extractGqlError(e)] };
    }
  }

  async function signUp(username: string, email: string, password: string, passwordConfirmation: string) {
    try {
      const data = await gqlClient.request<{
        signUp: { message: string | null; errors: string[] };
      }>(SIGN_UP, { username, email, password, passwordConfirmation });

      const result = data.signUp;
      if (result.errors.length > 0) {
        return { success: false, errors: result.errors };
      }

      return { success: true, errors: [] as string[] };
    } catch (e) {
      return { success: false, errors: [extractGqlError(e)] };
    }
  }

  async function requestPasswordReset(email: string) {
    const data = await gqlClient.request<{
      requestPasswordReset: { message: string };
    }>(REQUEST_PASSWORD_RESET, { email });

    return data.requestPasswordReset.message;
  }

  // Resend the email confirmation link (links expire after a few days).
  // Sent form-encoded rather than as JSON so Rack::Attack can read the email
  // and apply its per-address throttle on outgoing mail.
  async function resendConfirmation(email: string) {
    try {
      const response = await fetch(`${import.meta.env.VITE_API_URL}/users/confirmation`, {
        method: "POST",
        body: new URLSearchParams({ "user[email]": email })
      });

      if (response.ok) {
        return {
          success: true,
          message: "If that email needs confirming, a new confirmation link is on its way.",
          errors: [] as string[]
        };
      }

      // Devise returns `errors` as strings, but Rack::Attack's 429 returns
      // `error` (a string) alongside GraphQL-shaped `errors` objects, so
      // prefer `error` and only use `errors` entries that are strings.
      const data = (await response.json().catch(() => ({}))) as { error?: unknown; errors?: unknown };
      const stringErrors = Array.isArray(data.errors)
        ? data.errors.filter((error): error is string => typeof error === "string")
        : [];
      let errors = ["Couldn't send confirmation instructions."];
      if (typeof data.error === "string") {
        errors = [data.error];
      } else if (stringErrors.length > 0) {
        errors = stringErrors;
      }
      return { success: false, message: "", errors };
    } catch {
      return { success: false, message: "", errors: ["Couldn't send confirmation instructions."] };
    }
  }

  async function resetPassword(resetPasswordToken: string, password: string, passwordConfirmation: string) {
    try {
      const response = await fetch(`${import.meta.env.VITE_API_URL}/users/password`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          user: {
            reset_password_token: resetPasswordToken,
            password,
            password_confirmation: passwordConfirmation
          }
        })
      });

      const data = (await response.json()) as { message?: string; errors?: string[] };

      if (response.ok) {
        return { success: true, errors: [] as string[] };
      }
      return { success: false, errors: data.errors ?? ["Password reset failed."] };
    } catch (e) {
      return { success: false, errors: [extractGqlError(e)] };
    }
  }

  async function signOut() {
    // Revoke the token server-side before clearing local state.
    if (authStore.token) {
      try {
        await fetch(`${import.meta.env.VITE_API_URL}/api/auth/sign_out`, {
          method: "DELETE",
          headers: { Authorization: `Bearer ${authStore.token}` }
        });
      } catch {
        // Clear local state even if the server request fails.
      }
    }
    authStore.clearAuth();
    void router.push("/");
    const { show } = useSnackbar();
    show("You have been signed out.", "success");
  }

  return {
    signIn,
    signUp,
    signOut,
    requestPasswordReset,
    resendConfirmation,
    resetPassword
  };
}
