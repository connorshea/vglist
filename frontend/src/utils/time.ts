// "just now", "5m ago", "3 days ago", … falling back to a locale date for
// anything a year or more old.
export function timeAgo(dateStr: string, now: Date = new Date()): string {
  const date = new Date(dateStr);
  const diffMs = now.getTime() - date.getTime();
  const diffSec = Math.floor(diffMs / 1000);
  const diffMin = Math.floor(diffSec / 60);
  const diffHr = Math.floor(diffMin / 60);
  const diffDay = Math.floor(diffHr / 24);
  const diffWeek = Math.floor(diffDay / 7);
  const diffMonth = Math.floor(diffDay / 30);

  if (diffMin < 1) {
    return "just now";
  }
  if (diffMin < 60) {
    return `${diffMin}m ago`;
  }
  if (diffHr < 24) {
    return `${diffHr}h ago`;
  }
  if (diffDay === 1) {
    return "1 day ago";
  }
  if (diffDay < 7) {
    return `${diffDay} days ago`;
  }
  if (diffWeek === 1) {
    return "1 week ago";
  }
  if (diffWeek < 5) {
    return `${diffWeek} weeks ago`;
  }
  if (diffMonth === 1) {
    return "1 month ago";
  }
  if (diffMonth < 12) {
    return `${diffMonth} months ago`;
  }
  return date.toLocaleDateString();
}
