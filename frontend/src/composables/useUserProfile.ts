import { inject, type ComputedRef, type InjectionKey } from "vue";
import type { GetUserProfileQuery } from "@/types/graphql";

export type ProfileUser = NonNullable<GetUserProfileQuery["user"]>;

// What the profile layout shares with the tab it's showing.
export interface UserProfileContext {
  user: ComputedRef<ProfileUser | null>;
  // Whether the signed-in user is looking at their own profile.
  isOwnProfile: ComputedRef<boolean>;
  // Refetch the header, e.g. after a tab changes a count it shows.
  refetch: () => Promise<void>;
}

export const USER_PROFILE_KEY: InjectionKey<UserProfileContext> = Symbol("userProfile");

// The profile layout's user, for the tabs rendered inside it.
export function useUserProfile(): UserProfileContext {
  const context = inject(USER_PROFILE_KEY);
  if (!context) {
    throw new Error("useUserProfile() must be called inside the user profile layout.");
  }
  return context;
}
