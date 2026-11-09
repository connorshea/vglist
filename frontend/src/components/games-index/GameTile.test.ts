import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { mount, RouterLinkStub, type VueWrapper } from "@vue/test-utils";
import { NEAR_VIEWPORT_DWELL_MS } from "@/composables/useNearViewport";
import GameTile from "./GameTile.vue";

// An IntersectionObserver the test drives by hand.
class FakeIntersectionObserver {
  static instances: FakeIntersectionObserver[] = [];
  targets = new Set<Element>();

  constructor(private callback: IntersectionObserverCallback) {
    FakeIntersectionObserver.instances.push(this);
  }

  observe(el: Element) {
    this.targets.add(el);
  }

  unobserve(el: Element) {
    this.targets.delete(el);
  }

  disconnect() {
    this.targets.clear();
  }

  // Reports every observed element as having entered or left the root margin.
  static fire(isIntersecting: boolean) {
    for (const observer of FakeIntersectionObserver.instances) {
      const entries = [...observer.targets].map(
        (target) => ({ target, isIntersecting }) as unknown as IntersectionObserverEntry
      );
      observer.callback(entries, observer as unknown as IntersectionObserver);
    }
  }
}

const COVER = "https://files.vglist.co/cover.jpg";

let wrapper: VueWrapper | undefined;

function mountTile(coverUrl: string | null = COVER) {
  wrapper = mount(GameTile, {
    props: { id: "1", name: "Half-Life 2", coverUrl },
    global: { stubs: { RouterLink: RouterLinkStub } }
  });
  return wrapper;
}

describe("GameTile cover loading", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    FakeIntersectionObserver.instances = [];
    // A fresh class each time, so the tile gets a fresh shared observer.
    vi.stubGlobal("IntersectionObserver", class extends FakeIntersectionObserver {});
  });

  afterEach(() => {
    wrapper?.unmount();
    wrapper = undefined;
    vi.unstubAllGlobals();
    vi.useRealTimers();
  });

  it("doesn't request the cover until the tile is near the viewport", async () => {
    const tile = mountTile();

    expect(tile.find("img").exists()).toBeFalsy();
    // Not the initials placeholder either: the tile has a cover, it just isn't loaded.
    expect(tile.find(".game-tile-placeholder").exists()).toBeFalsy();

    FakeIntersectionObserver.fire(true);
    await vi.advanceTimersByTimeAsync(NEAR_VIEWPORT_DWELL_MS);

    expect(tile.find("img").attributes("src")).toBe(COVER);
  });

  it("skips covers a fast scroll only passes over", async () => {
    const tile = mountTile();

    FakeIntersectionObserver.fire(true);
    await vi.advanceTimersByTimeAsync(NEAR_VIEWPORT_DWELL_MS - 50);
    FakeIntersectionObserver.fire(false);
    await vi.advanceTimersByTimeAsync(NEAR_VIEWPORT_DWELL_MS);

    expect(tile.find("img").exists()).toBeFalsy();
  });

  it("drops a cover still loading when the tile leaves the viewport", async () => {
    const tile = mountTile();

    FakeIntersectionObserver.fire(true);
    await vi.advanceTimersByTimeAsync(NEAR_VIEWPORT_DWELL_MS);
    expect(tile.find("img").exists()).toBeTruthy();

    FakeIntersectionObserver.fire(false);
    await tile.vm.$nextTick();

    expect(tile.find("img").exists()).toBeFalsy();
  });

  it("keeps a cover that has loaded when the tile leaves the viewport", async () => {
    const tile = mountTile();

    FakeIntersectionObserver.fire(true);
    await vi.advanceTimersByTimeAsync(NEAR_VIEWPORT_DWELL_MS);
    await tile.find("img").trigger("load");
    FakeIntersectionObserver.fire(false);
    await tile.vm.$nextTick();

    expect(tile.find("img").attributes("src")).toBe(COVER);
  });

  it("shows the initials straight away for a game without a cover", () => {
    const tile = mountTile(null);

    expect(tile.find(".game-tile-placeholder").text()).toBe("H2");
  });

  it("loads the cover right away without IntersectionObserver", () => {
    vi.stubGlobal("IntersectionObserver", undefined);
    const tile = mountTile();

    expect(tile.find("img").attributes("src")).toBe(COVER);
  });
});
