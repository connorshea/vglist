import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { useAuth } from "./useAuth";

vi.mock("vue-router", () => ({
  useRouter: () => ({ push: vi.fn<() => void>() })
}));

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

describe("useAuth().resendConfirmation", () => {
  const fetchMock = vi.fn<typeof fetch>();

  beforeEach(() => {
    setActivePinia(createPinia());
    fetchMock.mockReset();
    vi.stubGlobal("fetch", fetchMock);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("posts the email form-encoded and returns a success message", async () => {
    fetchMock.mockResolvedValue(jsonResponse(200, { message: "Confirmation instructions sent." }));

    const result = await useAuth().resendConfirmation("test@example.com");

    expect(result.success).toBeTruthy();
    expect(result.message).not.toBe("");
    const [url, init] = fetchMock.mock.calls[0] ?? [];
    expect(url).toBe(`${import.meta.env.VITE_API_URL}/users/confirmation`);
    expect(init?.method).toBe("POST");
    const body = init?.body;
    expect(body).toBeInstanceOf(URLSearchParams);
    expect(body instanceof URLSearchParams ? body.get("user[email]") : null).toBe("test@example.com");
  });

  it("shows the throttle message rather than GraphQL-shaped error objects", async () => {
    const message = "Too many requests. Please try again later.";
    fetchMock.mockResolvedValue(jsonResponse(429, { error: message, errors: [{ message }] }));

    const result = await useAuth().resendConfirmation("test@example.com");

    expect(result).toEqual({ success: false, message: "", errors: [message] });
  });

  it("returns Devise's string errors", async () => {
    fetchMock.mockResolvedValue(jsonResponse(422, { errors: ["Email can't be blank"] }));

    const result = await useAuth().resendConfirmation("");

    expect(result.errors).toEqual(["Email can't be blank"]);
  });

  it("falls back to a generic error when the request fails", async () => {
    fetchMock.mockRejectedValue(new TypeError("Failed to fetch"));

    const result = await useAuth().resendConfirmation("test@example.com");

    expect(result).toEqual({ success: false, message: "", errors: ["Couldn't send confirmation instructions."] });
  });
});
