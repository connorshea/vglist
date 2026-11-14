import { describe, it, expect, afterEach, vi } from "vitest";
import { useReducedMotion, resetReducedMotionForTests } from "./useReducedMotion";

function stubMatchMedia(matches: boolean) {
  const query = Object.assign(new EventTarget(), { matches, media: "(prefers-reduced-motion: reduce)" });
  vi.stubGlobal(
    "matchMedia",
    vi.fn(() => query)
  );
  return query;
}

describe("useReducedMotion", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    resetReducedMotionForTests();
  });

  it("is false when matchMedia isn't available", () => {
    vi.stubGlobal("matchMedia", undefined);
    expect(useReducedMotion().value).toBeFalsy();
  });

  it("reflects the media query", () => {
    stubMatchMedia(true);
    expect(useReducedMotion().value).toBeTruthy();
  });

  it("updates when the setting changes", () => {
    const query = stubMatchMedia(false);
    const reduced = useReducedMotion();
    expect(reduced.value).toBeFalsy();
    query.dispatchEvent(Object.assign(new Event("change"), { matches: true }));
    expect(reduced.value).toBeTruthy();
  });
});
