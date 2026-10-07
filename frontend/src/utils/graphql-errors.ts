import { ClientError } from "graphql-request";

const GENERIC_MESSAGE = "Something went wrong. Please try again.";

/**
 * Extract a clean, safe-to-display error message from an error thrown by a
 * GraphQL request.
 *
 * graphql-request's `ClientError.message` embeds the full request, including
 * the variables, as JSON. For mutations like signIn or updatePassword that
 * means the user's plaintext password would be rendered on screen whenever
 * the server returns a non-2xx response. So `ClientError.message` is never
 * used here: we pull the human-readable messages from `response.errors[]`
 * and otherwise fall back to a generic message.
 */
export function extractGqlError(err: unknown): string {
  if (err instanceof ClientError || hasResponse(err)) {
    const response = err.response;
    const messages = response.errors?.map((e) => e.message).filter((m) => typeof m === "string" && m.length > 0);
    if (messages?.length) {
      return messages.join(", ");
    }
    if (typeof response.status === "number") {
      return `Request failed (HTTP ${response.status}). Please try again.`;
    }
    return GENERIC_MESSAGE;
  }
  if (err instanceof Error) return err.message || GENERIC_MESSAGE;
  if (typeof err === "string" && err.length > 0) return err;
  return GENERIC_MESSAGE;
}

interface ErrorWithResponse {
  response: { status?: unknown; errors?: { message?: unknown }[] };
}

function hasResponse(err: unknown): err is ErrorWithResponse {
  return (
    typeof err === "object" &&
    err !== null &&
    "response" in err &&
    typeof (err as { response: unknown }).response === "object" &&
    (err as { response: unknown }).response !== null
  );
}
