<template>
  <div class="profile-layout library-page">
    <div v-if="loading && !data" class="profile-message">
      <p>Loading…</p>
    </div>

    <div v-else-if="error" class="notification is-danger">
      <p>{{ error.message }}</p>
    </div>

    <template v-if="user">
      <header class="profile-header">
        <div class="profile-identity">
          <span class="profile-avatar">
            <img v-if="user.avatarUrl" :src="user.avatarUrl" alt="" />
            <span v-else aria-hidden="true">{{ user.username.charAt(0).toUpperCase() }}</span>
          </span>
          <div class="profile-identity-text">
            <h1 class="profile-name">
              {{ user.username }}
              <span v-if="user.role === 'ADMIN'" class="profile-role is-admin">Admin</span>
              <span v-else-if="user.role === 'MODERATOR'" class="profile-role is-mod">Mod</span>
            </h1>
            <p v-if="!isPrivate" class="profile-stats">{{ statsLine }}</p>
          </div>
        </div>

        <div v-if="isOwnProfile" class="profile-actions is-own">
          <router-link :to="{ name: 'settingsProfile' }" class="profile-button">
            <Pencil :size="14" aria-hidden="true" />
            Edit profile
          </router-link>
          <router-link :to="{ name: 'games' }" class="profile-button is-primary">
            <Plus :size="14" aria-hidden="true" />
            Add game
          </router-link>
        </div>
        <div v-else-if="canFollow || hasAdminActions" class="profile-actions">
          <router-link v-if="compareLink" :to="compareLink" class="profile-button">
            <GitCompareArrows :size="14" aria-hidden="true" />
            Compare libraries
          </router-link>
          <template v-if="canFollow">
            <button
              v-if="user.isFollowed"
              type="button"
              class="profile-button"
              :disabled="unfollowLoading"
              @click="showUnfollowConfirm = true"
            >
              <UserCheck :size="14" aria-hidden="true" />
              Following
            </button>
            <button v-else type="button" class="profile-button is-primary" :disabled="followLoading" @click="follow">
              <UserPlus :size="14" aria-hidden="true" />
              Follow
            </button>
          </template>

          <div v-if="hasAdminActions" ref="actionsMenu" class="profile-menu" @keydown.esc="closeActions">
            <button
              ref="actionsToggle"
              type="button"
              class="profile-button is-icon"
              aria-label="Moderation actions"
              aria-haspopup="menu"
              :aria-expanded="actionsOpen"
              @click="actionsOpen = !actionsOpen"
            >
              <Ellipsis :size="16" aria-hidden="true" />
            </button>
            <div v-if="actionsOpen" class="profile-menu-list" role="menu">
              <template v-if="canUpdateRole">
                <button
                  v-for="change in roleChangeOptions"
                  :key="change.role"
                  type="button"
                  role="menuitem"
                  @click="promptRoleChange(change)"
                >
                  {{ change.label }}
                </button>
              </template>
              <button
                v-if="canModerate && user.avatarUrl"
                type="button"
                role="menuitem"
                class="is-danger"
                @click="openDialog(showRemoveAvatarConfirm)"
              >
                Remove avatar
              </button>
              <button
                v-if="canBan && !user.banned"
                type="button"
                role="menuitem"
                class="is-danger"
                @click="openDialog(showBanConfirm)"
              >
                Ban user
              </button>
              <button
                v-if="canModerate && user.banned"
                type="button"
                role="menuitem"
                @click="openDialog(showUnbanConfirm)"
              >
                Unban user
              </button>
            </div>
          </div>
        </div>
      </header>

      <nav class="profile-tabs" aria-label="Profile sections">
        <router-link
          v-for="tab in tabs"
          :key="tab.label"
          :to="{ name: tab.route, params: { slug: user.slug } }"
          :class="{ 'is-active': tab.active }"
          :aria-current="tab.active ? 'page' : undefined"
        >
          {{ tab.label }}
          <span v-if="tab.count !== null" class="profile-tab-count">{{ tab.count.toLocaleString() }}</span>
        </router-link>
      </nav>

      <div v-if="user.banned" class="notification is-danger is-light profile-banned">This user has been banned.</div>

      <div v-if="isPrivate" class="profile-message">
        <p class="profile-message-title">This user's account is private.</p>
      </div>
      <router-view v-else />
    </template>

    <ConfirmDialog
      v-model="showBanConfirm.value"
      title="Ban user?"
      confirm-label="Ban user"
      loading-label="Banning…"
      :loading="banLoading"
      @confirm="ban"
    >
      <template #icon>
        <CircleAlert :size="22" :stroke-width="1.8" />
      </template>
      <strong>{{ user?.username }}</strong> will be banned and will no longer be able to access their account.
    </ConfirmDialog>

    <ConfirmDialog
      v-model="showUnbanConfirm.value"
      title="Unban user?"
      confirm-label="Unban user"
      loading-label="Unbanning…"
      :loading="unbanLoading"
      variant="primary"
      @confirm="unban"
    >
      <template #icon>
        <ShieldCheck :size="22" :stroke-width="1.8" />
      </template>
      <strong>{{ user?.username }}</strong> will regain access to their account.
    </ConfirmDialog>

    <ConfirmDialog
      v-model="showRoleConfirm.value"
      :title="roleConfirm.title"
      :confirm-label="roleConfirm.label"
      loading-label="Updating…"
      :loading="roleLoading"
      variant="primary"
      @confirm="changeRole"
    >
      <template #icon>
        <ShieldCheck :size="22" :stroke-width="1.8" />
      </template>
      <strong>{{ user?.username }}</strong> {{ roleConfirm.description }}
    </ConfirmDialog>

    <ConfirmDialog
      v-model="showRemoveAvatarConfirm.value"
      title="Remove avatar?"
      confirm-label="Remove avatar"
      loading-label="Removing…"
      :loading="removeAvatarLoading"
      @confirm="removeAvatar"
    >
      <template #icon>
        <CircleAlert :size="22" :stroke-width="1.8" />
      </template>
      <strong>{{ user?.username }}</strong
      >'s avatar will be removed and replaced with the default.
    </ConfirmDialog>

    <ConfirmDialog
      v-model="showUnfollowConfirm"
      title="Unfollow user?"
      confirm-label="Unfollow"
      loading-label="Unfollowing…"
      :loading="unfollowLoading"
      @confirm="unfollow"
    >
      <template #icon>
        <UserMinus :size="22" :stroke-width="1.8" />
      </template>
      You will no longer see <strong>{{ user?.username }}</strong
      >'s activity in your feed.
    </ConfirmDialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, provide, reactive, ref, watch } from "vue";
