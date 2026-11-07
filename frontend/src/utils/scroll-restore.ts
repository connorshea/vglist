/**
 * Waits until the page is tall enough to scroll to `top`, or until
 * `timeoutMs` passes. Used when restoring a saved scroll position on
 * Back/Forward: the route's data (and so most of its height) arrives after
 * the navigation, and scrolling straight away while a short loading state is
 * on screen clamps the position near the top.
 */
export function waitForScrollableTo(
  top: number,
  { timeoutMs = 2000, intervalMs = 50 }: { timeoutMs?: number; intervalMs?: number } = {}
): Promise<void> {
  return new Promise((resolve) => {
    const deadline = Date.now() + timeoutMs;
    const check = () => {
      const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
      if (maxScroll >= top || Date.now() >= deadline) {
        resolve();
      } else {
        setTimeout(check, intervalMs);
      }
    };
    check();
  });
}
