import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises, mount, type VueWrapper } from "@vue/test-utils";
import AvatarCropper from "./AvatarCropper.vue";

// jsdom has no canvas or image decoding, so fake both. The fake context
// records drawImage calls, which is where the crop shows up.
type DrawImageArgs = [ImageBitmap, ...number[]];

const drawImageCalls: DrawImageArgs[] = [];
const fakeContext = {
  clearRect: vi.fn<() => void>(),
  fillRect: vi.fn<() => void>(),
  drawImage: (...args: DrawImageArgs) => {
    drawImageCalls.push(args);
  },
  fillStyle: "",
  imageSmoothingQuality: "low"
};
const toBlobTypes: string[] = [];

function fakeBitmap(width: number, height: number): ImageBitmap {
  return { width, height, close: vi.fn<() => void>() } as unknown as ImageBitmap;
}

let wrapper: VueWrapper | null = null;

async function mountCropper(file: File) {
  wrapper = mount(AvatarCropper, { props: { file }, attachTo: document.body });
  await flushPromises();
  return wrapper;
}

function canvas(): HTMLCanvasElement {
  const el = document.body.querySelector<HTMLCanvasElement>("canvas.ac-canvas");
  if (!el) throw new Error("crop canvas not rendered");
  return el;
}

function button(label: string): HTMLButtonElement {
  const el = Array.from(document.body.querySelectorAll<HTMLButtonElement>(".ac-btn")).find((b) =>
    b.textContent?.includes(label)
  );
  if (!el) throw new Error(`no button labelled ${label}`);
  return el;
}

// The source rectangle (sx, sy, size) of the last export drawImage call, i.e.
// the 9-argument form.
function lastExportRect(): { sx: number; sy: number; size: number } {
  const call = [...drawImageCalls].reverse().find((args) => args.length === 9);
  if (!call) throw new Error("image was never exported");
  const [, sx, sy, size] = call;
  return { sx, sy, size };
}

beforeEach(() => {
  drawImageCalls.length = 0;
  toBlobTypes.length = 0;
  vi.stubGlobal("createImageBitmap", vi.fn<() => Promise<ImageBitmap>>().mockResolvedValue(fakeBitmap(1600, 800)));
  vi.spyOn(HTMLCanvasElement.prototype, "getContext").mockImplementation(
    () => fakeContext as unknown as CanvasRenderingContext2D
  );
  vi.spyOn(HTMLCanvasElement.prototype, "toBlob").mockImplementation(function (callback, type) {
    toBlobTypes.push(type ?? "");
    callback(new Blob(["cropped"], { type: type ?? "image/png" }));
  });
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = null;
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("AvatarCropper", () => {
  it("renders an accessible dialog and focuses the crop area", async () => {
    await mountCropper(new File(["x"], "photo.jpg", { type: "image/jpeg" }));

    const dialog = document.body.querySelector('[role="dialog"]');
    expect(dialog?.getAttribute("aria-modal")).toBe("true");
    expect(dialog?.getAttribute("aria-labelledby")).toBe("ac-title");
    expect(document.activeElement).toBe(canvas());
  });

  it("exports the centred square at full resolution, capped at 600px", async () => {
    await mountCropper(new File(["x"], "photo.jpg", { type: "image/jpeg" }));

    button("Save avatar").click();
    await flushPromises();

    const saved = wrapper?.emitted("save")?.[0]?.[0];
    expect(saved).toBeInstanceOf(Blob);
    expect(toBlobTypes).toEqual(["image/jpeg"]);
    const rect = lastExportRect();
    expect(rect.sx).toBeCloseTo(400);
    expect(rect.sy).toBeCloseTo(0);
    expect(rect.size).toBeCloseTo(800);
    const exportCall = drawImageCalls.at(-1);
    expect(exportCall?.slice(5)).toEqual([0, 0, 600, 600]);
  });

  it("keeps PNGs as PNG", async () => {
    await mountCropper(new File(["x"], "logo.png", { type: "image/png" }));

    button("Save avatar").click();
    await flushPromises();

    expect(toBlobTypes).toEqual(["image/png"]);
  });

  it("moves and zooms the crop with the keyboard", async () => {
    await mountCropper(new File(["x"], "photo.jpg", { type: "image/jpeg" }));

    canvas().dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowLeft", shiftKey: true, bubbles: true }));
    canvas().dispatchEvent(new KeyboardEvent("keydown", { key: "+", bubbles: true }));
    await flushPromises();
    button("Save avatar").click();
    await flushPromises();

    // Moving the image left moves the crop right, and zooming in shrinks it.
    const rect = lastExportRect();
    expect(rect.sx).toBeGreaterThan(400);
    expect(rect.size).toBeLessThan(800);
  });

  it("zooms with the slider", async () => {
    await mountCropper(new File(["x"], "photo.jpg", { type: "image/jpeg" }));

    const slider = document.body.querySelector<HTMLInputElement>('input[type="range"]');
    if (!slider) throw new Error("no zoom slider");
    slider.value = "2";
    slider.dispatchEvent(new Event("input", { bubbles: true }));
    await flushPromises();
    button("Save avatar").click();
    await flushPromises();

    expect(lastExportRect().size).toBeCloseTo(400);
  });

  it("emits cancel on Escape and from the Cancel button", async () => {
    await mountCropper(new File(["x"], "photo.jpg", { type: "image/jpeg" }));

    canvas().dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }));
    button("Cancel").click();

    expect(wrapper?.emitted("cancel")).toHaveLength(2);
  });

  it("shows an error for files that aren't images", async () => {
    await mountCropper(new File(["x"], "notes.txt", { type: "text/plain" }));

    expect(document.body.querySelector('[role="alert"]')?.textContent).toContain("couldn't be opened");
    expect(button("Save avatar").disabled).toBeTruthy();
  });

  it("shows an error when the browser can't decode the image", async () => {
    vi.stubGlobal("createImageBitmap", vi.fn<() => Promise<ImageBitmap>>().mockRejectedValue(new Error("decode")));

    await mountCropper(new File(["x"], "photo.heic", { type: "image/heic" }));

    expect(document.body.querySelector('[role="alert"]')?.textContent).toContain("couldn't be opened");
  });

  it("shows the upload error passed in by the parent and disables Save while saving", async () => {
    await mountCropper(new File(["x"], "photo.jpg", { type: "image/jpeg" }));

    await wrapper?.setProps({ saving: true, error: "Avatar must be a square image" });

    expect(document.body.querySelector('[role="alert"]')?.textContent).toContain("Avatar must be a square image");
    expect(button("Saving…").disabled).toBeTruthy();
  });
});
