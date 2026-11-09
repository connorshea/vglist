import { afterEach, describe, expect, it, vi } from "vitest";
import { persistedDocumentIds } from "@/types/persisted-documents";
import { persistedGetUrl, persistedQueryFetch, tracedApiUrls } from "./client";

const apiUrl: string = import.meta.env.VITE_API_URL ?? "";
const endpoint = `${apiUrl}/graphql`;
const heroCoversId = persistedDocumentIds.GetHeroCovers;

function postInit(body: Record<string, unknown>, headers: Record<string, string> = {}): RequestInit {
  return {
    method: "POST",
    headers: { "content-type": "application/json", ...headers },
    body: JSON.stringify(body)
  };
}

function getParams(url: string | null): URLSearchParams {
  expect(url).not.toBeNull();
  const parsed = new URL(url!, "http://localhost");
  expect(`${parsed.origin}${parsed.pathname}`.endsWith("/graphql")).toBeTruthy();
  return parsed.searchParams;
}

describe("persistedGetUrl", () => {
  it("sends a signed-out persisted query as GET, without the document", () => {
    const params = getParams(
      persistedGetUrl(postInit({ query: "query GetHeroCovers { x }", operationName: "GetHeroCovers" }))
    );
    expect(params.get("operationName")).toBe("GetHeroCovers");
    expect(params.get("documentId")).toBe(heroCoversId);
    expect(params.has("query")).toBeFalsy();
    expect(params.has("variables")).toBeFalsy();
  });

  it("sorts variable keys so the same variables always make the same URL", () => {
    const a = persistedGetUrl(
      postInit({ operationName: "GetGamesIndex", variables: { sortBy: "NEWEST", first: 6, nested: { b: 1, a: 2 } } })
    );
    const b = persistedGetUrl(
      postInit({ operationName: "GetGamesIndex", variables: { first: 6, nested: { a: 2, b: 1 }, sortBy: "NEWEST" } })
    );
    expect(a).toBe(b);
    expect(getParams(a).get("variables")).toBe('{"first":6,"nested":{"a":2,"b":1},"sortBy":"NEWEST"}');
  });

  it("keeps signed-in requests as POST", () => {
    expect(persistedGetUrl(postInit({ operationName: "GetHeroCovers" }, { authorization: "Bearer x.y.z" }))).toBeNull();
  });

  it("keeps operations without a persisted document ID as POST", () => {
    expect(persistedGetUrl(postInit({ operationName: "GetGame", variables: { id: "1" } }))).toBeNull();
    expect(persistedGetUrl(postInit({ operationName: "toString" }))).toBeNull();
  });

  it("ignores anything that isn't a JSON POST", () => {
    expect(persistedGetUrl({ method: "GET" })).toBeNull();
    expect(persistedGetUrl({ method: "POST", body: "not json" })).toBeNull();
    expect(persistedGetUrl(undefined)).toBeNull();
  });
});

describe("persistedQueryFetch", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("GETs persisted queries with no headers that need a preflight", async () => {
    const fetchMock = vi.fn<typeof fetch>().mockResolvedValue(new Response("{}", { status: 200 }));
    vi.stubGlobal("fetch", fetchMock);

    await persistedQueryFetch(endpoint, postInit({ operationName: "GetHeroCovers" }));

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0];
    expect(getParams(url as string).get("documentId")).toBe(heroCoversId);
    expect(init?.method).toBe("GET");
    expect(init?.body).toBeUndefined();
    expect(init?.headers).toEqual({ accept: "application/json" });
  });

  it("falls back to the original POST when the API doesn't know the document", async () => {
    const fetchMock = vi
      .fn<typeof fetch>()
      .mockResolvedValueOnce(new Response("{}", { status: 404 }))
      .mockResolvedValueOnce(new Response("{}", { status: 200 }));
    vi.stubGlobal("fetch", fetchMock);
    const init = postInit({ operationName: "GetHeroCovers" });

    const response = await persistedQueryFetch(endpoint, init);

    expect(response.status).toBe(200);
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(fetchMock.mock.calls[1]).toEqual([endpoint, init]);
  });

  it("doesn't retry other errors as POST", async () => {
    const fetchMock = vi.fn<typeof fetch>().mockResolvedValue(new Response("{}", { status: 500 }));
    vi.stubGlobal("fetch", fetchMock);

    const response = await persistedQueryFetch(endpoint, postInit({ operationName: "GetHeroCovers" }));

    expect(response.status).toBe(500);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it("POSTs everything else unchanged", async () => {
    const fetchMock = vi.fn<typeof fetch>().mockResolvedValue(new Response("{}", { status: 200 }));
    vi.stubGlobal("fetch", fetchMock);
    const init = postInit({ operationName: "GetGame" });

    await persistedQueryFetch(endpoint, init);

    expect(fetchMock.mock.calls).toEqual([[endpoint, init]]);
  });
});

describe("tracedApiUrls", () => {
  it("matches API requests except persisted GET queries", () => {
    expect(tracedApiUrls.test(endpoint)).toBeTruthy();
    expect(tracedApiUrls.test(`${apiUrl}/api/users/me/avatar`)).toBeTruthy();
    expect(tracedApiUrls.test(`${endpoint}?operationName=GetHeroCovers&documentId=${heroCoversId}`)).toBeFalsy();
  });
});
