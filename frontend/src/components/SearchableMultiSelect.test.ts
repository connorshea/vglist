import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, ref } from "vue";
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import SearchableMultiSelect from "./SearchableMultiSelect.vue";
import { SEARCH_DEBOUNCE_MS } from "@/composables/useDebouncedSearch";

interface Option {
  id: string;
  name: string;
}

const RPG = { id: "1", name: "RPG" };
const ACTION_RPG = { id: "2", name: "Action RPG" };
const TACTICAL_RPG = { id: "3", name: "Tactical RPG" };

enableAutoUnmount(afterEach);

const scrollIntoView = vi.fn<(options?: ScrollIntoViewOptions) => void>();

function mountSelect(initial: Option[] = []) {
  const value = ref<Option[]>(initial);
  const search = vi.fn<(query: string) => Promise<Option[]>>().mockResolvedValue([RPG, ACTION_RPG, TACTICAL_RPG]);
  const wrapper = mount(
    defineComponent({
      setup() {
        return () =>
          h(SearchableMultiSelect, {
            modelValue: value.value,
            "onUpdate:modelValue": (v: Option[]) => (value.value = v),
            search,
            label: "Genres"
          });
      }
    }),
    { attachTo: document.body }
  );
  const input = wrapper.find<HTMLInputElement>('input[role="combobox"]');
  return { wrapper, input, value, search };
}

async function typeAndWait(input: ReturnType<typeof mountSelect>["input"], text: string) {
  await input.trigger("focus");
  await input.setValue(text);
  await vi.advanceTimersByTimeAsync(SEARCH_DEBOUNCE_MS);
  await flushPromises();
}

function tags(wrapper: ReturnType<typeof mountSelect>["wrapper"]): string[] {
  return wrapper.findAll(".ss-tag").map((t) => t.text());
}

describe("SearchableMultiSelect", () => {
  beforeEach(() => {
    vi.useFakeTimers({ toFake: ["setTimeout", "clearTimeout"] });
    // jsdom doesn't lay anything out, so it has no scrollIntoView.
    Element.prototype.scrollIntoView = scrollIntoView;
    scrollIntoView.mockClear();
  });

  afterEach(() => {
    vi.useRealTimers();
    delete (Element.prototype as Partial<Element>).scrollIntoView;
  });

  it("shows the selected records as removable tags", () => {
    const { wrapper } = mountSelect([RPG, TACTICAL_RPG]);
    expect(tags(wrapper)).toEqual(["RPG", "Tactical RPG"]);
    expect(wrapper.findAll(".ss-tag-remove").map((b) => b.attributes("aria-label"))).toEqual([
      "Remove RPG",
      "Remove Tactical RPG"
    ]);
  });

  it("only shows the placeholder while nothing is selected", () => {
    expect(mountSelect().input.attributes("placeholder")).toBe("Search...");
    expect(mountSelect([RPG]).input.attributes("placeholder")).toBe("");
  });

  it("adds the highlighted result with Enter, keeping the list open for more", async () => {
    const { wrapper, input, value } = mountSelect([RPG]);
    await typeAndWait(input, "rpg");
    await input.trigger("keydown", { key: "ArrowDown" });
    expect(scrollIntoView).toHaveBeenLastCalledWith({ block: "nearest" });

    const event = new KeyboardEvent("keydown", { key: "Enter", cancelable: true });
    input.element.dispatchEvent(event);
    await wrapper.vm.$nextTick();

    expect(event.defaultPrevented).toBeTruthy();
    expect(value.value).toEqual([RPG, ACTION_RPG]);
    expect(input.element.value).toBe("");
    expect(input.attributes("aria-expanded")).toBe("true");
    expect(document.activeElement).toBe(input.element);
  });

  it("removes an already-selected result when it's picked again", async () => {
    const { wrapper, input, value } = mountSelect([RPG, ACTION_RPG]);
    await typeAndWait(input, "rpg");
    expect(wrapper.findAll('[role="option"]').map((o) => o.attributes("aria-selected"))).toEqual([
      "true",
      "true",
      "false"
    ]);
    await wrapper.findAll('[role="option"]')[0].trigger("mousedown");
    expect(value.value).toEqual([ACTION_RPG]);
  });

  it("keeps the arrow keys within the list", async () => {
    const { wrapper, input } = mountSelect();
    await typeAndWait(input, "rpg");
    for (let i = 0; i < 5; i++) {
      await input.trigger("keydown", { key: "ArrowDown" });
    }
    expect(wrapper.find(".ss-option.highlighted").text()).toBe("Tactical RPG");
    for (let i = 0; i < 5; i++) {
      await input.trigger("keydown", { key: "ArrowUp" });
    }
    expect(wrapper.find(".ss-option.highlighted").text()).toBe("RPG");
  });

  it("removes the last tag on Backspace in an empty input", async () => {
    const { input, value } = mountSelect([RPG, ACTION_RPG]);
    await input.trigger("focus");
    await input.trigger("keydown", { key: "Backspace" });
    expect(value.value).toEqual([RPG]);
  });

  it("leaves the tags alone on Backspace while there's text to delete", async () => {
    const { input, value } = mountSelect([RPG, ACTION_RPG]);
    await input.trigger("focus");
    await input.setValue("ta");
    await input.trigger("keydown", { key: "Backspace" });
    expect(value.value).toEqual([RPG, ACTION_RPG]);
  });

  it("removes a tag from its remove button without opening the list", async () => {
    const { wrapper, input, value } = mountSelect([RPG, ACTION_RPG]);
    await wrapper.findAll(".ss-tag-remove")[0].trigger("click");
    expect(value.value).toEqual([ACTION_RPG]);
    expect(input.attributes("aria-expanded")).toBe("false");
  });

  it("closes and clears the query on Escape, keeping the selection", async () => {
    const { input, value } = mountSelect([RPG]);
    await typeAndWait(input, "tac");
    await input.trigger("keydown", { key: "Escape" });
    expect(input.attributes("aria-expanded")).toBe("false");
    expect(input.element.value).toBe("");
    expect(value.value).toEqual([RPG]);
  });

  it("opens the list with ArrowDown after Escape closed it", async () => {
    const { input } = mountSelect();
    await input.trigger("focus");
    await input.trigger("keydown", { key: "Escape" });
    await input.trigger("keydown", { key: "ArrowDown" });
    expect(input.attributes("aria-expanded")).toBe("true");
  });

  it("closes when focus leaves", async () => {
    const { input } = mountSelect();
    await typeAndWait(input, "rpg");
    await input.trigger("blur");
    expect(input.attributes("aria-expanded")).toBe("false");
    expect(input.element.value).toBe("");
  });

  it("focuses the input when the control around it is clicked", async () => {
    const { wrapper, input } = mountSelect([RPG]);
    await wrapper.find(".ss-control").trigger("click");
    expect(document.activeElement).toBe(input.element);
  });
});
