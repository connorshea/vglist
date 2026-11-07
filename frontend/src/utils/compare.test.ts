import { describe, expect, it } from "vitest";
import { gapDescription, gapMeter, isCompareTab, overlapShares, sharePercent } from "./compare";

describe("overlapShares", () => {
  it("splits the bar in proportion to each part", () => {
    expect(overlapShares(25, 25, 50)).toEqual({ onlyA: 25, both: 25, onlyB: 50 });
  });

  it("keeps a sliver for a part that's tiny next to the others", () => {
    const shares = overlapShares(1, 0, 999);
    expect(shares.onlyA).toBeGreaterThanOrEqual(1.9);
    expect(shares.both).toBe(0);
    expect(shares.onlyA + shares.onlyB).toBeCloseTo(100, 0);
  });

  it("is empty when both libraries are", () => {
    expect(overlapShares(0, 0, 0)).toEqual({ onlyA: 0, both: 0, onlyB: 0 });
  });
});

describe("gapMeter", () => {
  it("grows towards whoever rated the game higher, capped at a gap of 25", () => {
    expect(gapMeter(10)).toEqual({ side: "a", width: 20 });
    expect(gapMeter(-40)).toEqual({ side: "b", width: 50 });
  });

  it("is empty for the same rating or a game only one of them rated", () => {
    expect(gapMeter(0)).toBeNull();
    expect(gapMeter(null)).toBeNull();
  });
});

describe("gapDescription", () => {
  it("names who rated it higher, so the direction isn't only shown by colour", () => {
    expect(gapDescription(19, "connorshea", "kestrel")).toBe("connorshea rated it 19 higher");
    expect(gapDescription(-31, "connorshea", "kestrel")).toBe("kestrel rated it 31 higher");
    expect(gapDescription(0, "connorshea", "kestrel")).toBe("Same rating");
    expect(gapDescription(null, "connorshea", "kestrel")).toBe("Not rated by both");
  });
});

describe("sharePercent", () => {
  it("rounds to a whole percentage and handles an empty library", () => {
    expect(sharePercent(168, 412)).toBe("41%");
    expect(sharePercent(0, 0)).toBe("0%");
  });
});

describe("isCompareTab", () => {
  it("only accepts the page's tabs", () => {
    expect(isCompareTab("only-a")).toBeTruthy();
    expect(isCompareTab("library")).toBeFalsy();
    expect(isCompareTab(undefined)).toBeFalsy();
  });
});
