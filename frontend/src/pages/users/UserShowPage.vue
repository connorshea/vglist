<template>
  <section class="section">
    <div v-if="loading && !data" class="has-text-centered py-6">
      <p>Loading...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>{{ error.message }}</p>
    </div>

    <div v-if="user" class="user-profile">
      <!-- Profile Header -->
      <header class="profile-header">
        <div class="profile-header-left">
          <figure class="profile-avatar">
            <img v-if="user.avatarUrl" :src="user.avatarUrl" :alt="user.username" />
            <div v-else class="avatar-placeholder">
              <span>{{ user.username.charAt(0).toUpperCase() }}</span>
            </div>
          </figure>
          <div class="profile-info">
            <div class="profile-name-row">
              <h1 class="profile-name">{{ user.username }}</h1>
              <span v-if="user.role === 'ADMIN'" class="role-badge role-admin">Admin</span>
              <span v-else-if="user.role === 'MODERATOR'" class="role-badge role-mod">Mod</span>
            </div>
            <p v-if="user.bio" class="profile-bio">{{ user.bio }}</p>
            <p v-if="!isPrivateProfile" class="profile-stats-line">
              {{ gamePurchases.length }} games
              <template v-if="totalHoursPlayed > 0 && !user.hideDaysPlayed">
                · {{ totalHoursPlayed.toLocaleString() }}h played
              </template>
              <template v-if="completionPct > 0"> · {{ completionPct }}% completed </template>
              <template v-if="avgRating > 0"> · avg {{ avgRating }} </template>
            </p>
            <div class="profile-social">
              <router-link :to="`/users/${route.params.slug}/followers`" class="social-link">
                <strong>{{ user.followers.totalCount }}</strong> followers
              </router-link>
              <router-link :to="`/users/${route.params.slug}/following`" class="social-link">
                <strong>{{ user.following.totalCount }}</strong> following
              </router-link>
            </div>
          </div>
        </div>
        <div v-if="canFollowOrUnfollow || hasAdminActions" class="profile-header-right">
          <button
            v-if="canFollowOrUnfollow && user.isFollowed"
            class="follow-btn follow-btn-secondary"
            :disabled="unfollowLoading"
            @click="handleUnfollow"
          >
            Unfollow
          </button>
          <button
            v-else-if="canFollowOrUnfollow"
            class="follow-btn follow-btn-primary"
            :disabled="followLoading"
            @click="handleFollow"
          >
            Follow
          </button>

          <!-- Admin Actions dropdown -->
          <div v-if="hasAdminActions" class="actions-dropdown">
            <button class="actions-dropdown-toggle" @click="actionsOpen = !actionsOpen">
              Actions
              <span class="actions-caret">{{ actionsOpen ? "\u25B2" : "\u25BC" }}</span>
            </button>
            <div v-if="actionsOpen" class="actions-dropdown-menu">
              <button
                v-if="canUpdateRole && user.role !== 'MODERATOR'"
                class="actions-dropdown-item"
                @click="promptRoleChange('MODERATOR')"
              >
                Make moderator
              </button>
              <button
                v-if="canUpdateRole && user.role === 'MODERATOR'"
                class="actions-dropdown-item"
                @click="promptRoleChange('MEMBER')"
              >
                Demote to member
              </button>
              <button
                v-if="canUpdateRole && user.role !== 'ADMIN'"
                class="actions-dropdown-item"
                @click="promptRoleChange('ADMIN')"
              >
                Make admin
              </button>
              <button
                v-if="canRemoveAvatar && user.avatarUrl"
                class="actions-dropdown-item actions-dropdown-item-danger"
                @click="handleRemoveAvatar"
              >
                Remove avatar
              </button>
              <button
                v-if="canBan && !user.banned"
                class="actions-dropdown-item actions-dropdown-item-danger"
                @click="promptBan"
              >
                Ban user
              </button>
              <button v-if="canUnban && user.banned" class="actions-dropdown-item" @click="handleUnban">
                Unban user
              </button>
            </div>
          </div>
        </div>
      </header>

      <!-- Banned notice -->
      <div v-if="user.banned" class="notification is-danger is-light">This user has been banned.</div>

      <!-- Private account notice -->
      <div v-if="isPrivateProfile" class="private-notice">
        <p class="private-notice-text">This user's account is private.</p>
      </div>

      <template v-if="!isPrivateProfile">
        <!-- Favorited Games (horizontal scroll) -->
        <div v-if="favoritedGames.length" class="favorites-section">
          <h2 class="section-label">FAVORITES</h2>
          <div class="favorites-row">
            <router-link v-for="game in favoritedGames" :key="game.id" :to="`/games/${game.id}`" class="favorite-tile">
              <img v-if="game.coverUrl" :src="game.coverUrl" :alt="game.name" />
              <div v-else class="favorite-placeholder">
                <span>{{ gameInitials(game.name) }}</span>
              </div>
              <div class="favorite-name">{{ game.name }}</div>
            </router-link>
          </div>
        </div>

        <!-- Library Section -->
        <div class="library-section">
          <h2 class="section-label">LIBRARY</h2>

          <!-- Status filter pills -->
          <div class="status-pills">
            <button
              v-for="s in statuses"
              :key="s.key"
              class="status-pill"
              :class="{ 'is-active': activeStatus === s.key }"
              @click="activeStatus = s.key"
            >
              <span v-if="s.key !== 'all'" class="status-dot" :style="{ background: statusColor(s.key) }"></span>
              {{ s.label }}
              <span class="pill-count">{{ s.key === "all" ? gamePurchases.length : statusCount(s.key) }}</span>
            </button>
          </div>

          <!-- Search + sort row -->
          <div class="library-controls">
            <div class="library-search">
              <input v-model="search" type="text" placeholder="Search library..." class="input is-small" />
            </div>
            <div class="library-sort">
              <div class="select is-small">
                <select v-model="sortBy">
                  <option value="name">A → Z</option>
                  <option value="rating">Rating</option>
                  <option value="hours">Hours</option>
                </select>
              </div>
            </div>
            <span class="library-count">
              {{ filteredGames.length }} game{{ filteredGames.length !== 1 ? "s" : "" }}
            </span>
          </div>

          <!-- Empty state -->
          <div v-if="filteredGames.length === 0 && gamePurchases.length > 0" class="library-empty">
            <p class="library-empty-title">No games found</p>
            <p class="library-empty-sub">Try adjusting your filters</p>
          </div>

          <div v-else-if="gamePurchases.length === 0" class="library-empty">
            <p class="library-empty-title">No games in library yet</p>
          </div>

          <!-- Gallery Grid -->
          <div v-else class="gallery-grid">
            <router-link
              v-for="purchase in filteredGames"
              :key="purchase.id"
              :to="`/games/${purchase.game.id}`"
              class="gallery-tile"
            >
              <!-- Cover -->
              <img
                v-if="purchase.game.coverUrl"
                :src="purchase.game.coverUrl"
                :alt="purchase.game.name"
                class="gallery-cover"
              />
              <div v-else class="gallery-cover-placeholder">
                <span>{{ gameInitials(purchase.game.name) }}</span>
              </div>

              <!-- Rating badge -->
              <div v-if="purchase.rating !== null" class="gallery-rating" :class="ratingClass(purchase.rating ?? 0)">
                {{ purchase.rating }}
              </div>

              <!-- Status dot -->
              <div
                v-if="purchase.completionStatus"
                class="gallery-status-dot"
                :class="{ 'is-playing': purchase.completionStatus === 'IN_PROGRESS' }"
                :style="{ background: statusColor(purchase.completionStatus) }"
              ></div>

              <!-- Bottom gradient + name -->
              <div class="gallery-name-overlay">
                <p class="gallery-name">{{ purchase.game.name }}</p>
              </div>

              <!-- Hover overlay -->
              <div class="gallery-hover">
                <p class="gallery-hover-name">{{ purchase.game.name }}</p>
                <div class="gallery-hover-meta">
                  <span
                    v-if="purchase.completionStatus"
                    class="gallery-hover-status"
                    :style="{ background: statusColor(purchase.completionStatus) }"
                  >
                    {{ formatStatus(purchase.completionStatus) }}
                  </span>
                  <span v-if="purchase.hoursPlayed && !user.hideDaysPlayed" class="gallery-hover-hours">
                    {{ purchase.hoursPlayed }}h
                  </span>
                  <span v-if="purchase.rating !== null" class="gallery-hover-rating"> {{ purchase.rating }}/100 </span>
                </div>
              </div>
            </router-link>
          </div>
        </div>
      </template>
    </div>
    <!-- Ban confirmation dialog -->
    <ConfirmDialog
      v-model="showBanConfirm"
      title="Ban user?"
      confirm-label="Ban user"
      loading-label="Banning…"
      :loading="banLoading"
      @confirm="confirmBan"
    >
      <template #icon>
        <CircleAlert :size="22" :stroke-width="1.8" />
      </template>
      <strong>{{ user?.username }}</strong> will be banned and will no longer be able to access their account.
    </ConfirmDialog>

    <!-- Role change confirmation dialog -->
    <ConfirmDialog
      v-model="showRoleConfirm"
      :title="roleConfirmTitle"
      :confirm-label="roleConfirmLabel"
      :loading-label="roleConfirmLoadingLabel"
      :loading="roleLoading"
      variant="primary"
      @confirm="confirmRoleChange"
    >
      <template #icon>
        <ShieldCheck :size="22" :stroke-width="1.8" />
      </template>
      <strong>{{ user?.username }}</strong> {{ roleConfirmDescription }}
    </ConfirmDialog>
  </section>
