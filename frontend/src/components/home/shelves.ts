import type { GameSortOption } from "@/components/games-index/format";

/**
 * The home page shelf for games that haven't come out yet. The games index
 * has no matching sort, so its `value` is null and, unlike the other shelves,
 * it has no "See all" link.
 */
export const UPCOMING_RELEASES = { slug: "upcoming", label: "Upcoming releases", value: null } as const;

/** What a home page shelf shows: one of the games index's sorts, or upcoming releases. */
export type HomeShelf = GameSortOption | typeof UPCOMING_RELEASES;
