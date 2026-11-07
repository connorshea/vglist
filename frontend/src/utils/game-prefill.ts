import type { LocationQuery } from "vue-router";

export interface GamePrefill {
  name: string;
  steamAppId: number | null;
}

function firstString(value: LocationQuery[string] | undefined): string {
  const first = Array.isArray(value) ? value[0] : value;
  return typeof first === "string" ? first : "";
}

/**
 * Reads the values a link can prefill on the new game form, e.g.
 * `/games/new?name=Half-Life%202&steamAppId=220`.
 * Anything malformed is ignored rather than put in the form.
 */
export function gamePrefillFromQuery(query: LocationQuery): GamePrefill {
  const name = firstString(query.name).trim().slice(0, 120);
  const rawSteamAppId = firstString(query.steamAppId).trim();
  const steamAppId = /^\d+$/.test(rawSteamAppId) ? Number(rawSteamAppId) : null;

  return { name, steamAppId: steamAppId !== null && steamAppId > 0 ? steamAppId : null };
}