</template>

<script setup lang="ts">
import { computed, ref, onMounted, onBeforeUnmount } from "vue";
import { useRoute } from "vue-router";
import { useQuery, useMutation } from "@/composables/useGraphQL";
import { useAuthStore } from "@/stores/auth";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_USER } from "@/graphql/queries/users";
import {
  FOLLOW_USER,
  UNFOLLOW_USER,
  BAN_USER,
  UNBAN_USER,
  UPDATE_USER_ROLE,
  REMOVE_USER_AVATAR
} from "@/graphql/mutations/users";
import type { GetUserQuery } from "@/types/graphql";
import ConfirmDialog from "@/components/ConfirmDialog.vue";
import { CircleAlert, ShieldCheck } from "lucide-vue-next";

const route = useRoute();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const { data, loading, error, refetch } = useQuery<GetUserQuery>(GET_USER, {
  variables: () => ({ slug: route.params.slug as string })
});

const user = computed(() => data.value?.user ?? null);
const gamePurchases = computed(() => user.value?.gamePurchases?.nodes ?? []);
const favoritedGames = computed(() => user.value?.favoritedGames?.nodes ?? []);

// Stats
const totalHoursPlayed = computed(() => gamePurchases.value.reduce((sum, p) => sum + (p.hoursPlayed ?? 0), 0));
const completedCount = computed(
  () =>
    gamePurchases.value.filter((p) => p.completionStatus === "COMPLETED" || p.completionStatus === "FULLY_COMPLETED")
      .length
);
const completionPct = computed(() =>
  gamePurchases.value.length ? Math.round((completedCount.value / gamePurchases.value.length) * 100) : 0
);
const avgRating = computed(() => {
  const rated = gamePurchases.value.filter((p) => p.rating !== null);
  return rated.length ? Math.round(rated.reduce((a, p) => a + (p.rating ?? 0), 0) / rated.length) : 0;
});

