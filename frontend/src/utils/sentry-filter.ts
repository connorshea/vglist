import type { ErrorEvent, EventHint } from "@sentry/vue";
import { isChunkLoadError } from "./chunk-reload";

/**
 * Sentry `beforeSend` hook. Drops failed chunk loads: after a deploy, tabs
 * still running the old build request chunks that no longer exist, and the
 * router recovers by reloading the page (see chunk-reload.ts). Reporting
 * them would only open a new Sentry issue per deploy.
 */
export function dropHandledChunkErrors(event: ErrorEvent, hint: EventHint): ErrorEvent | null {
  if (isChunkLoadError(hint.originalException)) {
    return null;
  }
  // Some rejections arrive without the original Error; fall back to the
  // message Sentry extracted.
  const messages = event.exception?.values?.map((value) => value.value) ?? [];
  if (messages.some((message) => isChunkLoadError(message))) {
    return null;
  }
  return event;
}
