// Matches a Wikidata item URL, e.g. https://www.wikidata.org/wiki/Q123,
// https://m.wikidata.org/wiki/Q123, https://www.wikidata.org/entity/Q123 or
// https://www.wikidata.org/wiki/Special:EntityPage/Q123. A query string or
// fragment after the ID is ignored.
const WIKIDATA_URL_PATTERN =
  /^(?:https?:\/\/)?(?:[\w-]+\.)*wikidata\.org\/(?:wiki\/(?:Special:EntityPage\/)?|entity\/)[Qq](\d+)\/?(?:[?#].*)?$/;

const WIKIDATA_ID_PATTERN = /^[Qq]?(\d+)$/;

/**
 * Normalizes user input for a Wikidata item ID to its numeric portion, so
 * "123", "Q123", "q123" and "https://www.wikidata.org/wiki/Q123" all become
 * "123". Input that isn't recognized is returned trimmed but otherwise
 * unchanged, so that validation can report it.
 */
export function normalizeWikidataId(input: string): string {
  const trimmed = input.trim();
  const match = WIKIDATA_ID_PATTERN.exec(trimmed) ?? WIKIDATA_URL_PATTERN.exec(trimmed);
  return match ? match[1] : trimmed;
}

/** Whether a normalized Wikidata ID is a positive whole number. */
export function isValidWikidataId(value: string): boolean {
  return /^\d+$/.test(value) && Number(value) > 0;
}
