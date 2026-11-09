import { describe, expect, it } from "vitest";
import { COVER_PLACEHOLDER_GRADIENTS, coverPlaceholderGradient, coverPlaceholderStyle } from "./cover-placeholder";

// WCAG relative luminance and contrast against white.
function contrastWithWhite(hex: string): number {
  const [r, g, b] = [1, 3, 5]
    .map((i) => parseInt(hex.slice(i, i + 2), 16) / 255)
    .map((v) => (v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4));
  const luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  return 1.05 / (luminance + 0.05);
}

describe("coverPlaceholderGradient", () => {
  it("returns the same gradient for the same name every time", () => {
    expect(coverPlaceholderGradient("Hollow Knight")).toBe(coverPlaceholderGradient("Hollow Knight"));
  });

  it("is seeded from the initials, so names with the same initials match", () => {
    expect(coverPlaceholderGradient("Half-Life")).toBe(coverPlaceholderGradient("Hades"));
    expect(coverPlaceholderGradient("Hollow Knight")).toBe(coverPlaceholderGradient("Hotline Kentucky"));
    expect(coverPlaceholderGradient("Portal 2")).toBe(coverPlaceholderGradient("Pikmin 2"));
  });

  it("spreads different initials across the palette", () => {
    const names = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("").map((letter) => `${letter}ame`);
    const used = new Set(names.map(coverPlaceholderGradient));
    expect(used.size).toBeGreaterThanOrEqual(COVER_PLACEHOLDER_GRADIENTS.length - 2);
  });

  it("handles names with no initials", () => {
    expect(coverPlaceholderGradient("")).toMatch(/^linear-gradient\(/);
  });

  it("keeps white initials readable on every stop", () => {
    for (const stops of COVER_PLACEHOLDER_GRADIENTS) {
      for (const stop of stops) {
        expect({ stop, contrast: contrastWithWhite(stop) >= 3 }).toEqual({ stop, contrast: true });
      }
    }
  });
});

describe("coverPlaceholderStyle", () => {
  it("wraps the gradient for a :style binding", () => {
    expect(coverPlaceholderStyle("Celeste")).toEqual({ backgroundImage: coverPlaceholderGradient("Celeste") });
  });
});
