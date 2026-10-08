import { describe, expect, it } from "vitest";
import { ClientError } from "graphql-request";
import { extractGqlError } from "./graphql-errors";

const request = {
  query:
    "mutation SignIn($email: String!, $password: String!) { signIn(email: $email, password: $password) { token } }",
  variables: { email: "user@example.com", password: "hunter2-super-secret" }
};

// graphql-request builds ClientError from whatever the server returned, which
// for a 5xx is just a status, headers, and maybe a non-JSON body. Its types
// are stricter than its runtime behaviour, so cast the shapes we exercise.
type ClientErrorResponse = ConstructorParameters<typeof ClientError>[0];
function makeClientError(response: Record<string, unknown>): ClientError {
  return new ClientError(response as unknown as ClientErrorResponse, request);
}

describe("extractGqlError", () => {
  it("returns the GraphQL error messages when present", () => {
    const err = makeClientError({
      status: 200,
      headers: new Headers(),
      errors: [{ message: "Not allowed." }, { message: "Also bad." }]
    });

    expect(extractGqlError(err)).toBe("Not allowed., Also bad.");
  });

  it("never leaks request variables on a server error", () => {
    const err = makeClientError({ status: 500, headers: new Headers() });

    const message = extractGqlError(err);
    expect(message).toBe("Request failed (HTTP 500). Please try again.");
    expect(message).not.toContain("hunter2");
    expect(message).not.toContain("user@example.com");
  });

  it("never leaks request variables on a proxy error with a non-JSON body", () => {
    const err = makeClientError({ status: 502, headers: new Headers(), error: "<html>Bad Gateway</html>" });

    const message = extractGqlError(err);
    expect(message).not.toContain("hunter2");
    expect(message).toContain("502");
  });

  it("falls back to a generic message when a response has no errors or status", () => {
    const err = { response: {} };

    expect(extractGqlError(err)).toBe("Something went wrong. Please try again.");
  });

  it("returns the message of an ordinary Error", () => {
    expect(extractGqlError(new TypeError("Failed to fetch"))).toBe("Failed to fetch");
  });

  it("passes through string errors and falls back for anything else", () => {
    expect(extractGqlError("boom")).toBe("boom");
    expect(extractGqlError(undefined)).toBe("Something went wrong. Please try again.");
    expect(extractGqlError({ weird: true })).toBe("Something went wrong. Please try again.");
  });
});
