import { describe, it, expect, afterEach } from "vitest";
import { loadTurnstile, resetTurnstileLoaderForTests, TURNSTILE_SCRIPT_URL, type TurnstileApi } from "./turnstile";

function injectedScripts() {
  return [...document.head.querySelectorAll<HTMLScriptElement>("script")].filter((s) => s.src === TURNSTILE_SCRIPT_URL);
}

const fakeApi: TurnstileApi = { render: () => "id", reset: () => {}, remove: () => {} };

describe("loadTurnstile", () => {
  afterEach(() => {
    for (const script of injectedScripts()) {
      script.remove();
    }
    delete window.turnstile;
    resetTurnstileLoaderForTests();
  });

  it("returns the existing API without adding a script", async () => {
    window.turnstile = fakeApi;

    await expect(loadTurnstile()).resolves.toBe(fakeApi);
    expect(injectedScripts()).toHaveLength(0);
  });

  it("adds the script once and resolves when it loads", async () => {
    const first = loadTurnstile();
    const second = loadTurnstile();
    expect(injectedScripts()).toHaveLength(1);

    window.turnstile = fakeApi;
    injectedScripts()[0].dispatchEvent(new Event("load"));

    await expect(first).resolves.toBe(fakeApi);
    expect(second).toBe(first);
  });

  it("rejects when the script fails, and lets a later call retry", async () => {
    const first = loadTurnstile();
    injectedScripts()[0].dispatchEvent(new Event("error"));

    await expect(first).rejects.toThrow("Failed to load the Turnstile script");
    expect(injectedScripts()).toHaveLength(0);

    void loadTurnstile().catch(() => {});
    expect(injectedScripts()).toHaveLength(1);
  });
});
