<template>
  <div class="column is-4">
    <div v-if="genres.length" class="sidebar-card">
      <h4 class="sidebar-card-title">Genres</h4>
      <div class="sidebar-tags">
        <router-link v-for="genre in genres" :key="genre.id" :to="`/genres/${genre.id}`" class="sidebar-tag">
          {{ genre.name }}
        </router-link>
      </div>
    </div>

    <div class="sidebar-card">
      <div class="community-section">
        <div class="community-header">
          <h4 class="community-title">Owners</h4>
          <span v-if="owners.totalCount > 0" class="community-count"> {{ owners.totalCount }} total </span>
        </div>
        <div v-if="owners.nodes.length > 0" class="avatar-stack">
          <router-link
            v-for="owner in owners.nodes"
            :key="owner.id"
            :to="`/users/${owner.slug}`"
            class="avatar-circle"
            :title="owner.username"
          >
            <img v-if="owner.avatarUrl" :src="owner.avatarUrl" :alt="owner.username" />
            <span v-else class="avatar-initials" :style="{ background: avatarColor(owner.username) }">
              {{ userInitials(owner.username) }}
            </span>
          </router-link>
          <span v-if="owners.totalCount > owners.nodes.length" class="avatar-overflow">
            +{{ owners.totalCount - owners.nodes.length }}
          </span>
        </div>
        <p v-else class="community-empty">No owners yet.</p>
      </div>

      <hr class="community-divider" />

      <div class="community-section">
        <div class="community-header">
          <h4 class="community-title">Favorited by</h4>
          <span v-if="favoriters.totalCount > 0" class="community-count"> {{ favoriters.totalCount }} total </span>
        </div>
        <div v-if="favoriters.nodes.length > 0" class="avatar-stack">
          <router-link
            v-for="fav in favoriters.nodes"
            :key="fav.id"
            :to="`/users/${fav.slug}`"
            class="avatar-circle"
            :title="fav.username"
          >
            <img v-if="fav.avatarUrl" :src="fav.avatarUrl" :alt="fav.username" />
            <span v-else class="avatar-initials" :style="{ background: avatarColor(fav.username) }">
              {{ userInitials(fav.username) }}
            </span>
          </router-link>
          <span v-if="favoriters.totalCount > favoriters.nodes.length" class="avatar-overflow">
            +{{ favoriters.totalCount - favoriters.nodes.length }}
          </span>
        </div>
        <p v-else class="community-empty">No favorites yet.</p>
      </div>
    </div>

    <div v-if="externalLinks.length" class="sidebar-card">
      <h4 class="sidebar-card-title">External links</h4>
      <ul class="external-links-list">
        <li v-for="link in externalLinks" :key="link.label">
          <a :href="link.url" target="_blank" rel="noopener noreferrer">{{ link.label }}</a>
        </li>
      </ul>
    </div>
  </div>
</template>

<script setup lang="ts">
interface UserNode {
  id: string;
  username: string;
  slug: string;
  avatarUrl?: string | null;
}

interface UserConnection {
  nodes: UserNode[];
  totalCount: number;
}

interface ExternalLink {
  label: string;
  url: string;
}

defineProps<{
  genres: { id: string; name: string }[];
  owners: UserConnection;
  favoriters: UserConnection;
  externalLinks: ExternalLink[];
}>();

function userInitials(username: string): string {
  return username.slice(0, 2).toUpperCase();
}

const AVATAR_COLORS = ["#6c5ce7", "#00b894", "#e17055", "#0984e3", "#e84393", "#00a862", "#d63031", "#fdcb6e"];

function avatarColor(username: string): string {
  let hash = 0;
  for (const ch of username) {
    hash = ((hash << 5) - hash + ch.charCodeAt(0)) | 0;
  }
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}
</script>

<style scoped>
/* ── Sidebar ── */
.sidebar-card {
  border: 1px solid var(--game-border);
  border-radius: var(--radius-md);
  padding: 1.25rem;
  margin-bottom: 1rem;
}

.sidebar-card-title {
  font-size: 1.1rem;
  font-weight: 600;
  margin-bottom: 0.75rem;
}

.sidebar-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.sidebar-tag {
  display: inline-block;
  padding: 0.35rem 0.85rem;
  border: 1.5px solid var(--vglist-theme);
  border-radius: var(--radius-pill);
  color: var(--vglist-theme);
  font-size: 0.85rem;
  font-weight: 500;
  text-decoration: none;
  transition: background 0.15s;
}

.sidebar-tag:hover {
  background: color-mix(in srgb, var(--vglist-theme) 10%, transparent);
}

@media (prefers-color-scheme: dark) {
  .sidebar-tag {
    color: var(--s-100);
    border-color: var(--s-300);
  }

  .sidebar-tag:hover {
    background: color-mix(in srgb, var(--p-300) 15%, transparent);
  }
}

/* Community card (owners/favoriters) */
.community-section {
  padding: 0.25rem 0;
}

.community-header {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 0.6rem;
}

.community-title {
  font-size: 1rem;
  font-weight: 600;
}

.community-count {
  font-size: 0.85rem;
  color: var(--game-text-muted);
}

.community-divider {
  border: none;
  border-top: 1px solid var(--game-border-light);
  margin: 0.75rem 0;
}

.community-empty {
  font-size: 0.85rem;
  color: var(--game-text-muted);
}

.avatar-stack {
  display: flex;
  align-items: center;
}

.avatar-circle {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: 2px solid var(--color-surface);
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  text-decoration: none;
  transition: transform 0.15s;
}

.avatar-circle:not(:first-child) {
  margin-left: -10px;
}

.avatar-circle:hover {
  transform: scale(1.15);
  z-index: 1;
}

.avatar-circle img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar-initials {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.75rem;
  font-weight: 700;
  color: #fff;
}

.avatar-overflow {
  margin-left: 0.5rem;
  font-size: 0.85rem;
  color: var(--game-text-muted);
  font-weight: 500;
}

/* External links */
.external-links-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.external-links-list li {
  padding: 0.6rem 0;
  border-bottom: 1px solid var(--game-border-light);
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.external-links-list li:last-child {
  border-bottom: none;
  padding-bottom: 0;
}

.external-links-list li::before {
  content: "\25CF";
  color: var(--vglist-theme);
  font-size: 0.6rem;
  flex-shrink: 0;
}

.external-links-list a {
  color: inherit;
  text-decoration: none;
  font-size: 0.95rem;
}

.external-links-list a:hover {
  text-decoration: underline;
}
</style>
