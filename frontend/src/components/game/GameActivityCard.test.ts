import { describe, expect, it } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import GameActivityCard, { type GameActivityEvent } from "./GameActivityCard.vue";

const user = { id: "u1", username: "connor", slug: "connor", avatarUrl: null };

function event(overrides: Partial<GameActivityEvent>): GameActivityEvent {
  return {
    id: "1",
    eventCategory: "ADD_TO_LIBRARY",
    createdAt: new Date().toISOString(),
    user,
    completionStatusChange: null,
    eventable: { id: "gp1", completionStatus: null },
    ...overrides
  };
}

function lines(events: GameActivityEvent[]): string[] {
  const wrapper = mount(GameActivityCard, {
    props: { events },
    global: { stubs: { RouterLink: RouterLinkStub } }
  });
  return wrapper.findAll(".activity-text").map((el) => el.text().replace(/\s+/g, " "));
}

describe("GameActivityCard", () => {
  it("describes each kind of event", () => {
    expect(
      lines([
        event({ id: "1" }),
        event({ id: "2", eventCategory: "FAVORITE_GAME", eventable: {} }),
        event({
          id: "3",
          eventCategory: "CHANGE_COMPLETION_STATUS",
          completionStatusChange: { after: "COMPLETED" }
        }),
        event({
          id: "4",
          eventCategory: "CHANGE_COMPLETION_STATUS",
          completionStatusChange: { after: "IN_PROGRESS" }
        })
      ])
    ).toEqual([
      "connor added it to their library",
      "connor favorited it",
      "connor marked it Completed",
      "connor started playing it"
    ]);
  });

  it("uses the status the event changed to, not the entry's current one", () => {
    const [line] = lines([
      event({
        eventCategory: "CHANGE_COMPLETION_STATUS",
        completionStatusChange: { after: "DROPPED" },
        eventable: { id: "gp1", completionStatus: "COMPLETED" }
      })
    ]);

    expect(line).toBe("connor marked it Dropped");
  });

  it("falls back to the entry's status for older events", () => {
    const [line] = lines([
      event({ eventCategory: "CHANGE_COMPLETION_STATUS", eventable: { id: "gp1", completionStatus: "PAUSED" } })
    ]);

    expect(line).toBe("connor marked it Paused");
  });
});
