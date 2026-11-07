import { describe, it, expect } from "vitest";
import { WebAuthnError } from "@simplewebauthn/browser";
import { guessPasskeyNickname, isPasskeyCancellation, passkeyRegistrationErrorMessage } from "./passkeys";

function domError(name: string): Error {
  const error = new Error("browser error");
  error.name = name;
  return error;
}

describe("isPasskeyCancellation", () => {
  it("treats a cancelled or timed-out prompt as a cancellation", () => {
    expect(isPasskeyCancellation(domError("NotAllowedError"))).toBeTruthy();
  });

  it("treats an aborted ceremony as a cancellation", () => {
    expect(isPasskeyCancellation(domError("AbortError"))).toBeTruthy();
    expect(
      isPasskeyCancellation(
        new WebAuthnError({ message: "aborted", code: "ERROR_CEREMONY_ABORTED", cause: domError("AbortError") })
      )
    ).toBeTruthy();
  });

  it("does not treat other errors as cancellations", () => {
    expect(isPasskeyCancellation(domError("SecurityError"))).toBeFalsy();
    expect(isPasskeyCancellation("nope")).toBeFalsy();
  });
});

describe("passkeyRegistrationErrorMessage", () => {
  it("explains a passkey that's already registered", () => {
    const error = new WebAuthnError({
      message: "already registered",
      code: "ERROR_AUTHENTICATOR_PREVIOUSLY_REGISTERED",
      cause: domError("InvalidStateError")
    });
    expect(passkeyRegistrationErrorMessage(error)).toBe("This passkey is already registered to your account.");
  });

  it("falls back to a generic message", () => {
    expect(passkeyRegistrationErrorMessage(domError("UnknownError"))).toMatch(/couldn't create a passkey/);
  });
});

describe("guessPasskeyNickname", () => {
  it.each([
    ["Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)", "iPhone"],
    ["Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", "Mac"],
    ["Mozilla/5.0 (Windows NT 10.0; Win64; x64)", "Windows PC"],
    ["Mozilla/5.0 (Linux; Android 15; Pixel 9)", "Android phone"],
    ["Mozilla/5.0 (X11; Linux x86_64)", "Linux PC"],
    ["Something else", "My passkey"]
  ])("names %s %s", (userAgent, nickname) => {
    expect(guessPasskeyNickname(userAgent)).toBe(nickname);
  });
});
