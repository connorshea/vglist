<template>
  <div>
    <p v-if="loading && !data" class="set-card-desc">Loading profile…</p>

    <p v-if="error" class="set-error" role="alert">Failed to load profile: {{ error.message }}</p>

    <form v-if="data" class="set-card" aria-labelledby="profile-heading" @submit.prevent="saveProfile">
      <h2 id="profile-heading" class="set-card-title">Profile</h2>
      <p class="set-card-desc">How you appear to other people on vglist.</p>

      <div class="profile-avatar-row">
        <img v-if="avatarUrl" class="profile-avatar" :src="avatarUrl" alt="Your avatar" />
        <div v-else class="profile-avatar is-placeholder" aria-hidden="true">{{ avatarInitial }}</div>
        <div>
          <button
            v-if="avatarUrl"
            type="button"
            class="set-btn is-muted"
            :disabled="removingAvatar"
            @click="showRemoveAvatarConfirm = true"
          >
            Remove avatar
          </button>
          <p class="set-help profile-avatar-help">
            {{ avatarUrl ? "Removing your avatar replaces it with the default." : "You're using the default avatar." }}
          </p>
        </div>
      </div>

      <div class="set-field">
        <label for="bio">Bio</label>
        <textarea
          id="bio"
          v-model="bio"
          class="set-textarea"
          placeholder="Tell people about yourself…"
          aria-describedby="bio-help"
        ></textarea>
        <span id="bio-help" class="set-help">Shown under your name on your profile.</span>
      </div>

      <fieldset class="set-field">
        <legend class="set-label">Privacy</legend>
        <div class="profile-seg">
          <label class="profile-seg-btn" :class="{ 'is-active': privacy === 'PUBLIC_ACCOUNT' }">
            <input v-model="privacy" type="radio" name="privacy" value="PUBLIC_ACCOUNT" />
            <Globe :size="14" :stroke-width="2" aria-hidden="true" />
            Public
          </label>
          <label class="profile-seg-btn" :class="{ 'is-active': privacy === 'PRIVATE_ACCOUNT' }">
            <input v-model="privacy" type="radio" name="privacy" value="PRIVATE_ACCOUNT" />
            <Lock :size="14" :stroke-width="2" aria-hidden="true" />
            Private
          </label>
        </div>
        <span class="set-help">
          Private hides your library, favorites and activity. Your username and avatar stay visible.
        </span>
      </fieldset>

      <label class="set-switch">
        <input v-model="hideDaysPlayed" type="checkbox" role="switch" />
        Hide days played on my profile
      </label>

      <p v-if="saveError" class="set-error" role="alert">{{ saveError }}</p>

      <div class="set-actions">
        <button type="submit" class="set-btn is-primary" :disabled="saving">
          {{ saving ? "Saving…" : "Save changes" }}
        </button>
      </div>
    </form>

    <ConfirmDialog
      v-model="showRemoveAvatarConfirm"
      title="Remove your avatar?"
      confirm-label="Remove avatar"
      loading-label="Removing…"
      :loading="removingAvatar"
      @confirm="removeAvatar"
    >
      Your avatar will be removed and replaced with the default.
    </ConfirmDialog>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { Globe, Lock } from "@lucide/vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";
import { useQuery, useMutation } from "@/composables/useGraphQL";
import { useSnackbar } from "@/composables/useSnackbar";
import { REMOVE_USER_AVATAR } from "@/graphql/mutations/users";
import { UPDATE_USER } from "@/graphql/mutations/users-settings";
import { GET_CURRENT_USER_PROFILE } from "@/graphql/queries/users";
import type {
  GetCurrentUserProfileQuery,
  RemoveUserAvatarMutation,
  UpdateUserMutation,
  UserPrivacy
} from "@/types/graphql";
import { extractGqlError } from "@/utils/graphql-errors";

const bio = ref("");
const privacy = ref<UserPrivacy>("PUBLIC_ACCOUNT");
const hideDaysPlayed = ref(false);
const avatarUrl = ref<string | null>(null);
const saveError = ref("");
const { show: showSnackbar } = useSnackbar();

const { data, loading, error } = useQuery<GetCurrentUserProfileQuery>(GET_CURRENT_USER_PROFILE);

watch(
  data,
  (val) => {
    if (val?.currentUser) {
      bio.value = val.currentUser.bio ?? "";
      privacy.value = val.currentUser.privacy ?? "PUBLIC_ACCOUNT";
      hideDaysPlayed.value = val.currentUser.hideDaysPlayed ?? false;
      avatarUrl.value = val.currentUser.avatarUrl ?? null;
    }
  },
  { immediate: true }
);

const avatarInitial = computed(() => data.value?.currentUser?.username.charAt(0).toUpperCase() ?? "");

const { mutate, loading: saving } = useMutation<UpdateUserMutation>(UPDATE_USER);

async function saveProfile() {
  saveError.value = "";

  try {
    const response = await mutate({
      bio: bio.value,
      privacy: privacy.value,
      hideDaysPlayed: hideDaysPlayed.value
    });

    const errors = response?.updateUser?.errors;
    if (errors && errors.length > 0) {
      saveError.value = errors.join(", ");
    } else {
      showSnackbar("Profile updated successfully.");
    }
  } catch (e) {
    saveError.value = extractGqlError(e);
  }
}

const showRemoveAvatarConfirm = ref(false);
const { mutate: removeAvatarMutate, loading: removingAvatar } =
  useMutation<RemoveUserAvatarMutation>(REMOVE_USER_AVATAR);

async function removeAvatar() {
  const userId = data.value?.currentUser?.id;
  if (!userId) return;

  try {
    await removeAvatarMutate({ userId });
    avatarUrl.value = null;
    showRemoveAvatarConfirm.value = false;
    showSnackbar("Your avatar has been removed.");
  } catch (e) {
    showSnackbar(`Failed to remove avatar: ${extractGqlError(e)}`, "error");
  }
}
</script>

<style scoped>
.profile-avatar-row {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 24px;
}

.profile-avatar {
  width: 72px;
  height: 72px;
  border-radius: 18px;
  object-fit: cover;
  flex-shrink: 0;
}

.profile-avatar.is-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--p-100);
  color: var(--p-700);
  font-size: 28px;
  font-weight: 600;
}

.profile-avatar-help {
  margin: 6px 0 0;
}

fieldset.set-field {
  border: 0;
  padding: 0;
  min-width: 0;
}

fieldset.set-field > legend {
  padding: 0;
  margin-bottom: 6px;
}

.profile-seg {
  display: inline-flex;
  width: fit-content;
  padding: 3px;
  gap: 2px;
  border-radius: var(--radius-md);
  background: var(--color-bg-subtle);
}

.profile-seg-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 7px 16px;
  border-radius: var(--radius-sm);
  font-size: 13px;
  color: var(--color-text-secondary);
  cursor: pointer;
}

.profile-seg-btn.is-active {
  background: var(--color-surface);
  color: var(--color-text-primary);
  font-weight: 500;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.08);
}

/* Visually hidden, but still focusable with arrow keys like any radio group. */
.profile-seg-btn input {
  position: absolute;
  opacity: 0;
  width: 1px;
  height: 1px;
  pointer-events: none;
}

.profile-seg-btn:has(input:focus-visible) {
  outline: 2px solid var(--color-accent);
  outline-offset: 1px;
}

@media (prefers-color-scheme: dark) {
  .profile-avatar.is-placeholder {
    background: color-mix(in srgb, var(--p-300) 18%, transparent);
    color: var(--p-200);
  }
}
</style>
