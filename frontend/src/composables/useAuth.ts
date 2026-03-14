import { useAuthStore } from "@/stores/auth";
import { useRouter } from "vue-router";
import { gqlClient } from "@/graphql/client";
import { SIGN_IN, SIGN_UP, REQUEST_PASSWORD_RESET } from "@/graphql/mutations/auth";
import { useSnackbar } from "@/composables/useSnackbar";

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
      return { success: false, errors: [e instanceof Error ? e.message : "Sign in failed"] };
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
      return { success: false, errors: [e instanceof Error ? e.message : "Sign up failed"] };
    }
  }

  async function requestPasswordReset(email: string) {
    const data = await gqlClient.request<{
      requestPasswordReset: { message: string };
    }>(REQUEST_PASSWORD_RESET, { email });

    return data.requestPasswordReset.message;
  }

  function signOut() {
    authStore.clearAuth();
    router.push("/");
    const { show } = useSnackbar();
    show("You have been signed out.", "success");
  }

  return {
    signIn,
    signUp,
    signOut,
    requestPasswordReset
  };
}
