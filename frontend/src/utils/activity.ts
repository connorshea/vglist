import type { GamePurchaseCompletionStatus, GetActivityQuery, UserRole } from "@/types/graphql";

/**
 * An event in an activity feed. The global feed (`GetActivity`) and a user's
 * feed (`GetUserActivity`) select the same fields, so this fits both.
 */
export type ActivityEvent = NonNullable<GetActivityQuery["activity"]>["nodes"][number];

export interface ActivityEventGame {
  id: string;
  name: string;
  coverUrl: string | null;
}

export interface ActivityBadge {
  label: string;
  cssClass: string;
}

const COMPLETION_STATUS_LABELS: Record<GamePurchaseCompletionStatus, string> = {
  UNPLAYED: "Unplayed",
  IN_PROGRESS: "In Progress",
  DROPPED: "Dropped",
  COMPLETED: "Completed",
  FULLY_COMPLETED: "100%",
  NOT_APPLICABLE: "N/A",
  PAUSED: "Paused"
};

const COMPLETION_STATUS_VERBS: Record<GamePurchaseCompletionStatus, string> = {
  UNPLAYED: "set",
  IN_PROGRESS: "is playing",
  DROPPED: "dropped",
  COMPLETED: "completed",
  FULLY_COMPLETED: "100%'d",
  NOT_APPLICABLE: "set",
  PAUSED: "paused"
};

/** The game an event is about, for the events that are about one. */
export function eventGame(event: ActivityEvent): ActivityEventGame | null {
  if (
    (event.eventCategory === "ADD_TO_LIBRARY" ||
      event.eventCategory === "CHANGE_COMPLETION_STATUS" ||
      event.eventCategory === "FAVORITE_GAME") &&
    "game" in event.eventable
  ) {
    return event.eventable.game;
  }
  return null;
}

/** The rating on the library entry an event is about, if it has one. */
export function eventRating(event: ActivityEvent): number | null {
  if (
    (event.eventCategory === "ADD_TO_LIBRARY" || event.eventCategory === "CHANGE_COMPLETION_STATUS") &&
    "rating" in event.eventable &&
    event.eventable.rating != null
  ) {
    return event.eventable.rating;
  }
  return null;
}

/**
 * The status a completion status event changed the game to. Uses the status
 * recorded on the event, so older events don't show the game's current status.
 * Falls back to the current status for events with no recorded change.
 */
export function eventCompletionStatus(event: ActivityEvent): GamePurchaseCompletionStatus | null {
  if (event.completionStatusChange) {
    return event.completionStatusChange.after;
  }
  if ("completionStatus" in event.eventable && event.eventable.completionStatus) {
    return event.eventable.completionStatus;
  }
  return null;
}

/** The verb for a completion status event, e.g. "completed" in "Connor completed Portal 2". */
export function completionStatusVerb(event: ActivityEvent): string {
  const status = eventCompletionStatus(event);
  return status ? COMPLETION_STATUS_VERBS[status] : "changed the status of";
}

/** The badge shown beside an event, if its kind has one. */
export function eventBadge(event: ActivityEvent): ActivityBadge | null {
  if (event.eventCategory === "ADD_TO_LIBRARY") {
    return { label: "Added", cssClass: "badge-added" };
  }
  if (event.eventCategory === "FAVORITE_GAME") {
    return { label: "Favorited", cssClass: "badge-favorited" };
  }
  const status = event.eventCategory === "CHANGE_COMPLETION_STATUS" ? eventCompletionStatus(event) : null;
  if (status) {
    return {
      label: COMPLETION_STATUS_LABELS[status],
      cssClass: `badge-${status.toLowerCase().replaceAll("_", "-")}`
    };
  }
  if (event.eventCategory === "NEW_USER") {
    return { label: "New User", cssClass: "badge-new-user" };
  }
  if (event.eventCategory === "FOLLOWING") {
    return { label: "Followed", cssClass: "badge-followed" };
  }
  return null;
}

/** Moderators and admins can delete any event; everyone else only their own. */
export function canDeleteEvent(event: ActivityEvent, viewer: { id: string; role: UserRole } | null): boolean {
  if (!viewer) {
    return false;
  }
  if (viewer.role === "MODERATOR" || viewer.role === "ADMIN") {
    return true;
  }
  return event.user.id === viewer.id;
}
