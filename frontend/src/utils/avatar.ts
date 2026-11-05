// A fallback avatar for users with no uploaded image: their first two letters
// on a colour picked from a hash of the username, so it stays stable.
export function userInitials(username: string): string {
  return username.slice(0, 2).toUpperCase();
}

const AVATAR_COLORS = ["#6c5ce7", "#00b894", "#e17055", "#0984e3", "#e84393", "#00a862", "#d63031", "#fdcb6e"];

export function avatarColor(username: string): string {
  let hash = 0;
  for (const ch of username) {
    hash = ((hash << 5) - hash + ch.charCodeAt(0)) | 0;
  }
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}
