<template>
  <div class="card game-card">
    <router-link :to="`/games/${id}`" class="game-card-cover">
      <div class="card-image" v-if="coverUrl">
        <figure class="image is-3by4">
          <img :src="coverUrl" :alt="name" />
        </figure>
      </div>
      <div class="card-image" v-else>
        <div class="game-cover-placeholder">
          <span>{{ gameInitials }}</span>
        </div>
      </div>
    </router-link>
    <div class="card-content">
      <p class="title is-5">
        <router-link :to="`/games/${id}`">{{ name }}</router-link>
      </p>
      <slot />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";

const props = defineProps<{
  id: string;
  name: string;
  coverUrl: string | null;
}>();

const gameInitials = computed(() => {
  return props.name
    .split(/[\s:]+/)
    .filter((w) => w.length > 0)
    .slice(0, 3)
    .map((w) => w[0].toUpperCase())
    .join("");
});
</script>

<style scoped>
.game-card {
  height: 100%;
  overflow: hidden;
  border-radius: 6px;
}

.game-card-cover {
  display: block;
}

.game-cover-placeholder {
  aspect-ratio: 3 / 4;
  background: linear-gradient(135deg, #e879a0 0%, #c266d6 50%, #7c5ce7 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  user-select: none;
  cursor: default;
}

.game-cover-placeholder span {
  font-size: 2.5rem;
  font-weight: 700;
  color: #fff;
  letter-spacing: 0.05em;
}
</style>
