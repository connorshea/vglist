import { gameInitials } from "./library";

// Backgrounds for the initials panel shown in place of a missing cover. Each
// is a pair of saturated mid-to-dark tones, so the white initials stay
// readable (at least 3:1, the bar for large bold text) on both stops, and the
// panel looks the same on light and dark pages.
export const COVER_PLACEHOLDER_GRADIENTS: readonly (readonly [string, string])[] = [
  ["#db2777", "#7c3aed"], // pink → violet
  ["#c026d3", "#6d28d9"], // fuchsia → purple
  ["#7c3aed", "#4338ca"], // violet → indigo
  ["#2563eb", "#4338ca"], // blue → indigo
  ["#0891b2", "#0369a1"], // cyan → sky
  ["#0d9488", "#0e7490"], // teal → cyan
  ["#16a34a", "#047857"], // green → emerald
  ["#d97706", "#c2410c"], // amber → orange
  ["#ea580c", "#be123c"], // orange → rose
  ["#e11d48", "#be185d"] // rose → pink
];

// FNV-1a, which spreads short strings like "HK" and "HL" across the palette
// better than a plain multiply-and-add hash.
function hash(text: string): number {
  let h = 0x811c9dc5;
  for (let i = 0; i < text.length; i++) {
    h ^= text.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  return h >>> 0;
}

// The gradient for a game (or other item) with no cover. It's seeded from the
// name's initials, so every placeholder for the same game has the same colour
// wherever it appears, even where fewer initials are shown.
export function coverPlaceholderGradient(name: string): string {
  const [from, to] = COVER_PLACEHOLDER_GRADIENTS[hash(gameInitials(name)) % COVER_PLACEHOLDER_GRADIENTS.length];
  return `linear-gradient(135deg, ${from} 0%, ${to} 100%)`;
}

// For a placeholder element's :style binding.
export function coverPlaceholderStyle(name: string): { backgroundImage: string } {
  return { backgroundImage: coverPlaceholderGradient(name) };
}
