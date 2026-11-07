// Geometry for the avatar cropper. The crop area is a square viewport, and all
// positions here are in viewport units, where the viewport is 1×1. That keeps
// the math independent of how big the cropper is drawn on screen.

export const MIN_ZOOM = 1;
export const MAX_ZOOM = 4;
// The largest avatar variant is 300×300, so 600 covers 2x screens with room to
// spare without uploading more than we need.
export const MAX_OUTPUT_SIZE = 600;

export interface CropState {
  // Natural size of the source image, in pixels.
  imageWidth: number;
  imageHeight: number;
  // 1 means the image's short side exactly fills the viewport.
  zoom: number;
  // Position of the image's top-left corner relative to the viewport's
  // top-left corner. Always <= 0, since the image must cover the viewport.
  x: number;
  y: number;
}

export interface SourceRect {
  sx: number;
  sy: number;
  size: number;
}

// Viewport units per image pixel at the given zoom.
export function cropScale(state: Pick<CropState, "imageWidth" | "imageHeight" | "zoom">): number {
  return state.zoom / Math.min(state.imageWidth, state.imageHeight);
}

export function clampZoom(zoom: number): number {
  return Math.min(MAX_ZOOM, Math.max(MIN_ZOOM, zoom));
}

// Keep the image covering the whole viewport, so the crop never includes
// empty space.
export function clampPosition(state: CropState): CropState {
  const scale = cropScale(state);
  const minX = 1 - state.imageWidth * scale;
  const minY = 1 - state.imageHeight * scale;
  return {
    ...state,
    x: Math.min(0, Math.max(minX, state.x)),
    y: Math.min(0, Math.max(minY, state.y))
  };
}

// Start zoomed all the way out with the image centred.
export function initialCropState(imageWidth: number, imageHeight: number): CropState {
  const scale = cropScale({ imageWidth, imageHeight, zoom: 1 });
  return {
    imageWidth,
    imageHeight,
    zoom: 1,
    x: (1 - imageWidth * scale) / 2,
    y: (1 - imageHeight * scale) / 2
  };
}

export function panBy(state: CropState, dx: number, dy: number): CropState {
  return clampPosition({ ...state, x: state.x + dx, y: state.y + dy });
}

// Zoom while keeping the image point under the viewport's centre in place.
export function zoomTo(state: CropState, zoom: number): CropState {
  const nextZoom = clampZoom(zoom);
  const ratio = nextZoom / state.zoom;
  return clampPosition({
    ...state,
    zoom: nextZoom,
    x: 0.5 - (0.5 - state.x) * ratio,
    y: 0.5 - (0.5 - state.y) * ratio
  });
}

// The square of the source image, in image pixels, that the viewport shows.
export function sourceRect(state: CropState): SourceRect {
  const scale = cropScale(state);
  return { sx: -state.x / scale, sy: -state.y / scale, size: 1 / scale };
}

// Output side length: the crop's native resolution, capped at MAX_OUTPUT_SIZE.
export function outputSize(rect: SourceRect): number {
  return Math.max(1, Math.min(MAX_OUTPUT_SIZE, Math.round(rect.size)));
}

// The server only processes PNG and JPEG. Keep PNGs as PNG so transparency
// survives, and encode everything else as JPEG.
export function outputType(sourceType: string): "image/png" | "image/jpeg" {
  return sourceType === "image/png" ? "image/png" : "image/jpeg";
}
