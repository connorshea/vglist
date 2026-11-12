import { gqlClient } from "@/graphql/client";
import { GET_CURRENT_USER_AVATAR } from "@/graphql/queries/users";
import { useAuthStore } from "@/stores/auth";
import type { GetCurrentUserAvatarQuery } from "@/types/graphql";

// How long a fetched avatar is trusted before the navbar checks it again. The
// avatar only changes from Settings (which refreshes it straight away), so
// this only matters for a change made on another device.
export const AVATAR_REFRESH_INTERVAL_MS = 60 * 60 * 1000;

// Load the signed-in user's avatar into the auth store, so the navbar can
// show it. Errors are ignored: the navbar falls back to the user's initial.
//
// The navbar calls this on every full page load, alongside the page's own
// queries. To keep it out of that burst, it's skipped when the stored avatar
// was checked within the last AVATAR_REFRESH_INTERVAL_MS, unless `force` is
// set (e.g. right after uploading a new avatar).
export async function refreshCurrentUserAvatar({ force = false }: { force?: boolean } = {}): Promise<void> {
  const authStore = useAuthStore();
  if (!authStore.isAuthenticated) {
    return;
  }

  const checkedAt = authStore.user?.avatarCheckedAt;
  if (!force && checkedAt !== undefined && Date.now() - checkedAt < AVATAR_REFRESH_INTERVAL_MS) {
    return;
  }

  try {
    const data = await gqlClient.request<GetCurrentUserAvatarQuery>(GET_CURRENT_USER_AVATAR);
    authStore.updateUser({ avatarUrl: data.currentUser?.avatarUrl ?? null, avatarCheckedAt: Date.now() });
  } catch {
    // Keep whatever avatar we already had.
  }
}
