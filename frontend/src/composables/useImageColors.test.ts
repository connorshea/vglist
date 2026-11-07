import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { nextTick, ref } from "vue";
import { useImageColors } from "./useImageColors";

// jsdom neither loads images nor implements canvas, so stand in for both: each
// fake image records itself, and the test fires its load/error event by hand.
class FakeImage {
  static created: FakeImage[] = [];
  crossOrigin = "";
  src = "";
  private listeners: Record<string, (() => void)[]> = {};

  constructor() {
    FakeImage.created.push(this);
  }

  addEventListener(type: string, listener: () => void) {
    (this.listeners[type] ??= []).push(listener);
  }

  fire(type: "load" | "error") {
    for (const listener of this.listeners[type] ?? []) listener();
  }
}

// Half red, half blue, so median-cut finds more than one color.
function fakePixels(): Uint8ClampedArray {
  const size = 64 * 64;
  const pixels = new Uint8ClampedArray(size * 4);
  for (let i = 0; i < size; i++) {
    const red = i < size / 2;
    pixels.set([red ? 200 : 30, 40, red ? 30 : 200, 255], i * 4);
  }
  return pixels;
}

function imageFor(url: string): FakeImage {
  const img = FakeImage.created.findLast((i) => i.src === url);
  if (!img) throw new Error(`No image was loaded for ${url}`);
  return img;
}

beforeEach(() => {
  FakeImage.created = [];
  vi.stubGlobal("Image", FakeImage);
  vi.spyOn(HTMLCanvasElement.prototype, "getContext").mockReturnValue({
    drawImage: () => undefined,
    getImageData: () => ({ data: fakePixels() })
  } as unknown as CanvasRenderingContext2D);
});

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("useImageColors", () => {
  it("builds a gradient once the image loads", () => {
    const { gradient } = useImageColors(ref("https://example.com/a.png"));
    expect(gradient.value).toBeNull();

    imageFor("https://example.com/a.png").fire("load");
    expect(gradient.value).toMatch(/^linear-gradient\(135deg, /);
  });

  it("keeps the current gradient while a new URL loads", async () => {
    const url = ref("https://example.com/a.png?sig=1");
    const { gradient } = useImageColors(url);
    imageFor(url.value).fire("load");
    const first = gradient.value;
    expect(first).not.toBeNull();

    // A refetch hands back a freshly signed URL for the same image.
    url.value = "https://example.com/a.png?sig=2";
    await nextTick();
    expect(gradient.value).toBe(first);

    imageFor(url.value).fire("load");
    expect(gradient.value).toBe(first);
  });

  it("ignores an older image that finishes loading after a newer URL", async () => {
    const url = ref("https://example.com/a.png");
    const { gradient } = useImageColors(url);

    url.value = "https://example.com/b.png";
    await nextTick();
    imageFor("https://example.com/b.png").fire("error");
    imageFor("https://example.com/a.png").fire("load");

    expect(gradient.value).toBeNull();
  });

  it("clears the gradient when the image goes away or fails", async () => {
    const url = ref<string | null>("https://example.com/a.png");
    const { gradient } = useImageColors(url);
    imageFor("https://example.com/a.png").fire("load");
    expect(gradient.value).not.toBeNull();

    url.value = null;
    await nextTick();
    expect(gradient.value).toBeNull();

    url.value = "https://example.com/a.png";
    await nextTick();
    imageFor("https://example.com/a.png").fire("load");
    url.value = "https://example.com/broken.png";
    await nextTick();
    imageFor("https://example.com/broken.png").fire("error");
    expect(gradient.value).toBeNull();
  });
});
