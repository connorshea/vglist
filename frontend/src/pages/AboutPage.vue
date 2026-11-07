<template>
  <main class="about">
    <div class="about-mosaic" aria-hidden="true">
      <div v-for="tile in tiles" :key="tile.id" class="about-tile" :style="{ background: tile.color }"></div>
    </div>
    <div class="about-vignette" aria-hidden="true"></div>

    <div class="about-card">
      <div class="about-band">
        <h1 class="about-title">
          <img src="@/assets/images/vglist-logo.svg" alt="About vglist" class="about-logo" />
        </h1>
      </div>

      <p class="about-copy">vglist is a video game database for tracking your collection, because I wanted to get through my massive backlog. I've been building it since 2017, and I hope it's as useful to others as it has been to me.</p>

      <div class="about-links">
        <a class="about-btn" href="https://github.com/connorshea/vglist" target="_blank" rel="noopener noreferrer"
          >GitHub</a
        >
        <a class="about-btn" href="https://discord.gg/Ma8Ztcc" target="_blank" rel="noopener noreferrer">Discord</a>
        <a
          class="about-btn"
          href="https://github.com/connorshea/vglist/blob/main/CHANGELOG.md"
          target="_blank"
          rel="noopener noreferrer"
          >Changelog</a
        >
      </div>

      <p class="about-fine">
        <span class="about-fine-line"
          >Game data from
          <a href="https://www.wikidata.org" target="_blank" rel="noopener noreferrer">Wikidata</a>.</span
        >
        {{ " " }}
        <span class="about-fine-line">Made by <router-link to="/users/connor">Connor Shea</router-link>.</span>
      </p>
    </div>
  </main>
</template>

<script setup lang="ts">
const PALETTE = [
  "#2f4858",
  "#86bbd8",
  "#d1495b",
  "#edae49",
  "#00798c",
  "#30638e",
  "#3a2e39",
  "#8e7dbe",
  "#99c1b9",
  "#f2d0a9",
  "#1e1e24",
  "#92140c",
  "#5c4d7d",
  "#4f6d7a",
  "#c0d6df",
  "#e8a87c"
];

// A fixed, deterministic set of colored tiles, so the page renders instantly
// without fetching covers.
const tiles = Array.from({ length: 126 }, (_, k) => ({
  id: k,
  color: PALETTE[(k * 3 + (k >> 3)) % PALETTE.length]
}));
</script>

<style scoped>
/* Break out of App's .section > .container wrapper to fill the viewport. */
.about {
  --about-muted: var(--n-500);
  --about-tint: var(--p-50);
  --about-tint-fg: var(--p-600);
  --about-tint-hover: var(--p-100);
  --about-link: var(--p-500);

  width: 100vw;
  position: relative;
  left: 50%;
  right: 50%;
  margin: -3rem -50vw;
  min-height: calc(100vh - 52px);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 48px 1.5rem;
  box-sizing: border-box;
  overflow: hidden;
  background: #110b24;
}

@media (prefers-color-scheme: dark) {
  .about {
    --about-muted: var(--s-100);
    --about-tint: rgba(157, 153, 224, 0.16);
    --about-tint-fg: var(--p-200);
    --about-tint-hover: rgba(157, 153, 224, 0.26);
    --about-link: hsl(241deg, 61%, 75%);
  }
}

.about-mosaic {
  position: absolute;
  top: -45%;
  left: -30%;
  width: 160%;
  display: grid;
  grid-template-columns: repeat(18, 110px);
  gap: 10px;
  transform: perspective(410px) rotateX(12deg) rotateZ(-23deg);
  opacity: 0.45;
  pointer-events: none;
}

.about-tile {
  aspect-ratio: 3 / 4;
  border-radius: 5px;
  box-shadow: 0 1px 6px rgba(0, 0, 0, 0.3);
}

.about-vignette {
  position: absolute;
  inset: 0;
  background: radial-gradient(
    ellipse 75% 60% at 50% 45%,
    rgba(89, 87, 214, 0.4) 0%,
    rgba(45, 28, 110, 0.7) 45%,
    rgba(17, 11, 36, 0.97) 100%
  );
}

.about-card {
  position: relative;
  z-index: 2;
  width: 100%;
  max-width: 520px;
  box-sizing: border-box;
  padding: 40px 36px 32px;
  text-align: center;
  border-radius: 16px;
  background: var(--color-surface);
  color: var(--color-text-primary);
  box-shadow: 0 24px 64px rgba(17, 11, 36, 0.55);
}

.about-band {
  margin: -40px -36px 24px;
  padding: 40px 36px 36px;
  border-radius: 16px 16px 0 0;
  background: var(--p-500);
}

.about-title {
  margin: 0;
  line-height: 0;
}

.about-logo {
  width: 180px;
  filter: brightness(0) invert(1);
}

.about-copy {
  font-size: 15px;
  line-height: 1.65;
  color: var(--about-muted);
  margin: 0 0 24px;
}

.about-links {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 8px;
}

.about-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 40px;
  padding: 0 10px;
  border-radius: var(--radius-button);
  background: var(--about-tint);
  color: var(--about-tint-fg);
  font-size: 14px;
  font-weight: 600;
  text-decoration: none;
  box-sizing: border-box;
  transition: background-color var(--transition-fast);
}

.about-btn:hover {
  background: var(--about-tint-hover);
  color: var(--about-tint-fg);
}

.about-btn:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.about-fine {
  font-size: 13px;
  line-height: 1.65;
  color: var(--about-muted);
  margin: 24px 0 0;
  padding-top: 20px;
  border-top: 1px solid var(--color-border);
}

.about-fine a {
  color: var(--about-link);
  font-weight: 500;
}

.about-fine a:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
  border-radius: 2px;
}

@media (max-width: 600px) {
  .about {
    padding: 24px 16px;
  }

  .about-card {
    padding: 32px 20px 24px;
  }

  .about-band {
    margin: -32px -20px 20px;
    padding: 32px 20px 28px;
  }

  .about-logo {
    width: 160px;
  }

  .about-links {
    grid-template-columns: 1fr;
  }

  .about-btn {
    min-height: 44px;
  }

  .about-fine-line {
    display: block;
  }
}
</style>
