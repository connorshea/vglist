<template>
  <ul class="result-list">
    <template v-if="section.type === 'games'">
      <li v-for="game in section.nodes" :key="game.id">
        <GameResultRow :game="game" />
      </li>
    </template>

    <template v-else-if="section.type === 'users'">
      <li v-for="user in section.nodes" :key="user.id">
        <RouterLink :to="recordPath('users', user.slug)" class="result-row">
          <img v-if="user.avatarUrl" :src="user.avatarUrl" alt="" class="result-avatar" loading="lazy" />
          <span v-else class="result-initial" aria-hidden="true">{{ user.username.charAt(0).toUpperCase() }}</span>
          <span class="result-name">{{ user.username }}</span>
          <span class="result-slug">@{{ user.slug }}</span>
        </RouterLink>
      </li>
    </template>

    <template v-else>
      <li v-for="record in section.nodes" :key="record.id">
        <RouterLink :to="recordPath(section.type, record.id)" class="result-row">
          <span class="result-initial" aria-hidden="true">{{ record.name.charAt(0).toUpperCase() }}</span>
          <span class="result-name">{{ record.name }}</span>
        </RouterLink>
      </li>
    </template>
  </ul>
</template>

<script setup lang="ts">
import GameResultRow from "./GameResultRow.vue";
import { recordPath, type SearchSection } from "@/utils/search";

defineProps<{
  section: SearchSection;
}>();
</script>

<style scoped>
.result-list {
  list-style: none;
  margin: 0;
}

.result-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 12px;
  border-radius: 8px;
  color: inherit;
}

.result-row:hover {
  background: var(--color-bg-subtle);
}

.result-row:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.result-avatar,
.result-initial {
  flex: 0 0 32px;
  width: 32px;
  height: 32px;
  border-radius: 50%;
}

.result-avatar {
  object-fit: cover;
}

.result-initial {
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  color: var(--color-text-tertiary);
  background: var(--color-bg-subtle);
}

.result-name {
  font-weight: 600;
  color: var(--color-text-primary);
}

.result-slug {
  font-size: 0.85rem;
  color: var(--color-text-secondary);
}
</style>
