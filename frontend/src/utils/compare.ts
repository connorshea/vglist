import type { GamePurchaseSort, LibraryComparisonSort } from "@/types/graphql";

// The comparison page's tabs, as they appear in the `?tab=` query parameter.
export type CompareTab = "overview" | "common" | "only-a" | "only-b";

const TABS: readonly CompareTab[] = ["overview", "common", "only-a", "only-b"];

export function isCompareTab(value: unknown): value is CompareTab {
  return typeof value === "string" && (TABS as readonly string[]).includes(value);
}

export const IN_COMMON_SORTS: readonly { key: LibraryComparisonSort; label: (a: string, b: string) => string }[] = [
  { key: "RATING_GAP", label: () => "Biggest disagreement" },
  { key: "USER_A_RATING", label: (a) => `${a}'s rating` },
  { key: "USER_B_RATING", label: (_a, b) => `${b}'s rating` },
  { key: "GAME_NAME", label: () => "Name (A–Z)" }
];

export function isInCommonSort(value: unknown): value is LibraryComparisonSort {
  return IN_COMMON_SORTS.some((sort) => sort.key === value);
}

export const ONLY_SORTS: readonly { key: GamePurchaseSort; label: string }[] = [
  { key: "HIGHEST_RATING", label: "Highest rating" },
  { key: "GAME_NAME", label: "Name (A–Z)" }
];

export function isOnlySort(value: unknown): value is GamePurchaseSort {
  return ONLY_SORTS.some((sort) => sort.key === value);
}

export interface OverlapShares {
  onlyA: number;
  both: number;
  onlyB: number;
}

// Each part of the overlap bar as a percentage of both libraries combined.
// A part that has any games gets at least a sliver, so it doesn't vanish next
// to a library ten times its size.
export function overlapShares(onlyA: number, both: number, onlyB: number): OverlapShares {
  const total = onlyA + both + onlyB;
  if (total === 0) return { onlyA: 0, both: 0, onlyB: 0 };

  const MIN = 2;
  const raw = [onlyA, both, onlyB].map((count) => (count === 0 ? 0 : Math.max((count / total) * 100, MIN)));
  const sum = raw.reduce((acc, share) => acc + share, 0);
  const [a, b, c] = raw.map((share) => Math.round((share / sum) * 1000) / 10);
  return { onlyA: a, both: b, onlyB: c };
}

// The bar in the rating gap column. It grows out from the middle towards
// whoever rated the game higher, reaching the end at a gap of 25 or more.
export function gapMeter(difference: number | null): { side: "a" | "b"; width: number } | null {
  if (difference === null || difference === 0) return null;
  return { side: difference > 0 ? "a" : "b", width: Math.min(Math.abs(difference), 25) * 2 };
}

// The rating gap column for screen readers, since the meter's direction is
// only shown by its position and colour.
export function gapDescription(difference: number | null, userA: string, userB: string): string {
  if (difference === null) return "Not rated by both";
  if (difference === 0) return "Same rating";
  return `${difference > 0 ? userA : userB} rated it ${Math.abs(difference)} higher`;
}

// The share of A's library that B also owns, e.g. "41%".
export function sharePercent(part: number, whole: number): string {
  if (whole === 0) return "0%";
  return `${Math.round((part / whole) * 100)}%`;
}
