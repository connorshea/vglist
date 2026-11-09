import { GraphQLClient } from "graphql-request";
import { useAuthStore } from "@/stores/auth";
import { persistedDocumentIds } from "@/types/persisted-documents";

// Unset in unit tests.
const apiUrl: string = import.meta.env.VITE_API_URL ?? "";
const endpoint = `${apiUrl}/graphql`;

/**
 * API URLs Sentry should send trace headers to: all of them except persisted
 * GET queries, where the headers would force a CORS preflight on requests
 * Cloudflare otherwise answers from its cache.
 */
export const tracedApiUrls = new RegExp(`^${apiUrl.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}(?!/graphql\\?)`);

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

// JSON.stringify with object keys sorted, so the same variables always make
// the same URL, and so the same CDN cache entry.
function stableStringify(value: unknown): string {
  return JSON.stringify(value, (_key, nested: unknown) =>
    isRecord(nested)
      ? Object.fromEntries(Object.entries(nested).sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0)))
      : nested
  );
}

/**
 * The GET URL for a POST graphql-request is about to send, or null if it has
 * to stay a POST.
 *
 * Signed-out requests for the operations in `persistedDocumentIds` are sent
 * as `GET /graphql?operationName=...&documentId=sha256:...&variables=...`,
 * which Cloudflare can cache. The API only lets it cache responses that are
 * the same for every signed-out visitor (see `PublicResponseCache`), so
 * signed-in requests, which carry an Authorization header, always stay POST.
 */
export function persistedGetUrl(init: RequestInit | undefined): string | null {
  if (init?.method !== "POST" || typeof init.body !== "string") {
    return null;
  }
  if (new Headers(init.headers).has("authorization")) {
    return null;
  }

  let body: unknown;
  try {
    body = JSON.parse(init.body);
  } catch {
    return null;
  }
  if (!isRecord(body) || typeof body.operationName !== "string") {
    return null;
  }

  const documentId = Object.hasOwn(persistedDocumentIds, body.operationName)
    ? persistedDocumentIds[body.operationName]
    : undefined;
  if (!documentId) {
    return null;
  }

  const params = new URLSearchParams({ operationName: body.operationName, documentId });
  if (isRecord(body.variables) && Object.keys(body.variables).length > 0) {
    params.set("variables", stableStringify(body.variables));
  }
  return `${endpoint}?${params.toString()}`;
}

/**
 * graphql-request always POSTs. This sends the requests `persistedGetUrl`
 * picks as GETs instead, with only an Accept header, so the browser doesn't
 * need a CORS preflight either.
 *
 * A 404 means the API doesn't know the document ID, e.g. while a deploy has
 * shipped the SPA but not yet the API, so the request is retried as the
 * original POST.
 */
export const persistedQueryFetch: typeof fetch = async (input, init) => {
  const url = persistedGetUrl(init);
  if (url) {
    const response = await fetch(url, {
      method: "GET",
      // A CORS-safelisted header, so still no preflight. Asking for JSON also
      // makes an API without the GET route (mid-deploy) answer 404 rather
      // than the redirect to the SPA that browser visits get.
      headers: { accept: "application/json" },
      signal: init?.signal ?? null
    });
    if (response.status !== 404) {
      return response;
    }
  }
  return fetch(input, init);
};

export const gqlClient = new GraphQLClient(endpoint, {
  fetch: persistedQueryFetch,
  headers: () => {
    const authStore = useAuthStore();
    const token = authStore.token;
    const headers: Record<string, string> = {};
    if (token) {
      headers["authorization"] = `Bearer ${token}`;
    }
    return headers;
  }
});
