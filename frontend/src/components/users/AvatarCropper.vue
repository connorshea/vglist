<template>
  <Teleport to="body">
    <div class="ac-overlay" role="dialog" aria-modal="true" aria-labelledby="ac-title" @keydown="onDialogKeydown">
      <div class="ac-backdrop" @click="cancel"></div>
      <div ref="dialogRef" class="ac-modal" tabindex="-1">
        <h2 id="ac-title" class="ac-title">Crop your avatar</h2>

        <p v-if="loadError" class="ac-error" role="alert">{{ loadError }}</p>
        <template v-else>
          <canvas
            ref="canvasRef"
            class="ac-canvas"
            :class="{ 'is-dragging': pointers.size > 0 }"
            :width="CANVAS_SIZE"
            :height="CANVAS_SIZE"
            tabindex="0"
            role="application"
            aria-label="Avatar crop area"
            aria-describedby="ac-help"
            @pointerdown="onPointerDown"
            @pointermove="onPointerMove"
            @pointerup="onPointerUp"
            @pointercancel="onPointerUp"
            @wheel.prevent="onWheel"
            @keydown="onCanvasKeydown"
          ></canvas>
          <p id="ac-help" class="ac-help">
            Drag or use the arrow keys to move the image. Scroll, pinch, or press + and − to zoom.
          </p>

          <div class="ac-zoom">
            <ZoomOut :size="16" :stroke-width="2" aria-hidden="true" />
            <input
              class="ac-zoom-slider"
              type="range"
              aria-label="Zoom"
              :min="MIN_ZOOM"
              :max="MAX_ZOOM"
              step="0.01"
              :value="state?.zoom ?? MIN_ZOOM"
              :disabled="!state"
              @input="onZoomInput"
            />
            <ZoomIn :size="16" :stroke-width="2" aria-hidden="true" />
          </div>
        </template>

        <p v-if="cropError || error" class="ac-error" role="alert">{{ cropError || error }}</p>

        <div class="ac-actions">
          <button type="button" class="ac-btn ac-btn-cancel" @click="cancel">Cancel</button>
          <button type="button" class="ac-btn ac-btn-primary" :disabled="!state || saving" @click="save">
            {{ saving ? "Saving…" : "Save avatar" }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { nextTick, onBeforeUnmount, onMounted, ref, shallowRef, watch } from "vue";
import { ZoomIn, ZoomOut } from "@lucide/vue";
import {
  MAX_ZOOM,
  MIN_ZOOM,
  type CropState,
  cropScale,
  initialCropState,
  outputSize,
  outputType,
  panBy,
  sourceRect,
  zoomTo
} from "@/utils/avatar-crop";

// Pixel size of the preview canvas. It's drawn at up to 300 CSS pixels, so
// this stays sharp on 2x screens.
const CANVAS_SIZE = 600;
// How far one arrow key press moves the image, in viewport units.
const KEY_PAN_STEP = 0.02;
const KEY_PAN_STEP_LARGE = 0.1;
const KEY_ZOOM_STEP = 0.1;

const props = withDefaults(
  defineProps<{
    file: File;
    saving?: boolean;
    error?: string;
  }>(),
  { saving: false, error: "" }
);

const emit = defineEmits<{
  cancel: [];
  save: [blob: Blob];
}>();

const dialogRef = ref<HTMLElement | null>(null);
const canvasRef = ref<HTMLCanvasElement | null>(null);
const image = shallowRef<ImageBitmap | null>(null);
const state = ref<CropState | null>(null);
const loadError = ref("");
// Active pointers, for dragging with one and pinch-zooming with two.
const pointers = ref(new Map<number, { x: number; y: number }>());
let previouslyFocusedElement: HTMLElement | null = null;

async function loadImage(file: File) {
  image.value?.close();
  image.value = null;
  state.value = null;
  loadError.value = "";

  try {
    if (!file.type.startsWith("image/")) {
      throw new Error("not an image");
    }
    // Browsers apply EXIF orientation by default, so phone photos aren't
    // sideways.
    const bitmap = await createImageBitmap(file);
    image.value = bitmap;
    state.value = initialCropState(bitmap.width, bitmap.height);
  } catch {
    loadError.value = "That file couldn't be opened as an image. Try a PNG or JPEG.";
  }
}

function draw() {
  const canvas = canvasRef.value;
  const bitmap = image.value;
  const crop = state.value;
  if (!canvas || !bitmap || !crop) {
    return;
  }

  const ctx = canvas.getContext("2d");
  if (!ctx) {
    return;
  }

  const scale = cropScale(crop) * CANVAS_SIZE;
  ctx.clearRect(0, 0, CANVAS_SIZE, CANVAS_SIZE);
  ctx.imageSmoothingQuality = "high";
  ctx.drawImage(bitmap, crop.x * CANVAS_SIZE, crop.y * CANVAS_SIZE, bitmap.width * scale, bitmap.height * scale);
}

watch([state, canvasRef], draw, { flush: "post" });
watch(() => props.file, loadImage);

// Convert a distance in CSS pixels on the canvas into viewport units.
function toViewportUnits(pixels: number): number {
  const width = canvasRef.value?.clientWidth ?? 0;
  return width > 0 ? pixels / width : 0;
}

function pinchDistance(): number | null {
  if (pointers.value.size !== 2) {
    return null;
  }
  const [a, b] = Array.from(pointers.value.values());
  return Math.hypot(a.x - b.x, a.y - b.y);
}

function onPointerDown(e: PointerEvent) {
  if (!state.value) {
    return;
  }
  canvasRef.value?.setPointerCapture?.(e.pointerId);
  pointers.value.set(e.pointerId, { x: e.clientX, y: e.clientY });
}

function onPointerMove(e: PointerEvent) {
  const previous = pointers.value.get(e.pointerId);
  if (!previous || !state.value) {
    return;
  }

  const distanceBefore = pinchDistance();
  pointers.value.set(e.pointerId, { x: e.clientX, y: e.clientY });

  if (distanceBefore !== null) {
    const distanceAfter = pinchDistance();
    if (distanceAfter !== null && distanceBefore > 0) {
      state.value = zoomTo(state.value, state.value.zoom * (distanceAfter / distanceBefore));
    }
    return;
  }

  state.value = panBy(state.value, toViewportUnits(e.clientX - previous.x), toViewportUnits(e.clientY - previous.y));
}

function onPointerUp(e: PointerEvent) {
  pointers.value.delete(e.pointerId);
}

function onWheel(e: WheelEvent) {
  if (!state.value) {
    return;
  }
  state.value = zoomTo(state.value, state.value.zoom * Math.exp(-e.deltaY * 0.002));
}

function onZoomInput(e: Event) {
  if (!state.value) {
    return;
  }
  state.value = zoomTo(state.value, Number((e.target as HTMLInputElement).value));
}

function onCanvasKeydown(e: KeyboardEvent) {
  const crop = state.value;
  if (!crop) {
    return;
  }

  const step = e.shiftKey ? KEY_PAN_STEP_LARGE : KEY_PAN_STEP;
  const moves: Record<string, [number, number]> = {
    ArrowLeft: [-step, 0],
    ArrowRight: [step, 0],
    ArrowUp: [0, -step],
    ArrowDown: [0, step]
  };

  if (e.key in moves) {
    const [dx, dy] = moves[e.key];
    state.value = panBy(crop, dx, dy);
  } else if (e.key === "+" || e.key === "=") {
    state.value = zoomTo(crop, crop.zoom + KEY_ZOOM_STEP);
  } else if (e.key === "-" || e.key === "_") {
    state.value = zoomTo(crop, crop.zoom - KEY_ZOOM_STEP);
  } else {
    return;
  }
  e.preventDefault();
}

function cropToBlob(bitmap: ImageBitmap, crop: CropState): Promise<Blob> {
  const rect = sourceRect(crop);
  const size = outputSize(rect);
  const type = outputType(props.file.type);

  const canvas = document.createElement("canvas");
  canvas.width = size;
  canvas.height = size;
  const ctx = canvas.getContext("2d");
  if (!ctx) {
    return Promise.reject(new Error("Your browser couldn't crop this image."));
  }

  // JPEG has no transparency, so give transparent images a white background
  // instead of black.
  if (type === "image/jpeg") {
    ctx.fillStyle = "#fff";
    ctx.fillRect(0, 0, size, size);
  }
  ctx.imageSmoothingQuality = "high";
  ctx.drawImage(bitmap, rect.sx, rect.sy, rect.size, rect.size, 0, 0, size, size);

  return new Promise((resolve, reject) => {
    canvas.toBlob(
      (blob) => (blob ? resolve(blob) : reject(new Error("Your browser couldn't crop this image."))),
      type,
      0.9
    );
  });
}

const cropError = ref("");

async function save() {
  if (!image.value || !state.value || props.saving) {
    return;
  }
  cropError.value = "";
  try {
    emit("save", await cropToBlob(image.value, state.value));
  } catch (e) {
    cropError.value = e instanceof Error ? e.message : "Your browser couldn't crop this image.";
  }
}

function cancel() {
  emit("cancel");
}

function getFocusableElements(): HTMLElement[] {
  if (!dialogRef.value) {
    return [];
  }
  return Array.from(
    dialogRef.value.querySelectorAll<HTMLElement>(
      'button:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex="-1"])'
    )
  );
}

function onDialogKeydown(e: KeyboardEvent) {
  if (e.key === "Escape") {
    cancel();
    return;
  }

  if (e.key === "Tab") {
    const focusable = getFocusableElements();
    if (focusable.length === 0) {
      return;
    }

    const first = focusable[0];
    const last = focusable[focusable.length - 1];

    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault();
      last.focus();
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault();
      first.focus();
    }
  }
}

