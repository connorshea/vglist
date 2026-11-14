import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { isChunkLoadError, reloadForStaleChunk } from "./chunk-reload";

describe("isChunkLoadError", () => {
  it.each([
    "Failed to fetch dynamically imported module: https://vglist.co/assets/GameShowPage-abc123.js",
    "error loading dynamically imported module: https://vglist.co/assets/GameShowPage-abc123.js",
    "Importing a module script failed.",
    "Unable to preload CSS for /assets/GameShowPage-abc123.css"
  ])("recognizes %s", (message) => {
    expect(isChunkLoadError(new TypeError(message))).toBeTruthy();
  });

  it("ignores other errors", () => {
    expect(isChunkLoadError(new Error("Network request failed"))).toBeFalsy();
    expect(isChunkLoadError(undefined)).toBeFalsy();
  });
});

describe("reloadForStaleChunk", () => {
  const assign = vi.fn<(url: string) => void>();

  beforeEach(() => {
    sessionStorage.clear();
    assign.mockClear();
    vi.stubGlobal("location", { assign });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("does a full page load of the destination", () => {
    expect(reloadForStaleChunk("/games/1", 100_000)).toBeTruthy();
    expect(assign).toHaveBeenCalledWith("/games/1");
  });

  it("doesn't reload again within the cooldown", () => {
    reloadForStaleChunk("/games/1", 100_000);
    expect(reloadForStaleChunk("/games/2", 105_000)).toBeFalsy();
    expect(assign).toHaveBeenCalledTimes(1);
  });

  it("reloads again once the cooldown has passed", () => {
    reloadForStaleChunk("/games/1", 100_000);
    expect(reloadForStaleChunk("/games/2", 111_000)).toBeTruthy();
    expect(assign).toHaveBeenLastCalledWith("/games/2");
  });

  it("still reloads when storage is blocked", () => {
    const session = vi.spyOn(window, "sessionStorage", "get").mockImplementation(() => {
      throw new DOMException("The operation is insecure.", "SecurityError");
    });
    try {
      expect(reloadForStaleChunk("/games/1", 100_000)).toBeTruthy();
      expect(assign).toHaveBeenCalledWith("/games/1");
    } finally {
      session.mockRestore();
    }
  });
});
