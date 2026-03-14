<template>
  <div class="card user-card has-text-centered">
    <div class="card-content">
      <figure class="image is-inline-block mb-3" :style="avatarSizeStyle">
        <img v-if="avatarUrl" class="is-rounded" :src="avatarUrl" :alt="username" />
        <div v-else class="user-avatar-placeholder is-rounded" :style="avatarSizeStyle">
          <span :style="initialFontStyle">{{ userInitial }}</span>
        </div>
      </figure>
      <p class="title is-5">
        <router-link :to="userPath">{{ username }}</router-link>
      </p>
      <slot />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";

const props = withDefaults(
  defineProps<{
    slug: string;
    username: string;
    avatarUrl?: string | null;
    size?: number;
  }>(),
  {
    avatarUrl: null,
    size: 96
  }
);

const userPath = computed(() => `/users/${props.slug}`);

const userInitial = computed(() => props.username.charAt(0).toUpperCase());

const avatarSizeStyle = computed(() => ({
  width: `${props.size}px`,
  height: `${props.size}px`
}));

const initialFontStyle = computed(() => ({
  fontSize: `${Math.round(props.size * 0.42)}px`
}));
</script>

<style scoped>
.user-card {
  height: 100%;
}

.user-avatar-placeholder {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
}

.user-avatar-placeholder span {
  font-weight: 700;
  color: #fff;
  letter-spacing: 0.02em;
}
</style>
