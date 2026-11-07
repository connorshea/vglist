import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { uploadAvatar } from "./avatar-upload";

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

describe("uploadAvatar", () => {
  const fetchMock = vi.fn<typeof fetch>();

  beforeEach(() => {
    fetchMock.mockReset();
    vi.stubGlobal("fetch", fetchMock);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("posts the image as multipart form data with the bearer token", async () => {
    fetchMock.mockResolvedValue(jsonResponse(201, { avatar_url: "https://files.vglist.co/abc" }));
    const blob = new Blob(["png"], { type: "image/png" });

    const url = await uploadAvatar(blob, "jwt-token");

    expect(url).toBe("https://files.vglist.co/abc");
    const [requestUrl, init] = fetchMock.mock.calls[0] ?? [];
    expect(requestUrl).toBe(`${import.meta.env.VITE_API_URL}/api/users/me/avatar`);
    expect(init?.method).toBe("POST");
    expect(init?.headers).toMatchObject({ Authorization: "Bearer jwt-token" });
    const body = init?.body;
    expect(body).toBeInstanceOf(FormData);
    const file = body instanceof FormData ? body.get("avatar") : null;
    expect(file).toBeInstanceOf(File);
    expect(file instanceof File ? file.name : null).toBe("avatar.png");
  });

  it("names JPEG uploads avatar.jpg", async () => {
    fetchMock.mockResolvedValue(jsonResponse(201, { avatar_url: "https://files.vglist.co/abc" }));

    await uploadAvatar(new Blob(["jpg"], { type: "image/jpeg" }), "jwt-token");

    const body = fetchMock.mock.calls[0]?.[1]?.body;
    const file = body instanceof FormData ? body.get("avatar") : null;
    expect(file instanceof File ? file.name : null).toBe("avatar.jpg");
  });

  it("throws the server's validation errors", async () => {
    fetchMock.mockResolvedValue(jsonResponse(422, { errors: ["Avatar must be a square image"] }));

    await expect(uploadAvatar(new Blob(["x"], { type: "image/png" }), "jwt-token")).rejects.toThrow(
      "Avatar must be a square image"
    );
  });

  it("prefers the throttle message over GraphQL-shaped errors", async () => {
    const message = "Too many requests. Please try again later.";
    fetchMock.mockResolvedValue(jsonResponse(429, { error: message, errors: [{ message }] }));

    await expect(uploadAvatar(new Blob(["x"], { type: "image/png" }), "jwt-token")).rejects.toThrow(message);
  });

  it("falls back to the HTTP status when the body isn't JSON", async () => {
    fetchMock.mockResolvedValue(new Response("Bad gateway", { status: 502 }));

    await expect(uploadAvatar(new Blob(["x"], { type: "image/png" }), "jwt-token")).rejects.toThrow(
      "Upload failed (HTTP 502)."
    );
  });
});
