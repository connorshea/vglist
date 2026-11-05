import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";
import LibraryFilterRail from "./LibraryFilterRail.vue";

function mountRail(props: Partial<InstanceType<typeof LibraryFilterRail>["$props"]> = {}) {
  return mount(LibraryFilterRail, {
    props: {
      search: "",
      status: null,
      gamesCount: 12,
      statusCounts: { IN_PROGRESS: 2, COMPLETED: 10 },
      platforms: Array.from({ length: 8 }, (_, i) => ({
        platform: { id: String(i + 1), name: `Platform ${i + 1}` },
        count: 8 - i
      })),
      stores: [{ store: { id: "1", name: "Steam" }, count: 5 }],
      platformIds: [],
      storeIds: [],
      minRating: null,
      maxRating: null,
      ...props
    }
  });
}

describe("LibraryFilterRail", () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it("marks the active status and emits a new one when picked", async () => {
    const wrapper = mountRail({ status: "COMPLETED" });
    const completed = wrapper.findAll("button").find((b) => b.text().startsWith("Completed"));

    expect(completed?.attributes("aria-pressed")).toBe("true");

    const all = wrapper.findAll("button").find((b) => b.text().startsWith("All games"));
    await all?.trigger("click");

    expect(wrapper.emitted("update:status")).toEqual([[null]]);
  });

  it("only lists No status when some game has no status", async () => {
    expect(mountRail().text()).not.toContain("No status");

    const wrapper = mountRail({ statusCounts: { COMPLETED: 10, NONE: 2 } });
    const noStatus = wrapper.findAll("button").find((b) => b.text().startsWith("No status"));

    expect(noStatus?.text()).toContain("2");
    await noStatus?.trigger("click");

    expect(wrapper.emitted("update:status")).toEqual([["NONE"]]);
  });

  it("emits the platform to toggle when its checkbox changes", async () => {
    const wrapper = mountRail();
    await wrapper.find('input[type="checkbox"]').trigger("change");

    expect(wrapper.emitted("toggle-platform")).toEqual([["1"]]);
  });

  it("shows six platforms until asked for the rest, keeping selected ones visible", async () => {
    const wrapper = mountRail({ platformIds: ["8"] });

    expect(wrapper.text()).toContain("Platform 8");
    expect(wrapper.text()).not.toContain("Platform 7");

    const more = wrapper.findAll("button").find((b) => b.text() === "Show 2 more");
    await more?.trigger("click");

    expect(wrapper.text()).toContain("Platform 7");
  });

  it("emits the rating range once the slider settles, with open ends as null", async () => {
    const wrapper = mountRail();
    const [min] = wrapper.findAll('input[type="range"]');

    await min.setValue(60);
    await min.trigger("change");
    await min.setValue(70);
    await min.trigger("change");
    vi.advanceTimersByTime(300);

    expect(wrapper.emitted("update:rating")).toEqual([[70, null]]);
  });
});
