import { describe, expect, it } from "vitest";
import { timeAgo } from "./time";

describe("timeAgo", () => {
  const now = new Date("2026-11-05T12:00:00Z");

  it.each([
    ["2026-11-05T11:59:30Z", "just now"],
    ["2026-11-05T11:15:00Z", "45m ago"],
    ["2026-11-05T07:00:00Z", "5h ago"],
    ["2026-11-04T11:00:00Z", "1 day ago"],
    ["2026-11-01T12:00:00Z", "4 days ago"],
    ["2026-10-29T12:00:00Z", "1 week ago"],
    ["2026-10-15T12:00:00Z", "3 weeks ago"],
    ["2026-10-01T12:00:00Z", "1 month ago"],
    ["2026-05-05T12:00:00Z", "6 months ago"]
  ])("formats %s as %s", (date, expected) => {
    expect(timeAgo(date, now)).toBe(expected);
  });

  it("falls back to a date for anything a year or more old", () => {
    expect(timeAgo("2025-01-01T12:00:00Z", now)).toBe(new Date("2025-01-01T12:00:00Z").toLocaleDateString());
  });
});
