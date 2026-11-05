import { describe, expect, it } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import GameReviewsCard, { type GameReview } from "./GameReviewsCard.vue";

function review(overrides: Partial<GameReview> = {}): GameReview {
  return {
    id: "1",
    comments: "Worth the wait.",
    rating: 95,
    hoursPlayed: 68,
    replayCount: 1,
    completionStatus: "FULLY_COMPLETED",
    updatedAt: new Date().toISOString(),
    user: { id: "u1", username: "mkellner", slug: "mkellner", avatarUrl: null },
    platforms: { nodes: [{ id: "p1", name: "Nintendo Switch 2" }] },
    ...overrides
  };
}

function mountCard(props: Partial<InstanceType<typeof GameReviewsCard>["$props"]> = {}) {
  return mount(GameReviewsCard, {
    props: { reviews: [review()], totalCount: 1, sort: "RECENT", loading: false, ...props },
    global: { stubs: { RouterLink: RouterLinkStub } }
  });
}

describe("GameReviewsCard", () => {
  it("shows the reviewer, score, status, text and play details", () => {
    const wrapper = mountCard();
    const text = wrapper.text();

    expect(wrapper.find(".review-user").text()).toBe("mkellner");
    expect(wrapper.find(".review-score").text()).toBe("Rated 95");
    expect(wrapper.find(".review-score").classes()).toContain("r-great");
    expect(wrapper.find(".review-status").text()).toBe("100%");
    expect(text).toContain("Worth the wait.");
    expect(wrapper.find(".review-meta").text()).toBe("68h played · Nintendo Switch 2 · Played twice");
  });

  it("leaves out a score and status the reviewer didn't set", () => {
    const wrapper = mountCard({
      reviews: [review({ rating: null, completionStatus: null, hoursPlayed: null, replayCount: 0 })]
    });

    expect(wrapper.find(".review-score").exists()).toBeFalsy();
    expect(wrapper.find(".review-status").exists()).toBeFalsy();
    expect(wrapper.find(".review-meta").text()).toBe("Nintendo Switch 2");
  });

  it("shows an empty state once loaded with no reviews", () => {
    expect(mountCard({ reviews: [], totalCount: 0 }).text()).toContain("No reviews yet.");
    expect(mountCard({ reviews: [], totalCount: 0, loading: true }).text()).not.toContain("No reviews yet.");
  });

  it("marks the current sort and emits a new one", async () => {
    const wrapper = mountCard({ totalCount: 2, sort: "HIGHEST_RATING" });
    const buttons = wrapper.findAll(".review-sorts button");

    expect(buttons.map((b) => b.attributes("aria-pressed"))).toEqual(["false", "true", "false"]);
    await buttons[2].trigger("click");
    expect(wrapper.emitted("update:sort")).toEqual([["LOWEST_RATING"]]);
  });

  it("hides the sort when there's only one review", () => {
    expect(mountCard().find(".review-sorts").exists()).toBeFalsy();
  });

  it("offers more reviews until all are shown", async () => {
    const wrapper = mountCard({ totalCount: 7 });
    await wrapper.find(".review-load-more").trigger("click");

    expect(wrapper.emitted("load-more")).toHaveLength(1);
    expect(mountCard({ totalCount: 1 }).find(".review-load-more").exists()).toBeFalsy();
  });

  it("truncates long reviews until expanded", async () => {
    const long = `${"word ".repeat(150)}the end`;
    const wrapper = mountCard({ reviews: [review({ comments: long })] });
    const more = wrapper.find(".review-more");

    expect(wrapper.find(".review-text").text()).not.toContain("the end");
    expect(more.attributes("aria-expanded")).toBe("false");

    await more.trigger("click");
    expect(wrapper.find(".review-text").text()).toContain("the end");
    expect(wrapper.find(".review-more").text()).toBe("Show less");
  });
});