// Filters
const activeStatus = ref("all");
const search = ref("");
const sortBy = ref("name");

const statuses = [
  { key: "all", label: "All" },
  { key: "IN_PROGRESS", label: "Playing" },
  { key: "COMPLETED", label: "Completed" },
  { key: "FULLY_COMPLETED", label: "100%" },
  { key: "PAUSED", label: "Paused" },
  { key: "DROPPED", label: "Dropped" },
  { key: "UNPLAYED", label: "Unplayed" }
];

function statusCount(key: string): number {
  return gamePurchases.value.filter((p) => p.completionStatus === key).length;
}

const filteredGames = computed(() => {
  return gamePurchases.value
    .filter((p) => {
      if (activeStatus.value !== "all" && p.completionStatus !== activeStatus.value) return false;
      if (search.value && !p.game.name.toLowerCase().includes(search.value.toLowerCase())) return false;
      return true;
    })
    .sort((a, b) => {
      if (sortBy.value === "name") return a.game.name.localeCompare(b.game.name);
      if (sortBy.value === "rating") return (b.rating ?? 0) - (a.rating ?? 0);
      if (sortBy.value === "hours") return (b.hoursPlayed ?? 0) - (a.hoursPlayed ?? 0);
      return 0;
    });
});

// Status colors
const STATUS_COLORS: Record<string, string> = {
  IN_PROGRESS: "#3b82f6",
  COMPLETED: "#22c55e",
  FULLY_COMPLETED: "#16a34a",
  PAUSED: "#f59e0b",
  DROPPED: "#ef4444",
  UNPLAYED: "#a855f7",
  NOT_APPLICABLE: "#6b7280"
};

