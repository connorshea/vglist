import { describe, it, expect } from "vitest";
import type { EventCategory, GamePurchaseCompletionStatus } from "@/types/graphql";
import {
  canDeleteEvent,
  completionStatusVerb,
  eventBadge,
  eventCompletionStatus,
  eventGame,
  eventRating,
  type ActivityEvent
} from "./activity";

const game = { id: "10", name: "Portal 2", coverUrl: null };
const author = { id: "1", username: "connor", slug: "connor", avatarUrl: null };

function event(
  eventCategory: EventCategory,
  eventable: ActivityEvent["eventable"],
  completionStatusChange: ActivityEvent["completionStatusChange"] = null
): ActivityEvent {
  return {
    id: "e1",
    eventCategory,
    createdAt: "2026-11-01T00:00:00Z",
    completionStatusChange,
    user: author,
    eventable
  };
}

function libraryEntry(completionStatus: GamePurchaseCompletionStatus | null, rating: number | null = null) {
  return { completionStatus, rating, game };
}

function statusChange(after: GamePurchaseCompletionStatus | null, before: GamePurchaseCompletionStatus | null = null) {
  return { before, after };
}

describe("eventGame", () => {
  it.each<EventCategory>(["ADD_TO_LIBRARY", "CHANGE_COMPLETION_STATUS"])("is the library entry's game for %s", (c) => {
    expect(eventGame(event(c, libraryEntry("COMPLETED")))).toEqual(game);
  });

  it("is the favorited game for FAVORITE_GAME", () => {
    expect(eventGame(event("FAVORITE_GAME", { game }))).toEqual(game);
  });

  it("is null for events that aren't about a game", () => {
    expect(eventGame(event("NEW_USER", author))).toBeNull();
    expect(eventGame(event("FOLLOWING", { followed: author }))).toBeNull();
  });
});

describe("eventRating", () => {
  it("is the library entry's rating", () => {
    expect(eventRating(event("ADD_TO_LIBRARY", libraryEntry(null, 85)))).toBe(85);
    expect(eventRating(event("CHANGE_COMPLETION_STATUS", libraryEntry("COMPLETED", 70)))).toBe(70);
  });

  it("keeps a rating of zero", () => {
    expect(eventRating(event("ADD_TO_LIBRARY", libraryEntry(null, 0)))).toBe(0);
  });

  it("is null without a rating", () => {
    expect(eventRating(event("ADD_TO_LIBRARY", libraryEntry(null, null)))).toBeNull();
    expect(eventRating(event("FAVORITE_GAME", { game }))).toBeNull();
  });
});

describe("eventCompletionStatus", () => {
  it("uses the status recorded on the event over the game's current one", () => {
    const e = event("CHANGE_COMPLETION_STATUS", libraryEntry("COMPLETED"), statusChange("IN_PROGRESS", "UNPLAYED"));
    expect(eventCompletionStatus(e)).toBe("IN_PROGRESS");
  });

  it("is null when the recorded change cleared the status", () => {
    const e = event("CHANGE_COMPLETION_STATUS", libraryEntry("COMPLETED"), statusChange(null, "DROPPED"));
    expect(eventCompletionStatus(e)).toBeNull();
  });

  it("falls back to the current status for events with no recorded change", () => {
    expect(eventCompletionStatus(event("CHANGE_COMPLETION_STATUS", libraryEntry("PAUSED")))).toBe("PAUSED");
  });

  it("is null with neither", () => {
    expect(eventCompletionStatus(event("CHANGE_COMPLETION_STATUS", libraryEntry(null)))).toBeNull();
    expect(eventCompletionStatus(event("FAVORITE_GAME", { game }))).toBeNull();
  });
});

describe("completionStatusVerb", () => {
  it.each<[GamePurchaseCompletionStatus, string]>([
    ["UNPLAYED", "set"],
    ["IN_PROGRESS", "is playing"],
    ["DROPPED", "dropped"],
    ["COMPLETED", "completed"],
    ["FULLY_COMPLETED", "100%'d"],
    ["NOT_APPLICABLE", "set"],
    ["PAUSED", "paused"]
  ])("is %s → %j", (status, verb) => {
    expect(completionStatusVerb(event("CHANGE_COMPLETION_STATUS", libraryEntry(null), statusChange(status)))).toBe(
      verb
    );
  });

  it("falls back to a generic verb without a status", () => {
    expect(completionStatusVerb(event("CHANGE_COMPLETION_STATUS", libraryEntry(null)))).toBe("changed the status of");
  });
});

describe("eventBadge", () => {
  it("labels additions, favorites, new users and follows", () => {
    expect(eventBadge(event("ADD_TO_LIBRARY", libraryEntry("COMPLETED")))).toEqual({
      label: "Added",
      cssClass: "badge-added"
    });
    expect(eventBadge(event("FAVORITE_GAME", { game }))).toEqual({ label: "Favorited", cssClass: "badge-favorited" });
    expect(eventBadge(event("NEW_USER", author))).toEqual({ label: "New User", cssClass: "badge-new-user" });
    expect(eventBadge(event("FOLLOWING", { followed: author }))).toEqual({
      label: "Followed",
      cssClass: "badge-followed"
    });
  });

  it.each<[GamePurchaseCompletionStatus, string, string]>([
    ["UNPLAYED", "Unplayed", "badge-unplayed"],
    ["IN_PROGRESS", "In Progress", "badge-in-progress"],
    ["DROPPED", "Dropped", "badge-dropped"],
    ["COMPLETED", "Completed", "badge-completed"],
    ["FULLY_COMPLETED", "100%", "badge-fully-completed"],
    ["NOT_APPLICABLE", "N/A", "badge-not-applicable"],
    ["PAUSED", "Paused", "badge-paused"]
  ])("labels a change to %s with the recorded status", (status, label, cssClass) => {
    const e = event("CHANGE_COMPLETION_STATUS", libraryEntry("COMPLETED"), statusChange(status));
    expect(eventBadge(e)).toEqual({ label, cssClass });
  });

  it("has no badge for a status change with no status", () => {
    expect(eventBadge(event("CHANGE_COMPLETION_STATUS", libraryEntry(null)))).toBeNull();
  });
});

describe("canDeleteEvent", () => {
  const own = event("NEW_USER", author);

  it("lets nobody delete when signed out", () => {
    expect(canDeleteEvent(own, null)).toBeFalsy();
  });

  it("lets members delete only their own events", () => {
    expect(canDeleteEvent(own, { id: "1", role: "MEMBER" })).toBeTruthy();
    expect(canDeleteEvent(own, { id: "2", role: "MEMBER" })).toBeFalsy();
  });

  it.each(["MODERATOR", "ADMIN"] as const)("lets a %s delete anyone's events", (role) => {
    expect(canDeleteEvent(own, { id: "2", role })).toBeTruthy();
  });
});