import { useRoute, useRouter, type RouteRecordName } from "vue-router";
import {
  CircleAlert,
  Ellipsis,
  GitCompareArrows,
  Pencil,
  Plus,
  ShieldCheck,
  UserCheck,
  UserMinus,
  UserPlus
} from "@lucide/vue";
import { useMutation, useQuery } from "@/composables/useGraphQL";
import { usePageTitle } from "@/composables/usePageTitle";
import { useSnackbar } from "@/composables/useSnackbar";
import { USER_PROFILE_KEY } from "@/composables/useUserProfile";
import { useAuthStore } from "@/stores/auth";
import { GET_USER_PROFILE } from "@/graphql/queries/users";
import {
  BAN_USER,
  FOLLOW_USER,
  REMOVE_USER_AVATAR,
  UNBAN_USER,
  UNFOLLOW_USER,
  UPDATE_USER_ROLE
} from "@/graphql/mutations/users";
import type { GetUserProfileQuery } from "@/types/graphql";
import ConfirmDialog from "@/components/ConfirmDialog.vue";
import { roleChanges, type RoleChange } from "@/utils/user-roles";
import "@/assets/stylesheets/library.scss";

const route = useRoute();
const router = useRouter();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const slug = computed(() => ("slug" in route.params ? route.params.slug : ""));

const { data, loading, error, refetch } = useQuery<GetUserProfileQuery>(GET_USER_PROFILE, {
  variables: () => ({ slug: slug.value })
});

watch([data, error, loading], () => {
  if (!loading.value && (error.value || (data.value && !data.value.user))) {
    void router.replace({ name: "notFound" });
  }
});

const user = computed(() => data.value?.user ?? null);