function statusColor(status: string): string {
  return STATUS_COLORS[status] ?? "#6b7280";
}

function ratingClass(rating: number): string {
  if (rating >= 90) return "rating-great";
  if (rating >= 75) return "rating-good";
  if (rating >= 60) return "rating-ok";
  return "rating-low";
}

function formatStatus(status: string): string {
  const labels: Record<string, string> = {
    IN_PROGRESS: "Playing",
    COMPLETED: "Completed",
    FULLY_COMPLETED: "100%",
    PAUSED: "Paused",
    DROPPED: "Dropped",
    UNPLAYED: "Unplayed",
    NOT_APPLICABLE: "N/A"
  };
  return labels[status] ?? status;
}

function gameInitials(name: string): string {
  return name
    .split(/[\s:]+/)
    .filter((w) => w.length > 0)
    .slice(0, 3)
    .map((w) => w[0].toUpperCase())
    .join("");
}

// Privacy: hide library details if the profile is private and the viewer is not the owner.
const isOwnProfile = computed(() => {
  return authStore.isAuthenticated && user.value !== null && authStore.user?.id === user.value.id;
});
const isPrivateProfile = computed(() => {
  return user.value?.privacy === "PRIVATE_ACCOUNT" && !isOwnProfile.value;
});

// Follow / Unfollow
const canFollowOrUnfollow = computed(() => {
  return authStore.isAuthenticated && user.value && authStore.user?.id !== user.value.id;
});

const { mutate: followUser, loading: followLoading } = useMutation(FOLLOW_USER);
const { mutate: unfollowUser, loading: unfollowLoading } = useMutation(UNFOLLOW_USER);

async function handleFollow() {
  try {
    await followUser({ userId: user.value!.id });
    await refetch();
    showSnackbar(`You are now following ${user.value!.username}.`);
  } catch {
    showSnackbar("Failed to follow user.", "error");
  }
}

async function handleUnfollow() {
  try {
    await unfollowUser({ userId: user.value!.id });
    await refetch();
    showSnackbar(`You have unfollowed ${user.value!.username}.`);
  } catch {
    showSnackbar("Failed to unfollow user.", "error");
  }
}

// ── Admin actions ──
const actionsOpen = ref(false);
const showBanConfirm = ref(false);
const showRoleConfirm = ref(false);
const pendingRole = ref<string | null>(null);
const banLoading = ref(false);
const roleLoading = ref(false);

