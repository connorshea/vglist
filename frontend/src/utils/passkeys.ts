import { WebAuthnError } from "@simplewebauthn/browser";

/**
 * Whether an error from `startAuthentication` / `startRegistration` means the
 * ceremony simply didn't finish: the user cancelled the browser prompt, it
 * timed out, or we aborted it ourselves (e.g. to replace the autofill request
 * with a button-triggered one). These are shown silently.
 *
 * Browsers deliberately report "no passkey for this site" as NotAllowedError
 * too, so it can't be told apart from cancelling.
 */
export function isPasskeyCancellation(error: unknown): boolean {
  if (error instanceof WebAuthnError && error.code === "ERROR_CEREMONY_ABORTED") {
    return true;
  }
  return error instanceof Error && (error.name === "NotAllowedError" || error.name === "AbortError");
}

/** A user-facing message for an error from `startRegistration`. */
export function passkeyRegistrationErrorMessage(error: unknown): string {
  if (error instanceof WebAuthnError && error.code === "ERROR_AUTHENTICATOR_PREVIOUSLY_REGISTERED") {
    return "This passkey is already registered to your account.";
  }
  if (error instanceof Error && error.name === "InvalidStateError") {
    return "This passkey is already registered to your account.";
  }
  return "Your browser couldn't create a passkey. Please try again.";
}

/**
 * A starting name for a new passkey, based on the device it was made on.
 * The user can change it right after adding the passkey.
 */
export function guessPasskeyNickname(userAgent: string = navigator.userAgent): string {
  if (/iPhone/.test(userAgent)) {
    return "iPhone";
  }
  if (/iPad/.test(userAgent)) {
    return "iPad";
  }
  if (/Android/.test(userAgent)) {
    return "Android phone";
  }
  if (/Macintosh|Mac OS X/.test(userAgent)) {
    return "Mac";
  }
  if (/Windows/.test(userAgent)) {
    return "Windows PC";
  }
  if (/CrOS/.test(userAgent)) {
    return "Chromebook";
  }
  if (/Linux/.test(userAgent)) {
    return "Linux PC";
  }
  return "My passkey";
}
