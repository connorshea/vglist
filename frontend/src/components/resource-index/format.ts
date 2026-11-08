import { countLabel } from "@/components/games-index/format";

/** "1,284 games", or "No games yet". */
export function gamesMeta(gamesCount: number): string {
  return gamesCount === 0 ? "No games yet" : countLabel(gamesCount, "game");
}

/** "38 games · 1996–2025", "1 game · 2002", or "No games yet". */
export function seriesMeta(
  gamesCount: number,
  firstReleaseYear: number | null | undefined,
  lastReleaseYear: number | null | undefined
): string {
  if (gamesCount === 0 || !firstReleaseYear || !lastReleaseYear) {
    return gamesMeta(gamesCount);
  }
  const years = firstReleaseYear === lastReleaseYear ? `${firstReleaseYear}` : `${firstReleaseYear}–${lastReleaseYear}`;
  return `${gamesMeta(gamesCount)} · ${years}`;
}