const currentRole = computed(() => authStore.user?.role);
const isNotSelf = computed(() => authStore.isAuthenticated && user.value && authStore.user?.id !== user.value.id);

const canBan = computed(
  () =>
    isNotSelf.value &&
    (currentRole.value === "ADMIN" || (currentRole.value === "MODERATOR" && user.value?.role === "MEMBER"))
);
const canUnban = computed(
  () => isNotSelf.value && (currentRole.value === "ADMIN" || currentRole.value === "MODERATOR")
);
const canUpdateRole = computed(() => isNotSelf.value && currentRole.value === "ADMIN");
const canRemoveAvatar = computed(
  () => isNotSelf.value && (currentRole.value === "ADMIN" || currentRole.value === "MODERATOR")
);
const hasAdminActions = computed(() => canBan.value || canUnban.value || canUpdateRole.value || canRemoveAvatar.value);

const { mutate: banUserMutate } = useMutation(BAN_USER);
const { mutate: unbanUserMutate } = useMutation(UNBAN_USER);
const { mutate: updateUserRoleMutate } = useMutation(UPDATE_USER_ROLE);
const { mutate: removeUserAvatarMutate } = useMutation(REMOVE_USER_AVATAR);

function promptBan() {
  actionsOpen.value = false;
  showBanConfirm.value = true;
}

async function confirmBan() {
  banLoading.value = true;
  try {
    await banUserMutate({ userId: user.value!.id });
    showBanConfirm.value = false;
    await refetch();
    showSnackbar(`${user.value!.username} has been banned.`, "success");
  } catch {
    showSnackbar("Failed to ban user.", "error");
  } finally {
    banLoading.value = false;
  }
}

async function handleUnban() {
  actionsOpen.value = false;
  try {
    await unbanUserMutate({ userId: user.value!.id });
    await refetch();
    showSnackbar(`${user.value!.username} has been unbanned.`, "success");
  } catch {
    showSnackbar("Failed to unban user.", "error");
  }
}

function roleLabelFor(role: string): string {
  if (role === "MODERATOR") return "moderator";
  if (role === "ADMIN") return "admin";
  return "member";
}

const roleConfirmTitle = computed(() => {
  if (!pendingRole.value) return "";
  if (pendingRole.value === "MEMBER") return "Demote to member?";
  return `Make ${roleLabelFor(pendingRole.value)}?`;
});

const roleConfirmLabel = computed(() => {
  if (!pendingRole.value) return "";
  if (pendingRole.value === "MEMBER") return "Demote to member";
  return `Make ${roleLabelFor(pendingRole.value)}`;
});

const roleConfirmLoadingLabel = computed(() => "Updating…");

const roleConfirmDescription = computed(() => {
  if (!pendingRole.value) return "";
  if (pendingRole.value === "ADMIN") return "will be granted full admin privileges.";
  if (pendingRole.value === "MODERATOR") return "will be granted moderator privileges.";
  return "will be demoted to a regular member.";
});

function promptRoleChange(role: string) {
  actionsOpen.value = false;
  pendingRole.value = role;
  showRoleConfirm.value = true;
}

async function confirmRoleChange() {
  if (!pendingRole.value) return;
  roleLoading.value = true;
  const roleLabel = roleLabelFor(pendingRole.value);
  try {
    await updateUserRoleMutate({ userId: user.value!.id, role: pendingRole.value });
    showRoleConfirm.value = false;
    await refetch();
    showSnackbar(`${user.value!.username} is now a ${roleLabel}.`, "success");
  } catch {
    showSnackbar("Failed to update user role.", "error");
  } finally {
    roleLoading.value = false;
  }
}

