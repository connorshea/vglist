// Loads Cloudflare Turnstile's script on demand, so only pages that show a
// challenge (the sign-up form) pull it in. See
// https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/
//
// The script origin must be allowed in the Caddyfile CSP (script-src and
// frame-src).

export const TURNSTILE_SCRIPT_URL = "https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit";

export interface TurnstileRenderOptions {
  sitekey: string;
  action?: string;
  theme?: "auto" | "light" | "dark";
  size?: "normal" | "flexible" | "compact";
  callback?: (token: string) => void;
  "expired-callback"?: () => void;
  "error-callback"?: (errorCode: string) => void;
  "response-field"?: boolean;
}

export interface TurnstileApi {
  render: (container: HTMLElement, options: TurnstileRenderOptions) => string | undefined;
  reset: (widgetId?: string) => void;
  remove: (widgetId?: string) => void;
}

declare global {
  interface Window {
    turnstile?: TurnstileApi;
  }
}

let loading: Promise<TurnstileApi> | null = null;

export function loadTurnstile(): Promise<TurnstileApi> {
  if (window.turnstile) return Promise.resolve(window.turnstile);
  if (loading) return loading;

  loading = new Promise<TurnstileApi>((resolve, reject) => {
    const script = document.createElement("script");
    script.src = TURNSTILE_SCRIPT_URL;
    script.async = true;
    script.addEventListener("load", () => {
      if (window.turnstile) {
        resolve(window.turnstile);
      } else {
        reject(new Error("Turnstile script loaded without defining window.turnstile"));
      }
    });
    script.addEventListener("error", () => {
      // Let a later mount try again, e.g. after a content blocker is turned off.
      script.remove();
      loading = null;
      reject(new Error("Failed to load the Turnstile script"));
    });
    document.head.appendChild(script);
  });

  return loading;
}

// Test-only: forget a cached load between tests.
export function resetTurnstileLoaderForTests() {
  loading = null;
}