// "connor", "connor's Library", ... as on the old app.
const TAB_TITLES: Partial<Record<RouteRecordName, string>> = {
  userLibrary: "Library",
  userFavorites: "Favorites",
  userActivity: "Activity",
  userFollowers: "Followers",
  userFollowing: "Following"
};
usePageTitle(() => {
  const username = user.value?.username;
  if (!username) return null;
  const tab = route.name ? TAB_TITLES[route.name] : undefined;
  return tab ? `${username}'s ${tab}` : username;
});

const isOwnProfile = computed(
  () => authStore.isAuthenticated && user.value !== null && authStore.user?.id === user.value.id
);
const isPrivate = computed(() => user.value?.privacy === "PRIVATE_ACCOUNT" && !isOwnProfile.value);

provide(USER_PROFILE_KEY, { user, isOwnProfile, refetch });

// "412 games · 1,830h played · 56% completed · avg 78"
const statsLine = computed(() => {
  const stats = user.value?.libraryStatistics;
  if (!stats) return "";
  const parts = [`${stats.gamesCount.toLocaleString()} game${stats.gamesCount === 1 ? "" : "s"}`];
  if (stats.totalHoursPlayed > 0 && !user.value?.hideDaysPlayed) {
    parts.push(`${Math.round(stats.totalHoursPlayed).toLocaleString()}h played`);
  }
  if (stats.completionPercentage > 0) parts.push(`${stats.completionPercentage}% completed`);
  if (stats.averageRating !== null) parts.push(`avg ${Math.round(stats.averageRating)}`);
  return parts.join(" · ");
});

// ── Tabs ────────────────────────────────────────────────────────────────────
interface Tab {
  label: string;
  route: "user" | "userLibrary" | "userFavorites" | "userActivity" | "userFollowers";
  count: number | null;
  active: boolean;
}

function isRoute(...names: RouteRecordName[]): boolean {
  return route.name !== undefined && names.includes(route.name);
}

const tabs = computed<Tab[]>(() => {
  const counts = !isPrivate.value;
  return [
    { label: "Overview", route: "user", count: null, active: isRoute("user") },
    {
      label: "Library",
      route: "userLibrary",
      count: counts ? (user.value?.libraryStatistics.gamesCount ?? 0) : null,
      active: isRoute("userLibrary")
    },
    {
      label: "Favorites",
      route: "userFavorites",
      count: counts ? (user.value?.favoritedGames.totalCount ?? 0) : null,
      active: isRoute("userFavorites")
    },
    { label: "Activity", route: "userActivity", count: null, active: isRoute("userActivity") },
    {
      // Followers and following are one tab, with a toggle between the two.
      label: "Followers",
      route: "userFollowers",
      count: counts ? (user.value?.followers.totalCount ?? 0) : null,
      active: isRoute("userFollowers", "userFollowing")
    }
  ];
});

// ── Follow ──────────────────────────────────────────────────────────────────
const canFollow = computed(() => authStore.isAuthenticated && user.value !== null && !isOwnProfile.value);

// Compares the viewer's library (on the left) with this user's. Like
// UserPolicy#compare?, only admins can compare a private or banned user's
// library. (The policy also lets a private user's followees compare with them,
// but the profile doesn't know who they follow, and shows them the private
// account message anyway.)
const canCompare = computed(() => authStore.isAdmin || (!isPrivate.value && !user.value?.banned));
const compareLink = computed(() =>
  canFollow.value && canCompare.value && user.value && authStore.user
    ? { name: "userCompare" as const, params: { slug: authStore.user.slug, otherSlug: user.value.slug } }
    : null
);

const { mutate: followUser, loading: followLoading } = useMutation(FOLLOW_USER);
const { mutate: unfollowUser, loading: unfollowLoading } = useMutation(UNFOLLOW_USER);
const showUnfollowConfirm = ref(false);

async function follow() {
  if (!user.value) return;
  const { id, username } = user.value;
  try {
    await followUser({ userId: id });
    await refetch();
    showSnackbar(`You are now following ${username}.`);
  } catch {
    showSnackbar("Failed to follow user.", "error");
  }
}

async function unfollow() {
  if (!user.value) return;
  const { id, username } = user.value;
  try {
    await unfollowUser({ userId: id });
    showUnfollowConfirm.value = false;
    await refetch();
    showSnackbar(`You have unfollowed ${username}.`);
  } catch {
    showSnackbar("Failed to unfollow user.", "error");
  }
}