async function handleRemoveAvatar() {
  actionsOpen.value = false;
  try {
    await removeUserAvatarMutate({ userId: user.value!.id });
    await refetch();
    showSnackbar("Avatar removed.", "success");
  } catch {
    showSnackbar("Failed to remove avatar.", "error");
  }
}

function closeActionsOnClickOutside(e: MouseEvent) {
  const target = e.target as HTMLElement;
  if (!target.closest(".actions-dropdown")) {
    actionsOpen.value = false;
  }
}

onMounted(() => document.addEventListener("click", closeActionsOnClickOutside));
onBeforeUnmount(() => document.removeEventListener("click", closeActionsOnClickOutside));
</script>

<style scoped>
/* ── Theme tokens ── */
.user-profile {
  --up-border: var(--color-border);
  --up-text-dim: var(--color-text-secondary);
  --up-text-faint: var(--color-text-tertiary);
  --up-hover-overlay: rgba(0, 0, 0, 0.65);
  --up-name-gradient: linear-gradient(to top, rgba(0, 0, 0, 0.75) 0%, rgba(0, 0, 0, 0.35) 60%, transparent 100%);
}

@media (prefers-color-scheme: dark) {
  .user-profile {
    --up-border: var(--color-border);
    --up-text-dim: var(--color-text-secondary);
    --up-text-faint: var(--color-text-tertiary);
    --up-hover-overlay: rgba(0, 0, 0, 0.75);
    --up-name-gradient: linear-gradient(to top, rgba(0, 0, 0, 0.85) 0%, rgba(0, 0, 0, 0.45) 60%, transparent 100%);
  }
}

/* ── Profile Header ── */
.profile-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 2rem;
}

.profile-header-left {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
}

.profile-avatar {
  flex-shrink: 0;
}

.profile-avatar img {
  width: 56px;
  height: 56px;
  border-radius: 14px;
  object-fit: cover;
  display: block;
}

.avatar-placeholder {
  width: 56px;
  height: 56px;
  border-radius: 14px;
  background: linear-gradient(135deg, var(--p-400), var(--p-300));
  display: flex;
  align-items: center;
  justify-content: center;
}

.avatar-placeholder span {
  font-size: 1.4rem;
  font-weight: 600;
  color: #fff;
}

.profile-name-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.profile-name {
  font-size: 1.35rem;
  font-weight: 700;
  line-height: 1.2;
}

.role-badge {
  font-size: 0.6rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  padding: 2px 8px;
  border-radius: 999px;
  color: #fff;
}

.role-admin {
  background: var(--vglist-theme);
}

.role-mod {
  background: #f59e0b;
}

.profile-bio {
  font-size: 0.9rem;
  color: var(--up-text-dim);
  margin-top: 0.25rem;
}

.profile-stats-line {
  font-size: 0.8rem;
  color: var(--up-text-dim);
  margin-top: 0.35rem;
}

.profile-social {
  display: flex;
  gap: 1rem;
  margin-top: 0.5rem;
}

.social-link {
  font-size: 0.8rem;
  color: var(--up-text-dim);
  text-decoration: none;
}

.social-link strong {
  color: inherit;
  font-weight: 600;
}

.social-link:hover {
  text-decoration: underline;
}

.follow-btn {
  padding: 0.45rem 1.25rem;
  border-radius: 20px;
  font-size: 0.85rem;
  font-weight: 500;
  cursor: pointer;
  border: 1.5px solid var(--up-border);
  transition:
    background 0.15s,
    border-color 0.15s;
}

.follow-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.follow-btn-primary {
  background: var(--vglist-theme);
  color: #fff;
  border-color: var(--vglist-theme);
}

.follow-btn-primary:hover {
  opacity: 0.9;
}

.follow-btn-secondary {
  background: transparent;
  color: inherit;
}

.follow-btn-secondary:hover {
  border-color: var(--vglist-theme);
}

/* ── Profile header right ── */
.profile-header-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

/* ── Actions dropdown ── */
.actions-dropdown {
  position: relative;
}

