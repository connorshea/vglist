import { gqlClient } from "@/graphql/client";
import { GET_CURRENT_USER_AVATAR } from "@/graphql/queries/users";
import { useAuthStore } from "@/stores/auth";
import type { GetCurrentUserAvatarQuery } from "@/types/graphql";

// Load the signed-in user's avatar into the auth store, so the navbar can
// show it. Errors are ignored: the navbar falls back to the user's initial.
export async function refreshCurrentUserAvatar(): Promise<void> {
  const authStore = useAuthStore();
  if (!authStore.isAuthenticated) return;

  try {
    const data = await gqlClient.request<GetCurrentUserAvatarQuery>(GET_CURRENT_USER_AVATAR);
    authStore.updateUser({ avatarUrl: data.currentUser?.avatarUrl ?? null });
  } catch {
    // Keep whatever avatar we already had.
  }
}
