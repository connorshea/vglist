import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, ref, type Ref } from "vue";
import { mount, type VueWrapper } from "@vue/test-utils";
import type * as NearViewportModule from "./useNearViewport";

// GameTile.test.ts covers the dwell behavior through a real tile. These cover
// the composable's own bookkeeping: one shared observer, entries routed to the
// right element, and cleanup on unmount.

class FakeIntersectionObserver {
  static instances: FakeIntersectionObserver[] = [];
  targets = new Set<Element>();

  constructor(
    private callback: IntersectionObserverCallback,
    public options?: IntersectionObserverInit
  ) {
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

  // Reports one element as having entered or left the root margin, the way a
  // real observer would only for elements it is watching.
  static fire(target: Element, isIntersecting: boolean) {
    for (const observer of FakeIntersectionObserver.instances) {
      if (observer.targets.has(target)) {
        observer.callback(
          [{ target, isIntersecting } as unknown as IntersectionObserverEntry],
          observer as unknown as IntersectionObserver
        );
      }
    }
  }
}

let mod: typeof NearViewportModule;
const wrappers: VueWrapper[] = [];

function mountNear(enabled = true): { near: Readonly<Ref<boolean>>; el: () => Element; wrapper: VueWrapper } {
  let near: Readonly<Ref<boolean>> | null = null;
  const wrapper = mount(
    defineComponent({
      setup() {
        const target = ref<Element | null>(null);
        near = mod.useNearViewport(target, enabled);
        return () => h("div", { ref: target });
      }
    })
  );
  wrappers.push(wrapper);
  return { near: near!, el: () => wrapper.element as Element, wrapper };
}

describe("useNearViewport", () => {
  beforeEach(async () => {
    // The shared observer lives at module level, so each test gets a fresh copy.
    vi.resetModules();
    vi.useFakeTimers({ toFake: ["setTimeout", "clearTimeout"] });
    FakeIntersectionObserver.instances = [];
    vi.stubGlobal("IntersectionObserver", FakeIntersectionObserver);
    mod = await import("./useNearViewport");
  });

  afterEach(() => {
    for (const wrapper of wrappers.splice(0)) {
      wrapper.unmount();
    }
    vi.unstubAllGlobals();
    vi.useRealTimers();
  });

  it("is always true when disabled, without observing anything", () => {
    const { near } = mountNear(false);
    expect(near.value).toBeTruthy();
    expect(FakeIntersectionObserver.instances).toHaveLength(0);
  });

  it("is always true without IntersectionObserver", async () => {
    vi.unstubAllGlobals();
    vi.stubGlobal("IntersectionObserver", undefined);
    vi.resetModules();
    mod = await import("./useNearViewport");
    expect(mountNear().near.value).toBeTruthy();
  });

  it("shares one observer, with a margin around the viewport, between every element", () => {
    const a = mountNear();
    const b = mountNear();
    expect(FakeIntersectionObserver.instances).toHaveLength(1);
    const [observer] = FakeIntersectionObserver.instances;
    expect(observer.options?.rootMargin).toBe("300px 0px");
    expect([...observer.targets]).toEqual([a.el(), b.el()]);
  });

  it("only updates the element an entry is for", () => {
    const a = mountNear();
    const b = mountNear();
    FakeIntersectionObserver.fire(a.el(), true);
    expect(a.near.value).toBeTruthy();
    expect(b.near.value).toBeFalsy();
  });

  it("counts an element that is near on its first report straight away", () => {
    const { near, el } = mountNear();
    FakeIntersectionObserver.fire(el(), true);
    expect(near.value).toBeTruthy();
  });

  it("waits out the dwell for an element that scrolls near later", () => {
    const { near, el } = mountNear();
    FakeIntersectionObserver.fire(el(), false);
    FakeIntersectionObserver.fire(el(), true);
    vi.advanceTimersByTime(mod.NEAR_VIEWPORT_DWELL_MS - 1);
    expect(near.value).toBeFalsy();
    vi.advanceTimersByTime(1);
    expect(near.value).toBeTruthy();
  });

  it("restarts the dwell when an element leaves and comes back", () => {
    const { near, el } = mountNear();
    FakeIntersectionObserver.fire(el(), false);
    FakeIntersectionObserver.fire(el(), true);
    vi.advanceTimersByTime(mod.NEAR_VIEWPORT_DWELL_MS - 10);
    FakeIntersectionObserver.fire(el(), false);
    FakeIntersectionObserver.fire(el(), true);
    vi.advanceTimersByTime(mod.NEAR_VIEWPORT_DWELL_MS - 10);
    expect(near.value).toBeFalsy();
    vi.advanceTimersByTime(10);
    expect(near.value).toBeTruthy();
  });

  it("stops observing on unmount, and cancels a pending dwell", () => {
    const { near, el, wrapper } = mountNear();
    const element = el();
    FakeIntersectionObserver.fire(element, false);
    FakeIntersectionObserver.fire(element, true);
    wrapper.unmount();
    wrappers.splice(wrappers.indexOf(wrapper), 1);

    expect(FakeIntersectionObserver.instances[0].targets.has(element)).toBeFalsy();
    expect(vi.getTimerCount()).toBe(0);
    vi.advanceTimersByTime(mod.NEAR_VIEWPORT_DWELL_MS);
    expect(near.value).toBeFalsy();
  });

  it("keeps observing other elements after one unmounts", () => {
    const a = mountNear();
    const b = mountNear();
    a.wrapper.unmount();
    wrappers.splice(wrappers.indexOf(a.wrapper), 1);
    FakeIntersectionObserver.fire(b.el(), true);
    expect(b.near.value).toBeTruthy();
  });
});