.actions-dropdown-toggle {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 0.5rem 1rem;
  border: 1px solid var(--up-border);
  border-radius: 6px;
  background: var(--color-surface);
  color: var(--color-text-primary);
  font-size: 0.9rem;
  cursor: pointer;
  font-family: inherit;
}

.actions-dropdown-toggle:hover {
  border-color: var(--vglist-theme);
}

.actions-caret {
  font-size: 0.6rem;
}

.actions-dropdown-menu {
  position: absolute;
  right: 0;
  top: calc(100% + 4px);
  min-width: 180px;
  background: var(--color-surface);
  border: 1px solid var(--up-border);
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
  z-index: 100;
  padding: 4px 0;
}

.actions-dropdown-item {
  display: block;
  width: 100%;
  padding: 8px 16px;
  border: none;
  background: none;
  font-size: 0.9rem;
  text-align: left;
  cursor: pointer;
  font-family: inherit;
}

.actions-dropdown-item:hover {
  background: var(--color-bg-subtle);
}

.actions-dropdown-item-danger {
  color: var(--r-500);
}

.actions-dropdown-item-danger:hover {
  background: var(--r-50);
}

/* ── Section Labels ── */
.section-label {
  font-size: 0.7rem;
  font-weight: 600;
  letter-spacing: 0.1em;
  color: var(--vglist-theme);
  margin-bottom: 0.75rem;
}

/* ── Private Notice ── */
.private-notice {
  text-align: center;
  padding: 3rem 1rem;
  border: 1px dashed var(--up-border);
  border-radius: 10px;
  margin-top: 1rem;
}

.private-notice-text {
  font-size: 0.95rem;
  color: var(--up-text-dim);
  font-weight: 500;
}

/* ── Favorites Row ── */
.favorites-section {
  margin-bottom: 2rem;
}

.favorites-row {
  display: flex;
  gap: 0.65rem;
  overflow-x: auto;
  padding-bottom: 0.5rem;
  scrollbar-width: thin;
}

.favorite-tile {
  flex-shrink: 0;
  width: 90px;
  text-decoration: none;
  color: inherit;
}

.favorite-tile img {
  width: 90px;
  height: 120px;
  object-fit: cover;
  border-radius: 8px;
  display: block;
}

.favorite-placeholder {
  width: 90px;
  height: 120px;
  border-radius: 8px;
  background: linear-gradient(135deg, #e879a0 0%, #c266d6 50%, #7c5ce7 100%);
  display: flex;
  align-items: center;
  justify-content: center;
}

.favorite-placeholder span {
  font-size: 1.25rem;
  font-weight: 700;
  color: #fff;
}

.favorite-name {
  font-size: 0.7rem;
  font-weight: 500;
  margin-top: 0.3rem;
  line-height: 1.3;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

/* ── Library Section ── */
.library-section {
  margin-bottom: 2rem;
}

/* Status Pills */
.status-pills {
  display: flex;
  gap: 0.4rem;
  flex-wrap: wrap;
  margin-bottom: 1rem;
}

.status-pill {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 0.75rem;
  font-weight: 400;
  padding: 0.3rem 0.75rem;
  border-radius: 999px;
  border: 1px solid var(--up-border);
  background: transparent;
  color: var(--up-text-dim);
  cursor: pointer;
  transition: all 0.15s;
  white-space: nowrap;
}

.status-pill.is-active {
  font-weight: 600;
  border-color: transparent;
  background: var(--vglist-theme);
  color: #fff;
}

.status-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  display: inline-block;
  flex-shrink: 0;
}

.pill-count {
  font-size: 0.65rem;
  opacity: 0.6;
}

/* Library Controls */
.library-controls {
  display: flex;
  gap: 0.65rem;
  align-items: center;
  margin-bottom: 1rem;
}

.library-search {
  flex: 1;
  max-width: 260px;
}

.library-count {
  margin-left: auto;
  font-size: 0.75rem;
  color: var(--up-text-faint);
}

/* Empty State */
.library-empty {
  text-align: center;
  padding: 4rem 1rem;
  color: var(--up-text-faint);
}

.library-empty-title {
  font-size: 0.9rem;
  font-weight: 500;
  color: var(--up-text-dim);
  margin-bottom: 0.25rem;
}

.library-empty-sub {
  font-size: 0.8rem;
}

/* ── Gallery Grid ── */
.gallery-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
  gap: 10px;
}

