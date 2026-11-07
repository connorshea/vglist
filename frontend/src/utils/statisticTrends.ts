const DAY_MS = 24 * 60 * 60 * 1000;

/** A daily statistics snapshot, reduced to its timestamp and one value. */
export interface TrendSnapshot {
  timestamp: string;
  value: number | null;
}

export interface Trend {
  /** How much the value changed over the range, or null with no usable history. */
  delta: number | null;
  /**
   * Set when history doesn't reach back the full range: the timestamp of the
   * oldest snapshot the delta is measured from.
   */
  partialSince: string | null;
  /** Values oldest first, ending with the current value, for a sparkline. */
  points: number[];
}

/**
 * Works out how a statistic has moved over the last `rangeDays` days.
 *
 * `snapshots` come newest first, as the siteStatistics connection returns
 * them. The baseline is the snapshot closest to `rangeDays` before `now`;
 * snapshots that predate a column (older records return null) are skipped.
 */
export function computeTrend(snapshots: TrendSnapshot[], current: number, rangeDays: number, now: Date): Trend {
  const usable = snapshots
    .filter((s): s is { timestamp: string; value: number } => s.value !== null)
    .map((s) => ({ time: new Date(s.timestamp).getTime(), value: s.value }))
    .sort((a, b) => a.time - b.time);

  if (usable.length === 0) return { delta: null, partialSince: null, points: [] };

  const cutoff = now.getTime() - rangeDays * DAY_MS;
  let baselineIndex = 0;
  let closest = Infinity;
  usable.forEach((s, i) => {
    const distance = Math.abs(s.time - cutoff);
    if (distance < closest) {
      closest = distance;
      baselineIndex = i;
    }
  });

  const baseline = usable[baselineIndex];
  // Snapshots are daily, so anything more than a day short of the cutoff
  // means the history doesn't cover the whole range.
  const partial = baseline.time - cutoff > DAY_MS;

  return {
    delta: current - baseline.value,
    partialSince: partial ? new Date(baseline.time).toISOString() : null,
    points: [...usable.slice(baselineIndex).map((s) => s.value), current]
  };
}

/**
 * Turns values into SVG polyline points inside a `width` x `height` box,
 * leaving `pad` px at the top and bottom so the stroke isn't clipped. A flat
 * series draws a line through the middle.
 */
export function sparklinePoints(values: number[], width: number, height: number, pad = 2): string {
  if (values.length === 0) return "";
  const series = values.length === 1 ? [values[0], values[0]] : values;
  const min = Math.min(...series);
  const max = Math.max(...series);
  const usableHeight = height - pad * 2;

  return series
    .map((value, i) => {
      const x = (i / (series.length - 1)) * width;
      const y = max === min ? height / 2 : pad + usableHeight - ((value - min) / (max - min)) * usableHeight;
      return `${round(x)},${round(y)}`;
    })
    .join(" ");
}

function round(n: number): number {
  return Math.round(n * 10) / 10;
}
