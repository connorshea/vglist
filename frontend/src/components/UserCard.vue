<template>
  <router-link :to="userPath" class="user-card" :class="{ 'is-banned': banned }">
    <Lock v-if="isPrivate" class="private-icon" :size="14" :stroke-width="1.1" />
    <span v-if="roleBadgeLabel" class="role-badge" :class="roleBadgeClass">{{ roleBadgeLabel }}</span>

    <div class="avatar" :style="avatarStyle">
      <img v-if="avatarUrl" :src="avatarUrl" :alt="username" />
      <span v-else :style="initialFontStyle">{{ userInitial }}</span>
    </div>

    <div class="username">{{ username }}</div>
    <div v-if="gameCount !== undefined" class="game-count">{{ gameCount }} game{{ gameCount !== 1 ? "s" : "" }}</div>
    <div v-if="joinedDate" class="joined">Joined {{ formattedJoinedDate }}</div>
    <slot />
  </router-link>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { Lock } from "lucide-vue-next";

const GRADIENTS = [
  "linear-gradient(135deg, var(--p-400), var(--p-600))",
  "linear-gradient(135deg, var(--p-300), var(--p-500))",
  "linear-gradient(135deg, var(--p-400), var(--p-700))",
  "linear-gradient(135deg, var(--p-200), var(--p-400))",
  "linear-gradient(135deg, var(--p-500), var(--p-800))",
  "linear-gradient(135deg, var(--p-300), var(--p-600))"
];

const props = withDefaults(
  defineProps<{
    slug: string;
    username: string;
    avatarUrl?: string | null;
    size?: number;
    role?: string;
    privacy?: string;
    banned?: boolean;
    gameCount?: number;
    joinedDate?: string;
  }>(),
  {
    avatarUrl: null,
    size: 48,
    role: undefined,
    privacy: undefined,
    banned: false,
    gameCount: undefined,
    joinedDate: undefined
  }
);

const userPath = computed(() => `/users/${props.slug}`);
const userInitial = computed(() => props.username.charAt(0).toUpperCase());
const isPrivate = computed(() => props.privacy === "PRIVATE_ACCOUNT");

function hashCode(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash += str.charCodeAt(i);
  }
  return hash;
}

const avatarStyle = computed(() => ({
  width: `${props.size}px`,
  height: `${props.size}px`,
  background: props.avatarUrl ? undefined : GRADIENTS[hashCode(props.username) % GRADIENTS.length]
}));

const initialFontStyle = computed(() => ({
  fontSize: `${Math.round(props.size * 0.38)}px`
}));

const roleBadgeLabel = computed(() => {
  if (props.banned) return "Banned";
  if (props.role === "ADMIN") return "Admin";
  if (props.role === "MODERATOR") return "Mod";
  return null;
});

const roleBadgeClass = computed(() => {
  if (props.banned) return "banned";
  if (props.role === "ADMIN") return "admin";
  if (props.role === "MODERATOR") return "mod";
  return "";
});

const formattedJoinedDate = computed(() => {
  if (!props.joinedDate) return "";
  const date = new Date(props.joinedDate);
  return date.toLocaleDateString("en-US", { month: "short", year: "numeric" });
});
</script>

<style scoped>
.user-card {
  display: block;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 18px 12px 14px;
  text-align: center;
  text-decoration: none;
  position: relative;
  transition:
    transform 0.15s,
    box-shadow 0.15s;
  cursor: pointer;
  overflow: hidden;
}

.user-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
}

@media (prefers-color-scheme: dark) {
  .user-card:hover {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.4);
  }
}

.user-card.is-banned {
  opacity: 0.5;
}

.user-card.is-banned .avatar {
  filter: grayscale(1);
}

/* Role badge */
.role-badge {
  position: absolute;
  top: 6px;
  right: 6px;
  font-size: 8px;
  font-weight: 600;
  padding: 2px 6px;
  border-radius: 8px;
  letter-spacing: 0.3px;
  text-transform: uppercase;
}

.role-badge.admin {
  background: var(--p-100);
  color: var(--p-500);
}

.role-badge.mod {
  background: var(--p-50);
  color: var(--p-400);
}

.role-badge.banned {
  background: var(--r-50);
  color: var(--r-800);
}

/* Private icon */
.private-icon {
  position: absolute;
  top: 9px;
  left: 9px;
  color: var(--color-text-tertiary);
}

/* Avatar */
.avatar {
  border-radius: 50%;
  margin: 0 auto 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  flex-shrink: 0;
  position: relative;
  overflow: hidden;
}

.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar span {
  font-weight: 600;
  letter-spacing: 0.02em;
}

/* Text */
.username {
  font-size: 12px;
  font-weight: 500;
  color: var(--color-accent);
  margin-bottom: 2px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.game-count {
  font-size: 11px;
  color: var(--color-text-secondary);
}

.joined {
  font-size: 10px;
  color: var(--color-text-tertiary);
  margin-top: 1px;
}
</style>
