/**
 * The `after` cursor that starts a GraphQL connection `offset` rows in.
 *
 * The API's connection cursors are offsets: graphql-ruby encodes the offset as
 * a string in unpadded URL-safe Base64 (`Base64.urlsafe_encode64("50",
 * padding: false)`). Building it here lets a page number in the URL jump
 * straight to that page, instead of walking every page before it. A request
 * spec (spec/requests/api/users_spec.rb) pins the format.
 */
export function offsetCursor(offset: number): string | null {
  if (!Number.isInteger(offset) || offset <= 0) return null;
  return btoa(String(offset)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/**
 * Reads a `?page=` query parameter as a page number from 1. Anything that
 * isn't a positive whole number (missing, repeated, `0`, `abc`, `2.5`) is
 * page 1.
 */
export function parsePageParam(value: unknown): number {
  if (typeof value !== "string" || !/^[1-9]\d*$/.test(value)) return 1;
  const page = Number(value);
  return Number.isSafeInteger(page) ? page : 1;
}
