import { describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import GamesFilterPanel from "./GamesFilterPanel.vue";
import { EMPTY_FILTERS, type GameFilters } from "./format";

function mountPanel(modelValue: Partial<GameFilters> = {}, variant: "popover" | "sheet" = "popover") {
  return mount(GamesFilterPanel, {
    attachTo: document.body,
    props: {
      modelValue: { ...EMPTY_FILTERS, ...modelValue },
      names: { platform: null, genre: null, engine: null },
      genres: [
        { id: "1", name: "Metroidvania" },
        { id: "2", name: "Roguelike" }
      ],
      count: 38,
      signedIn: true,
      variant
    }
  });
}

function lastModelValue(wrapper: ReturnType<typeof mountPanel>): GameFilters {
  const events = wrapper.emitted("update:modelValue") ?? [];
  return events[events.length - 1][0] as GameFilters;
}

describe("GamesFilterPanel", () => {
  it("labels the apply button with the match count", () => {
    const wrapper = mountPanel();
    expect(wrapper.find(".apply-btn").text()).toBe("Show 38 games");
    wrapper.unmount();
  });

  it("toggles a genre pill on and off", async () => {
    const wrapper = mountPanel();
    await wrapper.findAll(".filter-pill")[1].trigger("click");
    expect(lastModelValue(wrapper).genre).toBe("2");

    await wrapper.setProps({ modelValue: { ...EMPTY_FILTERS, genre: "2" } });
    await wrapper.findAll(".filter-pill")[1].trigger("click");
    expect(lastModelValue(wrapper).genre).toBe("");
    wrapper.unmount();
  });

  it("keeps the year range the right way round", async () => {
    const wrapper = mountPanel({ toYear: "2010" });
    await wrapper.find("#games-filter-from").setValue("2015");
    expect(lastModelValue(wrapper)).toMatchObject({ fromYear: "2015", toYear: "2015" });
    wrapper.unmount();
  });

  it("clears every filter", async () => {
    const wrapper = mountPanel({ genre: "1", fromYear: "2015", hideLibrary: true });
    await wrapper.find(".clear-btn").trigger("click");
    expect(lastModelValue(wrapper)).toEqual(EMPTY_FILTERS);
    wrapper.unmount();
  });

  it("closes on Escape", async () => {
    const wrapper = mountPanel();
    await wrapper.find('[role="dialog"]').trigger("keydown", { key: "Escape" });
    expect(wrapper.emitted("close")).toHaveLength(1);
    wrapper.unmount();
  });

  it("only offers the platform search in the phone sheet", () => {
    const popover = mountPanel();
    expect(popover.find("#games-filter-platform").exists()).toBeFalsy();
    popover.unmount();

    const sheet = mountPanel({}, "sheet");
    expect(sheet.find("#games-filter-platform").exists()).toBeTruthy();
    expect(sheet.find('[role="dialog"]').attributes("aria-modal")).toBe("true");
    sheet.unmount();
  });
});
