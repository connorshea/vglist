<template>
  <div class="profile-header-skeleton" aria-hidden="true">
    <div class="s-identity">
      <SkeletonBlock class="s-avatar" />
      <div class="s-identity-text">
        <div class="s-name">
          <SkeletonBlock class="s-bar s-name-bar" />
        </div>
        <div class="s-stats">
          <SkeletonBlock class="s-bar s-stats-bar" />
          <SkeletonBlock class="s-bar s-stats-bar is-wrapped" />
        </div>
      </div>
    </div>

    <div class="s-tabs">
      <div v-for="(width, index) in TAB_WIDTHS" :key="index" class="s-tab">
        <SkeletonBlock class="s-bar s-tab-bar" :style="{ width }" />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import SkeletonBlock from "@/components/SkeletonBlock.vue";

// Stands in for UserProfileLayout's header (avatar, name, stats line) and tab
// bar while the profile first loads. The rows use the same sizes as the real
// header and tabs so the tab content below doesn't move when the profile
// arrives; keep them in step. The follow/edit buttons are left out, since
// they depend on who's looking and are no taller than the identity block.
// Hidden from screen readers: the layout announces the loading state.

// Overview, Library, Favorites, Activity, Followers.
const TAB_WIDTHS = ["58px", "70px", "78px", "52px", "80px"];
</script>

<style scoped>
.s-bar {
  border-radius: 4px;
}

.s-identity {
  display: flex;
  gap: 14px;
  align-items: center;
}

.s-avatar {
  flex-shrink: 0;
  width: 48px;
  height: 48px;
  border-radius: 12px;
}

/* The real header is as tall as the 48px avatar or the name and stats lines,
   whichever is taller (they're about 44px), so match the lines too. */
.s-name {
  display: flex;
  align-items: center;
  height: calc(1.25rem * 1.2);
}

.s-name-bar {
  width: 140px;
  height: 16px;
}

.s-stats {
  display: flex;
  align-items: center;
  height: calc(0.8rem * 1.5);
  margin-top: 3px;
}

.s-stats-bar {
  width: 220px;
  max-width: 60vw;
  height: 9px;
}

.s-tabs {
  display: flex;
  margin-top: 24px;
  overflow: hidden;
  border-bottom: 1px solid var(--color-border);
}

/* Padding, line box and bottom border of a real tab. */
.s-tab {
  display: flex;
  flex-shrink: 0;
  align-items: center;
  height: calc(0.875rem * 1.5);
  margin-bottom: -1px;
  padding: 10px 16px;
  box-sizing: content-box;
  border-bottom: 2px solid transparent;
}

.s-tab-bar {
  height: 9px;
}

/* A full stats line ("948 games · 1,830h played · 56% completed · avg 78")
   wraps onto a second line on a phone, so reserve one there. */
.s-stats-bar.is-wrapped {
  display: none;
}

@media (max-width: 480px) {
  .s-stats {
    flex-direction: column;
    align-items: flex-start;
    justify-content: space-around;
    height: calc(0.8rem * 1.5 * 2);
  }

  .s-stats-bar.is-wrapped {
    display: block;
    width: 90px;
  }
}

@media (max-width: 768px) {
  .s-avatar {
    width: 44px;
    height: 44px;
    border-radius: 11px;
  }

  .s-tabs {
    margin-top: 16px;
    margin-right: -1.5rem;
    margin-left: -1.5rem;
    padding: 0 calc(1.5rem - 12px);
  }

  .s-tab {
    padding: 10px 12px;
  }
}
</style>
