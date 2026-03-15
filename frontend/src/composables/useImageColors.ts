import { ref, watch, type Ref } from "vue";

interface RGB {
  r: number;
  g: number;
  b: number;
}

interface ImageColorsResult {
  /** CSS gradient string derived from the cover image, or null if not yet extracted / failed. */
  gradient: Ref<string | null>;
}

/**
 * Extracts dominant colors from an image URL using the Canvas API and returns
 * a reactive CSS gradient string.
 *
 * Falls back gracefully (gradient stays null) if the image fails to load,
 * CORS prevents canvas read-back, or no image URL is provided.
 */
export function useImageColors(imageUrl: Ref<string | null | undefined>): ImageColorsResult {
  const gradient = ref<string | null>(null);

  watch(
    imageUrl,
    (url) => {
      gradient.value = null;
      if (!url) return;
      extractColors(url);
    },
    { immediate: true }
  );

  function extractColors(url: string): void {
    const img = new Image();
    // Required for cross-origin canvas access (e.g. images from CDN/S3 in production).
    // If the server doesn't send appropriate CORS headers, onload will fire but
    // getImageData() will throw -- caught below with a graceful fallback.
    img.crossOrigin = "anonymous";

    img.onload = () => {
      try {
        const colors = sampleDominantColors(img);
        if (colors.length >= 2) {
          gradient.value = buildGradient(colors);
        }
      } catch {
        // Canvas tainted by CORS or other error -- keep gradient as null
        // so the component falls back to its default background.
      }
    };

    // Network error or broken URL -- stay null.
    img.onerror = () => {
      gradient.value = null;
    };

    img.src = url;
  }

  return { gradient };
}

/**
 * Sample pixels from the image and find 2-3 dominant colors via a simple
 * median-cut quantization approach.
 */
function sampleDominantColors(img: HTMLImageElement): RGB[] {
  const canvas = document.createElement("canvas");
  // Downsample to a small size for performance -- we only need color info,
  // not pixel-perfect detail. 64x64 gives us 4096 pixels which is plenty.
  const sampleSize = 64;
  canvas.width = sampleSize;
  canvas.height = sampleSize;

  const ctx = canvas.getContext("2d", { willReadFrequently: true });
  if (!ctx) return [];

  ctx.drawImage(img, 0, 0, sampleSize, sampleSize);

  // This call will throw a SecurityError if the canvas is tainted by CORS.
  const imageData = ctx.getImageData(0, 0, sampleSize, sampleSize);
  const pixels = imageData.data;

  // Collect all non-transparent, non-extreme pixels.
  const samples: RGB[] = [];
  for (let i = 0; i < pixels.length; i += 4) {
    const r = pixels[i];
    const g = pixels[i + 1];
    const b = pixels[i + 2];
    const a = pixels[i + 3];

    // Skip nearly-transparent pixels.
    if (a < 128) continue;

    // Skip very dark (near black) and very bright (near white) pixels
    // since they make poor background colors.
    const brightness = (r + g + b) / 3;
    if (brightness < 20 || brightness > 235) continue;

    samples.push({ r, g, b });
  }

  if (samples.length === 0) return [];

  // Use median-cut to find dominant color clusters.
  return medianCut(samples, 3);
}

/**
 * Simple median-cut color quantization.
 * Recursively splits the color space along the channel with the widest range.
 */
function medianCut(pixels: RGB[], targetCount: number): RGB[] {
  if (pixels.length === 0) return [];
  if (targetCount <= 1 || pixels.length <= 1) {
    return [averageColor(pixels)];
  }

  // Find which channel (r, g, b) has the widest range.
  const channels: (keyof RGB)[] = ["r", "g", "b"];
  let maxRange = 0;
  let splitChannel: keyof RGB = "r";

  for (const ch of channels) {
    const values = pixels.map((p) => p[ch]);
    const range = Math.max(...values) - Math.min(...values);
    if (range > maxRange) {
      maxRange = range;
      splitChannel = ch;
    }
  }

  // Sort by the channel with the widest range and split at the median.
  const sorted = [...pixels].sort((a, b) => a[splitChannel] - b[splitChannel]);
  const mid = Math.floor(sorted.length / 2);

  const left = sorted.slice(0, mid);
  const right = sorted.slice(mid);

  const leftCount = Math.floor(targetCount / 2);
  const rightCount = targetCount - leftCount;

  return [...medianCut(left, leftCount), ...medianCut(right, rightCount)];
}

/** Average an array of RGB colors into a single color. */
function averageColor(pixels: RGB[]): RGB {
  if (pixels.length === 0) return { r: 0, g: 0, b: 0 };

  let rSum = 0;
  let gSum = 0;
  let bSum = 0;

  for (const p of pixels) {
    rSum += p.r;
    gSum += p.g;
    bSum += p.b;
  }

  const count = pixels.length;
  return {
    r: Math.round(rSum / count),
    g: Math.round(gSum / count),
    b: Math.round(bSum / count)
  };
}

/**
 * Build a CSS linear-gradient from an array of colors.
 * Darkens the colors slightly so white text remains legible on the gradient.
 */
function buildGradient(colors: RGB[]): string {
  const adjusted = colors.map((c) => ensureContrast(c));

  if (adjusted.length === 1) {
    // Single color: create a subtle gradient by shifting hue slightly.
    const c = adjusted[0];
    const c2 = { r: Math.max(0, c.r - 30), g: Math.max(0, c.g - 20), b: Math.min(255, c.b + 20) };
    return `linear-gradient(135deg, rgb(${c.r}, ${c.g}, ${c.b}), rgb(${c2.r}, ${c2.g}, ${c2.b}))`;
  }

  const stops = adjusted.map((c) => `rgb(${c.r}, ${c.g}, ${c.b})`).join(", ");
  return `linear-gradient(135deg, ${stops})`;
}

/**
 * Ensure a color is dark enough for white text to be legible on top of it.
 * Uses relative luminance and darkens if needed.
 */
function ensureContrast(color: RGB): RGB {
  const luminance = relativeLuminance(color);

  // If the color is too bright for white text, darken it.
  // A luminance above ~0.35 means white text won't have enough contrast.
  if (luminance > 0.35) {
    const factor = 0.35 / luminance;
    return {
      r: Math.round(color.r * factor),
      g: Math.round(color.g * factor),
      b: Math.round(color.b * factor)
    };
  }

  // If the color is extremely dark, lighten it slightly so the gradient
  // doesn't look like a black void.
  if (luminance < 0.03) {
    return {
      r: Math.max(color.r, 30),
      g: Math.max(color.g, 30),
      b: Math.max(color.b, 40)
    };
  }

  return color;
}

/** Relative luminance per WCAG 2.0. */
function relativeLuminance(c: RGB): number {
  const rsrgb = c.r / 255;
  const gsrgb = c.g / 255;
  const bsrgb = c.b / 255;

  const r = rsrgb <= 0.03928 ? rsrgb / 12.92 : Math.pow((rsrgb + 0.055) / 1.055, 2.4);
  const g = gsrgb <= 0.03928 ? gsrgb / 12.92 : Math.pow((gsrgb + 0.055) / 1.055, 2.4);
  const b = bsrgb <= 0.03928 ? bsrgb / 12.92 : Math.pow((bsrgb + 0.055) / 1.055, 2.4);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}
