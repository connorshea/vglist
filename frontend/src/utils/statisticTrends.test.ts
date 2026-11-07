import { describe, it, expect } from "vitest";
import { computeTrend, sparklinePoints, type TrendSnapshot } from "./statisticTrends";

const NOW = new Date("2026-11-07T18:00:00Z");

// Daily midnight-UTC snapshots, newest first, for the given values (oldest first).
function daily(values: (number | null)[]): TrendSnapshot[] {
  const latest = Date.UTC(2026, 10, 7);
  return values
    .map((value, i) => ({
      timestamp: new Date(latest - (values.length - 1 - i) * 86_400_000).toISOString(),
      value
    }))
    .reverse();
}

describe("computeTrend", () => {
  it("measures the change from the snapshot closest to the start of the range", () => {
    // 11 snapshots: Oct 28 (100) through Nov 7 (110).
    const snapshots = daily([100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110]);
    const trend = computeTrend(snapshots, 112, 7, NOW);

    // Seven days before Nov 7 18:00 is Oct 31 18:00, closest to the Nov 1 snapshot (104).
    expect(trend.delta).toBe(8);
    expect(trend.partialSince).toBeNull();
    expect(trend.points).toEqual([104, 105, 106, 107, 108, 109, 110, 112]);
  });

  it("flags a range that history doesn't fully cover", () => {
    const trend = computeTrend(daily([50, 52, 55]), 56, 30, NOW);

    expect(trend.delta).toBe(6);
    expect(trend.partialSince).toBe("2026-11-05T00:00:00.000Z");
    expect(trend.points).toEqual([50, 52, 55, 56]);
  });

  it("skips snapshots that predate the column", () => {
    const trend = computeTrend(daily([null, null, 10, 12]), 13, 7, NOW);

    expect(trend.delta).toBe(3);
    expect(trend.points).toEqual([10, 12, 13]);
  });

  it("has no delta without any usable history", () => {
    expect(computeTrend([], 5, 7, NOW)).toEqual({ delta: null, partialSince: null, points: [] });
    expect(computeTrend(daily([null, null]), 5, 7, NOW).delta).toBeNull();
  });
});

describe("sparklinePoints", () => {
  it("scales values to fill the box, oldest on the left", () => {
    expect(sparklinePoints([0, 5, 10], 100, 20, 0)).toBe("0,20 50,10 100,0");
  });

  it("draws a flat series through the middle", () => {
    expect(sparklinePoints([3, 3], 100, 20)).toBe("0,10 100,10");
    expect(sparklinePoints([7], 100, 20)).toBe("0,10 100,10");
  });

  it("returns nothing for no values", () => {
    expect(sparklinePoints([], 100, 20)).toBe("");
  });
});
