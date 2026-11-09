import type { BrowserOptions, ErrorEvent, Event, EventHint } from "@sentry/vue";
import { isChunkLoadError } from "./chunk-reload";

// @sentry/vue doesn't export this type itself.
export type TransactionEvent = Parameters<NonNullable<BrowserOptions["beforeSendTransaction"]>>[0];

const FILTERED = "[Filtered]";

// Any key with "token" in it, e.g. reset_password_token, or the
// query.reset_password_token span attribute the Vue router integration adds.
const SENSITIVE_KEY = /token/i;

// The value of a token-named query param in a URL or path.
const SENSITIVE_QUERY_PARAM = /([?&][^=&#]*token[^=&#]*=)[^&#]*/gi;

/**
 * Replaces the values of token query params (e.g. the password reset page's
 * ?reset_password_token=) in a URL or path.
 */
export function scrubTokenParams(value: string): string {
  return value.replace(SENSITIVE_QUERY_PARAM, `$1${FILTERED}`);
}

function scrubValue(value: unknown): unknown {
  if (typeof value === "string") {
    return scrubTokenParams(value);
  }
  if (Array.isArray(value)) {
    return value.map(scrubValue);
  }
  if (value !== null && typeof value === "object") {
    const scrubbed: Record<string, unknown> = {};
    for (const [key, child] of Object.entries(value)) {
      scrubbed[key] = SENSITIVE_KEY.test(key) && child != null ? FILTERED : scrubValue(child);
    }
    return scrubbed;
  }
  return value;
}

/**
 * Strips tokens from everywhere they can end up in an event: the page URL
 * (request.url), navigation and fetch breadcrumbs, and span attributes,
 * which the Vue router integration fills with every query param. The
 * password reset token is in the URL for as long as the reset page is open,
 * and it's valid until used, so it must never reach Sentry.
 */
export function scrubTokens<T extends Event>(event: T): T {
  return scrubValue(event) as T;
}

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

/** Sentry `beforeSend` hook: drops handled chunk errors, scrubs the rest. */
export function beforeSend(event: ErrorEvent, hint: EventHint): ErrorEvent | null {
  const kept = dropHandledChunkErrors(event, hint);
  return kept && scrubTokens(kept);
}

/** Sentry `beforeSendTransaction` hook. */
export function beforeSendTransaction(event: TransactionEvent): TransactionEvent {
  return scrubTokens(event);
}
