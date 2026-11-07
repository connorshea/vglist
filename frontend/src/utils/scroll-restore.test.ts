import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { waitForScrollableTo } from "./scroll-restore";

function setPageHeight(height: number) {
  Object.defineProperty(document.documentElement, "scrollHeight", { configurable: true, value: height });
}

describe("waitForScrollableTo", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.stubGlobal("innerHeight", 800);
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it("resolves straight away when the page is already tall enough", async () => {
    setPageHeight(3000);
    let done = false;
    void waitForScrollableTo(2000).then(() => (done = true));
    await vi.advanceTimersByTimeAsync(0);
    expect(done).toBeTruthy();
  });

  it("waits for the page to grow", async () => {
    setPageHeight(1000);
    let done = false;
    void waitForScrollableTo(2000).then(() => (done = true));
    await vi.advanceTimersByTimeAsync(200);
    expect(done).toBeFalsy();

    setPageHeight(3000);
    await vi.advanceTimersByTimeAsync(50);
    expect(done).toBeTruthy();
  });

  it("gives up after the timeout", async () => {
    setPageHeight(1000);
    let done = false;
    void waitForScrollableTo(2000, { timeoutMs: 500 }).then(() => (done = true));
    await vi.advanceTimersByTimeAsync(450);
    expect(done).toBeFalsy();
    await vi.advanceTimersByTimeAsync(100);
    expect(done).toBeTruthy();
  });
});
