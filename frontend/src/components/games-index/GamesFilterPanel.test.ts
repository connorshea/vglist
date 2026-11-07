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
  it("labels the apply button without a match count", () => {
    const wrapper = mountPanel();
    expect(wrapper.find(".apply-btn").text()).toBe("Apply Filters");
    wrapper.unmount();
  });

  it("picks a genre with a search field like the engine filter", async () => {
    const wrapper = mountPanel();
    const input = wrapper.find("#games-filter-genre");
    expect(input.attributes("placeholder")).toBe("Any genre");
    expect(wrapper.find('label[for="games-filter-genre"]').text()).toBe("Genre");

    await wrapper.setProps({
      modelValue: { ...EMPTY_FILTERS, genre: "2" },
      names: { platform: null, genre: "Roguelike", engine: null }
    });
    expect(input.attributes("placeholder")).toBe("Roguelike");
    await wrapper.find('[aria-label="Clear genre filter"]').trigger("click");
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