onMounted(async () => {
  previouslyFocusedElement = document.activeElement as HTMLElement | null;
  await loadImage(props.file);
  await nextTick();
  (canvasRef.value ?? dialogRef.value)?.focus();
});

onBeforeUnmount(() => {
  image.value?.close();
  previouslyFocusedElement?.focus();
});
</script>

<style scoped>
.ac-overlay {
  position: fixed;
  inset: 0;
  z-index: 100;
  display: flex;
  align-items: center;
  justify-content: center;
}

.ac-backdrop {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.45);
}

.ac-modal {
  position: relative;
  width: calc(100% - 32px);
  max-width: 360px;
  padding: 24px;
  border-radius: 16px;
  background: var(--color-surface);
  box-shadow:
    0 16px 48px rgba(0, 0, 0, 0.12),
    0 2px 8px rgba(0, 0, 0, 0.06);
  outline: none;
}

.ac-title {
  margin: 0 0 16px;
  font-size: 17px;
  font-weight: 600;
  color: var(--color-text-primary);
}

.ac-canvas {
  display: block;
  width: 100%;
  max-width: 300px;
  aspect-ratio: 1;
  margin: 0 auto;
  border-radius: 18px;
  background: var(--color-bg-subtle);
  cursor: grab;
  /* Let pointer events handle drag and pinch instead of the page scrolling. */
  touch-action: none;
}

