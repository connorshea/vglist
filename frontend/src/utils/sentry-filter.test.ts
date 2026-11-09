import { afterEach, describe, it, expect, vi } from "vitest";
import type { ErrorEvent } from "@sentry/vue";
import type { TransactionEvent } from "./sentry-filter";
import {
  beforeSend,
  beforeSendTransaction,
  dropHandledChunkErrors,
  isAutomatedBrowser,
  scrubTokenParams,
  TRACES_SAMPLE_RATE,
  tracesSampler
} from "./sentry-filter";

const CHROME =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36";
const HEADLESS_CHROME = CHROME.replace("Chrome/", "HeadlessChrome/");

function eventWith(message: string): ErrorEvent {
  return { type: undefined, exception: { values: [{ type: "TypeError", value: message }] } };
}

describe("dropHandledChunkErrors", () => {
  const chunkMessage = "Failed to fetch dynamically imported module: https://vglist.co/assets/GameShowPage-abc123.js";

  it("drops chunk load errors by the original exception", () => {
    const error = new TypeError(chunkMessage);
    expect(dropHandledChunkErrors(eventWith(chunkMessage), { originalException: error })).toBeNull();
  });

  it("drops CSS preload errors by the event message when the original is missing", () => {
    const event = eventWith("Unable to preload CSS for https://vglist.co/assets/SkeletonBlock-abc123.css");
    expect(dropHandledChunkErrors(event, {})).toBeNull();
  });

  it("keeps other errors", () => {
    const event = eventWith("Cannot read properties of undefined (reading 'id')");
    const hint = { originalException: new TypeError("Cannot read properties of undefined (reading 'id')") };
    expect(dropHandledChunkErrors(event, hint)).toBe(event);
  });
});

describe("scrubTokenParams", () => {
  it("filters token query params in absolute URLs and paths", () => {
    expect(scrubTokenParams("https://vglist.co/password/reset/confirm?reset_password_token=abc123")).toBe(
      "https://vglist.co/password/reset/confirm?reset_password_token=[Filtered]"
    );
    expect(scrubTokenParams("/confirm?a=1&confirmation_token=abc&b=2#top")).toBe(
      "/confirm?a=1&confirmation_token=[Filtered]&b=2#top"
    );
  });

  it("leaves other query params alone", () => {
    expect(scrubTokenParams("/games?page=2&redirect=%2Fsettings")).toBe("/games?page=2&redirect=%2Fsettings");
  });
});

describe("beforeSend", () => {
  const resetUrl = "https://vglist.co/password/reset/confirm?reset_password_token=secret";

  it("scrubs the token from the request URL and breadcrumbs", () => {
    const event: ErrorEvent = {
      type: undefined,
      request: { url: resetUrl },
      breadcrumbs: [{ category: "navigation", data: { from: "/password/reset", to: resetUrl } }]
    };

    const scrubbed = beforeSend(event, {});

    expect(JSON.stringify(scrubbed)).not.toContain("secret");
    expect(scrubbed?.request?.url).toBe("https://vglist.co/password/reset/confirm?reset_password_token=[Filtered]");
    expect(scrubbed?.breadcrumbs?.[0]?.data?.from).toBe("/password/reset");
  });

  it("still drops chunk load errors", () => {
    const message = "Failed to fetch dynamically imported module: https://vglist.co/assets/A-abc.js";
    expect(beforeSend(eventWith(message), { originalException: new TypeError(message) })).toBeNull();
  });
});

describe("beforeSendTransaction", () => {
  it("scrubs token-named span attributes from the Vue router integration", () => {
    const event: TransactionEvent = {
      type: "transaction",
      contexts: {
        trace: {
          trace_id: "t",
          span_id: "s",
          data: { "query.reset_password_token": "secret", "query.page": "2" }
        }
      },
      spans: [
        {
          span_id: "c",
          trace_id: "t",
          start_timestamp: 0,
          status: "ok",
          data: { "url.full": "https://vglist.co/password/reset/confirm?reset_password_token=secret" }
        }
      ]
    };

    const scrubbed = beforeSendTransaction(event);

    expect(JSON.stringify(scrubbed)).not.toContain("secret");
    expect(scrubbed.contexts?.trace?.data?.["query.reset_password_token"]).toBe("[Filtered]");
    expect(scrubbed.contexts?.trace?.data?.["query.page"]).toBe("2");
  });
});

describe("isAutomatedBrowser", () => {
  it("is false for a regular browser", () => {
    expect(isAutomatedBrowser({ userAgent: CHROME, webdriver: false })).toBeFalsy();
  });

  it("detects headless Chrome by its user agent", () => {
    expect(isAutomatedBrowser({ userAgent: HEADLESS_CHROME, webdriver: false })).toBeTruthy();
  });

  it("detects a WebDriver-controlled browser with a regular user agent", () => {
    expect(isAutomatedBrowser({ userAgent: CHROME, webdriver: true })).toBeTruthy();
  });
});

describe("tracesSampler", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("samples regular browsers at the normal rate", () => {
    vi.stubGlobal("navigator", { userAgent: CHROME, webdriver: false });
    expect(tracesSampler()).toBe(TRACES_SAMPLE_RATE);
  });

  it("never samples automated browsers", () => {
    vi.stubGlobal("navigator", { userAgent: HEADLESS_CHROME, webdriver: false });
    expect(tracesSampler()).toBe(0);
  });
});
