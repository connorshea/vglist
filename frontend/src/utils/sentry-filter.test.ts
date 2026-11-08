import { describe, it, expect } from "vitest";
import type { ErrorEvent } from "@sentry/vue";
import { dropHandledChunkErrors } from "./sentry-filter";

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
