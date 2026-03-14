/**
 * Extract a clean error message from a graphql-request ClientError.
 *
 * The graphql-request library includes the full response JSON in
 * `err.message`, which is not suitable for display. This helper
 * pulls the human-readable messages from `err.response.errors[]`.
 */
export function extractGqlError(err: unknown): string {
  if (err && typeof err === "object" && "response" in err) {
    const response = (err as { response: { errors?: { message: string }[] } }).response;
    if (response.errors?.length) {
      return response.errors.map((e) => e.message).join(", ");
    }
  }
  if (err instanceof Error) return err.message;
  return String(err);
}
