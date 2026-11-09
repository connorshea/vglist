import { GraphQLClient } from "graphql-request";
import { useAuthStore } from "@/stores/auth";
import { clearQueryCache } from "@/graphql/query-cache";

// The names of mutations sent so far. The response middleware only gets the
// operation name, not the document, so the request middleware notes which
// names belong to mutations.
const mutationNames = new Set<string>();

function isMutationBody(body: unknown): boolean {
  if (typeof body !== "string") {
    return false;
  }
  try {
    const { query } = JSON.parse(body) as { query?: unknown };
    // Top-level definitions are unindented in a printed document.
    return typeof query === "string" && /^mutation\b/m.test(query);
  } catch {
    return false;
  }
}

export const gqlClient = new GraphQLClient(`${import.meta.env.VITE_API_URL}/graphql`, {
  headers: () => {
    const authStore = useAuthStore();
    const token = authStore.token;
    const headers: Record<string, string> = {};
    if (token) {
      headers["authorization"] = `Bearer ${token}`;
    }
    return headers;
  },
  requestMiddleware: (request) => {
    if (isMutationBody(request.body)) {
      mutationNames.add(request.operationName ?? "");
    }
    return request;
  },
  // Any mutation, whether it succeeded or not, may have changed what cached
  // queries would return, so start over once it's done.
  responseMiddleware: (_response, request) => {
    if (mutationNames.has(request.operationName ?? "")) {
      clearQueryCache();
    }
  }
});
