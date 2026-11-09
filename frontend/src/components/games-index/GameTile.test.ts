import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { mount, RouterLinkStub, type VueWrapper } from "@vue/test-utils";

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
let DWELL_MS: number;

// The shared observer lives at module level, so each test imports a fresh copy.
async function mountTile(coverUrl: string | null = COVER, { onScreen = false, deferCover = true } = {}) {
  const { default: GameTile } = await import("./GameTile.vue");
  ({ NEAR_VIEWPORT_DWELL_MS: DWELL_MS } = await import("@/composables/useNearViewport"));
  wrapper = mount(GameTile, {
    props: { id: "1", name: "Half-Life 2", coverUrl, deferCover },
    global: { stubs: { RouterLink: RouterLinkStub } }
  });
  // A real observer reports where the tile is as soon as it's observed.
  FakeIntersectionObserver.fire(onScreen);
  await wrapper.vm.$nextTick();
  return wrapper;
}

async function scrollIntoView(dwell: number) {
  FakeIntersectionObserver.fire(true);
  await vi.advanceTimersByTimeAsync(dwell);
}

describe("GameTile cover loading", () => {
  beforeEach(() => {
    vi.resetModules();
    vi.useFakeTimers();
    FakeIntersectionObserver.instances = [];
    vi.stubGlobal("IntersectionObserver", FakeIntersectionObserver);
  });

  afterEach(() => {
    wrapper?.unmount();
    wrapper = undefined;
    vi.unstubAllGlobals();
    vi.useRealTimers();
  });

  it("doesn't request the cover until the tile settles near the viewport", async () => {
    const tile = await mountTile();

    expect(tile.find("img").exists()).toBeFalsy();
    // Not the initials placeholder either: the tile has a cover, it just isn't loaded.
    expect(tile.find(".game-tile-placeholder").exists()).toBeFalsy();

    await scrollIntoView(DWELL_MS);

    expect(tile.find("img").attributes("src")).toBe(COVER);
  });

  it("loads a cover that is on screen when the tile mounts straight away", async () => {
    const tile = await mountTile(COVER, { onScreen: true });

    expect(tile.find("img").attributes("src")).toBe(COVER);
  });

  it("skips covers a fast scroll only passes over", async () => {
    const tile = await mountTile();

    await scrollIntoView(DWELL_MS - 50);
    FakeIntersectionObserver.fire(false);
    await vi.advanceTimersByTimeAsync(DWELL_MS);

    expect(tile.find("img").exists()).toBeFalsy();
  });

  it("drops a cover still loading when the tile leaves the viewport", async () => {
    const tile = await mountTile();

    await scrollIntoView(DWELL_MS);
    expect(tile.find("img").exists()).toBeTruthy();

    FakeIntersectionObserver.fire(false);
    await tile.vm.$nextTick();

    expect(tile.find("img").exists()).toBeFalsy();
  });

  it("keeps a cover that has loaded when the tile leaves the viewport", async () => {
    const tile = await mountTile();

    await scrollIntoView(DWELL_MS);
    await tile.find("img").trigger("load");
    FakeIntersectionObserver.fire(false);
    await tile.vm.$nextTick();

    expect(tile.find("img").attributes("src")).toBe(COVER);
  });

  it("shows a cover that loaded earlier this session in the first paint", async () => {
    const first = await mountTile();
    await scrollIntoView(DWELL_MS);
    await first.find("img").trigger("load");
    first.unmount();

    // Mounted again off screen, as when going back to a cached list.
    const again = await mountTile();

    expect(again.find("img").attributes("src")).toBe(COVER);
  });

  it("shows the initials straight away for a game without a cover", async () => {
    const tile = await mountTile(null);

    expect(tile.find(".game-tile-placeholder").text()).toBe("H2");
  });

  it("loads the cover right away without IntersectionObserver", async () => {
    vi.stubGlobal("IntersectionObserver", undefined);
    const tile = await mountTile();

    expect(tile.find("img").attributes("src")).toBe(COVER);
  });
});

describe("GameTile cover loading without deferCover", () => {
  beforeEach(() => {
    vi.resetModules();
    vi.stubGlobal("IntersectionObserver", FakeIntersectionObserver);
  });

  afterEach(() => {
    wrapper?.unmount();
    wrapper = undefined;
    vi.unstubAllGlobals();
  });

  // Shelves scroll sideways on phones, where the observer's margin doesn't
  // reach; the browser's own lazy loading preloads ahead there.
  it("leaves the cover to the browser's lazy loading", async () => {
    const tile = await mountTile(COVER, { deferCover: false });

    const img = tile.find("img");
    expect(img.attributes("src")).toBe(COVER);
    expect(img.attributes("loading")).toBe("lazy");
  });
});