.gallery-tile {
  position: relative;
  aspect-ratio: 3 / 4;
  border-radius: 10px;
  overflow: hidden;
  cursor: pointer;
  display: block;
  text-decoration: none;
  color: inherit;
}

.gallery-cover {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.gallery-cover-placeholder {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #e879a0 0%, #c266d6 50%, #7c5ce7 100%);
  display: flex;
  align-items: center;
  justify-content: center;
}

.gallery-cover-placeholder span {
  font-size: 1.75rem;
  font-weight: 700;
  color: #fff;
  letter-spacing: 0.05em;
}

/* Rating badge */
.gallery-rating {
  position: absolute;
  top: 6px;
  right: 6px;
  min-width: 24px;
  height: 24px;
  border-radius: 6px;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.65rem;
  font-weight: 700;
  padding: 0 5px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.4);
  z-index: 2;
}

.rating-great {
  background: #22c55e;
}

.rating-good {
  background: #3b82f6;
}

.rating-ok {
  background: #f59e0b;
}

.rating-low {
  background: #ef4444;
}

/* Status dot */
.gallery-status-dot {
  position: absolute;
  top: 8px;
  left: 8px;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  border: 1.5px solid rgba(0, 0, 0, 0.4);
  z-index: 2;
}

.gallery-status-dot.is-playing {
  animation: pulse-dot 2s ease-in-out infinite;
}

@keyframes pulse-dot {
  0%,
  100% {
    box-shadow: 0 0 0 0 rgba(59, 130, 246, 0.5);
  }

  50% {
    box-shadow: 0 0 0 4px rgba(59, 130, 246, 0);
  }
}

/* Bottom name overlay (always visible) */
.gallery-name-overlay {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 20px 8px 8px;
  background: var(--up-name-gradient);
  z-index: 1;
  transition: opacity 0.2s ease;
}

.gallery-name {
  font-size: 0.7rem;
  font-weight: 500;
  color: #fff;
  line-height: 1.3;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

/* Hover overlay */
.gallery-hover {
  position: absolute;
  inset: 0;
  background: var(--up-hover-overlay);
  backdrop-filter: blur(2px);
  opacity: 0;
  transition: opacity 0.2s ease;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  padding: 10px;
  z-index: 3;
}

.gallery-tile:hover .gallery-hover {
  opacity: 1;
}

.gallery-tile:hover .gallery-name-overlay {
  opacity: 0;
}

.gallery-hover-name {
  font-size: 0.8rem;
  font-weight: 600;
  color: #fff;
  line-height: 1.3;
  margin-bottom: 0.4rem;
}

.gallery-hover-meta {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  flex-wrap: wrap;
}

.gallery-hover-status {
  font-size: 0.6rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: #fff;
  padding: 1px 6px;
  border-radius: 999px;
  line-height: 1.4;
}

.gallery-hover-hours {
  font-size: 0.65rem;
  color: rgba(255, 255, 255, 0.5);
}

.gallery-hover-rating {
  font-size: 0.65rem;
  color: rgba(255, 255, 255, 0.5);
}

/* ── Responsive ── */
@media (max-width: 768px) {
  .profile-header {
    flex-direction: column;
  }

  .gallery-grid {
    grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
    gap: 8px;
  }

  .library-controls {
    flex-wrap: wrap;
  }

  .library-search {
    max-width: 100%;
    order: -1;
    flex-basis: 100%;
  }
}
</style>
