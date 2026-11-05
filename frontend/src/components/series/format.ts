import { countLabel } from "@/components/games-index/format";

/** "38 games · 1996–2025", "1 game · 2002", or "No games yet". */
export function seriesMeta(
  gamesCount: number,
  firstReleaseYear: number | null | undefined,
  lastReleaseYear: number | null | undefined
): string {
  if (gamesCount === 0) return "No games yet";
  const parts = [countLabel(gamesCount, "game")];
  if (firstReleaseYear && lastReleaseYear) {
    parts.push(firstReleaseYear === lastReleaseYear ? `${firstReleaseYear}` : `${firstReleaseYear}–${lastReleaseYear}`);
  }
  return parts.join(" · ");
}