.ac-canvas.is-dragging {
  cursor: grabbing;
}

.ac-canvas:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 3px;
}

.ac-help {
  margin: 10px 0 0;
  font-size: 12px;
  line-height: 1.5;
  color: var(--color-text-secondary);
  text-align: center;
}

.ac-zoom {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 14px;
  color: var(--color-text-secondary);
}

.ac-zoom-slider {
  flex: 1;
  accent-color: var(--color-accent);
}

.ac-zoom-slider:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.ac-error {
  margin: 12px 0 0;
  font-size: 13px;
  color: var(--color-danger-text);
}

.ac-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  margin-top: 20px;
}

.ac-btn {
  padding: 9px 18px;
  border-radius: var(--radius-sm);
  font: inherit;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
}

.ac-btn:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.ac-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.ac-btn-cancel {
  border: 1px solid var(--color-border);
  background: var(--color-surface);
  color: var(--color-text-secondary);
}

.ac-btn-cancel:hover {
  background: var(--color-bg-subtle);
  color: var(--color-text-primary);
}

.ac-btn-primary {
  border: 1px solid var(--p-500);
  background: var(--p-500);
  color: #fff;
}

.ac-btn-primary:hover:not(:disabled) {
  background: var(--p-600);
  border-color: var(--p-600);
}

@media (prefers-color-scheme: dark) {
  .ac-modal {
    border: 1px solid var(--s-300);
    box-shadow:
      0 16px 48px rgba(0, 0, 0, 0.35),
      0 2px 8px rgba(0, 0, 0, 0.2);
  }

  .ac-error {
    color: var(--r-200);
  }
}
</style>