// ── Moderation ──────────────────────────────────────────────────────────────
const currentRole = computed(() => authStore.user?.role);
const canModerate = computed(
  () => canFollow.value && (currentRole.value === "ADMIN" || currentRole.value === "MODERATOR")
);
const canBan = computed(() => canModerate.value && (currentRole.value === "ADMIN" || user.value?.role === "MEMBER"));
const canUpdateRole = computed(() => canFollow.value && currentRole.value === "ADMIN");
const hasAdminActions = computed(() => canModerate.value || canUpdateRole.value);

const actionsOpen = ref(false);
const actionsMenu = ref<HTMLElement | null>(null);
const actionsToggle = ref<HTMLButtonElement | null>(null);

function closeActions() {
  if (!actionsOpen.value) return;
  actionsOpen.value = false;
  actionsToggle.value?.focus();
}

function closeActionsOnClickOutside(event: MouseEvent) {
  if (actionsMenu.value && event.target instanceof Node && !actionsMenu.value.contains(event.target)) {
    actionsOpen.value = false;
  }
}

onMounted(() => document.addEventListener("click", closeActionsOnClickOutside));
onBeforeUnmount(() => document.removeEventListener("click", closeActionsOnClickOutside));

// Each dialog's open state, in an object so the menu can open any of them.
const showBanConfirm = reactive({ value: false });
const showUnbanConfirm = reactive({ value: false });
const showRoleConfirm = reactive({ value: false });
const showRemoveAvatarConfirm = reactive({ value: false });

function openDialog(dialog: { value: boolean }) {
  actionsOpen.value = false;
  dialog.value = true;
}

const { mutate: banUser, loading: banLoading } = useMutation(BAN_USER);
const { mutate: unbanUser, loading: unbanLoading } = useMutation(UNBAN_USER);
const { mutate: updateUserRole, loading: roleLoading } = useMutation(UPDATE_USER_ROLE);
const { mutate: removeUserAvatar, loading: removeAvatarLoading } = useMutation(REMOVE_USER_AVATAR);

// Runs a moderation mutation, then closes its dialog and refreshes the header.
async function moderate(
  dialog: { value: boolean },
  action: () => Promise<unknown>,
  success: string,
  failure: string
): Promise<void> {
  try {
    await action();
    dialog.value = false;
    await refetch();
    showSnackbar(success, "success");
  } catch {
    showSnackbar(failure, "error");
  }
}

function ban() {
  if (!user.value) return;
  const { id, username } = user.value;
  void moderate(showBanConfirm, () => banUser({ userId: id }), `${username} has been banned.`, "Failed to ban user.");
}

function unban() {
  if (!user.value) return;
  const { id, username } = user.value;
  void moderate(
    showUnbanConfirm,
    () => unbanUser({ userId: id }),
    `${username} has been unbanned.`,
    "Failed to unban user."
  );
}

function removeAvatar() {
  if (!user.value) return;
  const { id } = user.value;
  void moderate(
    showRemoveAvatarConfirm,
    () => removeUserAvatar({ userId: id }),
    "Avatar removed.",
    "Failed to remove avatar."
  );
}

// Every role other than the user's current one, so admins can be demoted too.
const roleChangeOptions = computed(() => (user.value ? roleChanges(user.value.role) : []));
const pendingRole = ref<RoleChange | null>(null);

const roleConfirm = computed(() => pendingRole.value ?? { title: "", label: "", description: "", noun: "" });

function promptRoleChange(change: RoleChange) {
  pendingRole.value = change;
  openDialog(showRoleConfirm);
}

function changeRole() {
  if (!user.value || !pendingRole.value) return;
  const { id, username } = user.value;
  const { role, noun } = pendingRole.value;
  void moderate(
    showRoleConfirm,
    () => updateUserRole({ userId: id, role }),
    `${username} is now ${noun}.`,
    "Failed to update user role."
  );
}
</script>

<style scoped>
.profile-layout {
  padding-bottom: 64px;
}

/* ── Header ── */
.profile-header {
  display: flex;
  flex-wrap: wrap;
  gap: 12px 16px;
  align-items: center;
  justify-content: space-between;
}

.profile-identity {
  display: flex;
  gap: 14px;
  align-items: center;
  min-width: 0;
}

.profile-identity-text {
  min-width: 0;
}

