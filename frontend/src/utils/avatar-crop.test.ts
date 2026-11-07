import { describe, expect, it } from "vitest";
import {
  MAX_OUTPUT_SIZE,
  MAX_ZOOM,
  initialCropState,
  outputSize,
  outputType,
  panBy,
  sourceRect,
  zoomTo
} from "./avatar-crop";
// Compare with a tolerance: the math produces values like -0 and 399.99999.
function rectCloseTo(sx: number, sy: number, size: number) {
  return { sx: expect.closeTo(sx), sy: expect.closeTo(sy), size: expect.closeTo(size) };
}

describe("initialCropState", () => {
  it("centres a landscape image with its height filling the viewport", () => {
    const state = initialCropState(1600, 800);
    expect(state.zoom).toBe(1);
    expect(state.x).toBeCloseTo(-0.5);
    expect(state.y).toBe(0);
    expect(sourceRect(state)).toEqual(rectCloseTo(400, 0, 800));
  });

  it("centres a portrait image with its width filling the viewport", () => {
    const state = initialCropState(600, 900);
    expect(sourceRect(state)).toEqual(rectCloseTo(0, 150, 600));
  });
});

describe("panBy", () => {
  it("moves the crop", () => {
    const state = panBy(initialCropState(1600, 800), 0.25, 0);
    expect(sourceRect(state).sx).toBeCloseTo(200);
  });

  it("won't pan past the image's edges", () => {
    const start = initialCropState(1600, 800);
    expect(sourceRect(panBy(start, 10, 10))).toEqual(rectCloseTo(0, 0, 800));
    expect(sourceRect(panBy(start, -10, -10)).sx).toBeCloseTo(800);
    expect(sourceRect(panBy(start, -10, -10)).sy).toBeCloseTo(0);
  });
});

describe("zoomTo", () => {
  it("zooms around the centre of the viewport", () => {
    const state = zoomTo(initialCropState(1000, 1000), 2);
    const rect = sourceRect(state);
    expect(rect.size).toBeCloseTo(500);
    expect(rect.sx).toBeCloseTo(250);
    expect(rect.sy).toBeCloseTo(250);
  });

  it("clamps the zoom level", () => {
    const start = initialCropState(1000, 1000);
    expect(zoomTo(start, 100).zoom).toBe(MAX_ZOOM);
    expect(zoomTo(start, 0.1).zoom).toBe(1);
  });

  it("keeps the image covering the viewport when zooming out near an edge", () => {
    let state = zoomTo(initialCropState(1000, 1000), 4);
    state = panBy(state, 10, 10);
    state = zoomTo(state, 1);
    expect(sourceRect(state)).toEqual(rectCloseTo(0, 0, 1000));
  });
});

describe("outputSize", () => {
  it("caps large crops", () => {
    expect(outputSize({ sx: 0, sy: 0, size: 3000 })).toBe(MAX_OUTPUT_SIZE);
  });

  it("doesn't upscale small crops", () => {
    expect(outputSize({ sx: 0, sy: 0, size: 240.4 })).toBe(240);
  });
});

describe("outputType", () => {
  it("keeps PNGs as PNG and encodes everything else as JPEG", () => {
    expect(outputType("image/png")).toBe("image/png");
    expect(outputType("image/jpeg")).toBe("image/jpeg");
    expect(outputType("image/webp")).toBe("image/jpeg");
    expect(outputType("")).toBe("image/jpeg");
  });
});
