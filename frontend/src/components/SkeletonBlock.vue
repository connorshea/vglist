<template>
  <span class="skeleton-block" aria-hidden="true"></span>
</template>

<script setup lang="ts">
// A placeholder shape for content that is still loading. It has no size of its
// own: give it one with a class or style (width, height, aspect-ratio,
// border-radius) that matches the content it stands in for, so nothing moves
// when the real content arrives. It's hidden from screen readers; announce the
// loading state on the surrounding region (e.g. aria-busy) instead.
</script>

<style scoped>
.skeleton-block {
  /* A tint of the text colour rather than a fixed grey, so the shape shows up
     on any background in both light and dark mode. */
  --skeleton-fill: color-mix(in srgb, var(--color-text-primary) 9%, transparent);
  --skeleton-shine: color-mix(in srgb, var(--color-text-primary) 6%, transparent);

  display: block;
  position: relative;
  overflow: hidden;
  border-radius: var(--radius-sm);
  background: var(--skeleton-fill);
}

.skeleton-block::after {
  content: "";
  position: absolute;
  inset: 0;
  background: linear-gradient(90deg, transparent 0%, var(--skeleton-shine) 50%, transparent 100%);
  transform: translateX(-100%);
  animation: skeleton-shimmer 1.6s ease-in-out infinite;
}

@keyframes skeleton-shimmer {
  to {
    transform: translateX(100%);
  }
}

@media (prefers-reduced-motion: reduce) {
  .skeleton-block::after {
    animation: none;
    display: none;
  }
}
</style>
