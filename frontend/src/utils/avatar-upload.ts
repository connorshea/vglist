// Upload a cropped avatar for the signed-in user. This goes to a REST endpoint
// rather than GraphQL because graphql-request can't send multipart bodies.
// Resolves to the new avatar's URL, or throws an Error with a message that's
// safe to show to the user.
export async function uploadAvatar(blob: Blob, token: string | null): Promise<string | null> {
  const body = new FormData();
  body.append("avatar", blob, blob.type === "image/png" ? "avatar.png" : "avatar.jpg");

  const headers: Record<string, string> = { Accept: "application/json" };
  if (token) headers.Authorization = `Bearer ${token}`;

  const response = await fetch(`${import.meta.env.VITE_API_URL}/api/users/me/avatar`, {
    method: "POST",
    headers,
    body
  });

  const data = (await response.json().catch(() => ({}))) as {
    avatar_url?: unknown;
    error?: unknown;
    errors?: unknown;
  };

  if (!response.ok) {
    // Validation errors come back as `errors` strings. Auth failures and
    // Rack::Attack's 429 send `error` (the 429 also sends GraphQL-shaped
    // `errors` objects, which aren't strings), so prefer `error`.
    if (typeof data.error === "string") throw new Error(data.error);
    const messages = Array.isArray(data.errors)
      ? data.errors.filter((error): error is string => typeof error === "string")
      : [];
    throw new Error(messages.length > 0 ? messages.join(" ") : `Upload failed (HTTP ${response.status}).`);
  }

  return typeof data.avatar_url === "string" ? data.avatar_url : null;
}