.profile-avatar {
  display: flex;
  flex-shrink: 0;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 48px;
  overflow: hidden;
  border-radius: 12px;
  background: linear-gradient(135deg, var(--p-400), var(--p-300));
  color: #fff;
  font-size: 1.2rem;
  font-weight: 600;
}

.profile-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.profile-name {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 8px;
  align-items: center;
  margin: 0;
  color: var(--color-text-primary);
  font-size: 1.25rem;
  font-weight: 700;
  line-height: 1.2;
  overflow-wrap: anywhere;
}

.profile-role {
  padding: 2px 8px;
  border-radius: 999px;
  color: #fff;
  font-size: 0.6rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.profile-role.is-admin {
  background: var(--vglist-theme);
}

.profile-role.is-mod {
  background: #b45309;
}

.profile-stats {
  margin: 3px 0 0;
  color: var(--color-text-secondary);
  font-size: 0.8rem;
}

.profile-actions {
  display: flex;
  gap: 8px;
  align-items: center;
}

.profile-button {
  display: inline-flex;
  gap: 6px;
  align-items: center;
  justify-content: center;
  height: 36px;
  padding: 0 18px;
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius-pill);
  background: transparent;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 0.85rem;
  font-weight: 500;
  cursor: pointer;
}

.profile-button:hover {
  border-color: var(--color-accent);
  color: var(--color-accent);
}

.profile-button.is-primary {
  border-color: var(--vglist-theme);
  background: var(--vglist-theme);
  color: #fff;
}

.profile-button.is-primary:hover {
  border-color: var(--p-600);
  background: var(--p-600);
}

.profile-button.is-icon {
  width: 36px;
  padding: 0;
}

.profile-button:disabled {
  opacity: 0.6;
  cursor: default;
}

.profile-button:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

/* ── Moderation menu ── */
.profile-menu {
  position: relative;
}

.profile-menu-list {
  position: absolute;
  top: calc(100% + 6px);
  right: 0;
  z-index: 100;
  min-width: 180px;
  padding: 4px 0;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  background: var(--color-surface);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
}

.profile-menu-list button {
  display: block;
  width: 100%;
  padding: 8px 16px;
  border: 0;
  background: none;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 0.875rem;
  text-align: left;
  cursor: pointer;
}

.profile-menu-list button:hover,
.profile-menu-list button:focus-visible {
  outline: 0;
  background: var(--color-bg-subtle);
}

.profile-menu-list button.is-danger {
  color: var(--r-500);
}

/* ── Tabs ── */
.profile-tabs {
  display: flex;
  margin-top: 24px;
  overflow-x: auto;
  border-bottom: 1px solid var(--color-border);
  scrollbar-width: none;
}

.profile-tabs a {
  display: flex;
  flex-shrink: 0;
  gap: 6px;
  align-items: center;
  margin-bottom: -1px;
  padding: 10px 16px;
  border-bottom: 2px solid transparent;
  color: var(--color-text-secondary);
  font-size: 0.875rem;
}

.profile-tabs a:hover {
  color: var(--color-text-primary);
}

.profile-tabs a.is-active {
  border-bottom-color: var(--color-accent);
  color: var(--color-accent);
  font-weight: 500;
}

.profile-tabs a:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: -2px;
}

.profile-tab-count {
  color: var(--color-text-tertiary);
  font-size: 0.7rem;
}

.profile-banned {
  margin: 16px 0 0;
}

.profile-message {
  padding: 48px 0;
  color: var(--color-text-secondary);
  text-align: center;
}

.profile-message-title {
  color: var(--color-text-primary);
  font-weight: 600;
}

@media (max-width: 768px) {
  .profile-avatar {
    width: 44px;
    height: 44px;
    border-radius: 11px;
  }

  /* As on the library page before, there's no room for these on a phone.
     Settings are a tap away in the nav sheet, and games are added from the
     game's page. */
  .profile-actions.is-own {
    display: none;
  }

  .profile-tabs {
    margin-top: 16px;
    /* Run the tabs to the screen's edges, so they scroll edge to edge. */
    margin-right: -1.5rem;
    margin-left: -1.5rem;
    padding: 0 calc(1.5rem - 12px);
  }

  .profile-tabs a {
    padding: 10px 12px;
  }
}
</style>
