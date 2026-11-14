import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, ref } from "vue";
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import SearchableSelect from "./SearchableSelect.vue";
import { SEARCH_DEBOUNCE_MS } from "@/composables/useDebouncedSearch";

interface Option {
  id: string;
  name: string;
}

const VALVE = { id: "1", name: "Valve" };
const VALVE_SOFTWARE = { id: "2", name: "Valve Software" };
const VALVE_CORP = { id: "3", name: "Valve Corporation" };

enableAutoUnmount(afterEach);

const scrollIntoView = vi.fn<(options?: ScrollIntoViewOptions) => void>();

function mountSelect(initial: Option | null = null) {
  const value = ref<Option | null>(initial);
  const search = vi.fn<(query: string) => Promise<Option[]>>().mockResolvedValue([VALVE, VALVE_SOFTWARE, VALVE_CORP]);
  const wrapper = mount(
    defineComponent({
      setup() {
        return () =>
          h(SearchableSelect, {
            modelValue: value.value,
            "onUpdate:modelValue": (v: Option | null) => (value.value = v),
            search,
            label: "Developer"
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

function highlighted(wrapper: ReturnType<typeof mountSelect>["wrapper"]): string | undefined {
  return wrapper.find(".ss-option.highlighted").text();
}

describe("SearchableSelect", () => {
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

  it("labels the combobox and links it to the listbox", async () => {
    const { wrapper, input } = mountSelect();
    expect(wrapper.find("label").attributes("for")).toBe(input.attributes("id"));
    expect(input.attributes("aria-expanded")).toBe("false");
    await input.trigger("focus");
    expect(input.attributes("aria-expanded")).toBe("true");
    expect(wrapper.find('[role="listbox"]').attributes("id")).toBe(input.attributes("aria-controls"));
  });

  it("asks you to type before searching", async () => {
    const { wrapper, input, search } = mountSelect();
    await input.trigger("focus");
    expect(wrapper.text()).toContain("Type to search");
    expect(search).not.toHaveBeenCalled();
  });

  it("searches once typing pauses and lists the results", async () => {
    const { wrapper, input, search } = mountSelect();
    await typeAndWait(input, "valve");
    expect(search).toHaveBeenCalledWith("valve");
    expect(wrapper.findAll('[role="option"]').map((o) => o.text())).toEqual([
      "Valve",
      "Valve Software",
      "Valve Corporation"
    ]);
  });

  it("moves the highlight with the arrow keys, within the list", async () => {
    const { wrapper, input } = mountSelect();
    await typeAndWait(input, "valve");
    expect(highlighted(wrapper)).toBe("Valve");

    await input.trigger("keydown", { key: "ArrowDown" });
    await input.trigger("keydown", { key: "ArrowDown" });
    await input.trigger("keydown", { key: "ArrowDown" });
    expect(highlighted(wrapper)).toBe("Valve Corporation");
    // Long lists keep the highlighted option in view.
    expect(scrollIntoView).toHaveBeenLastCalledWith({ block: "nearest" });
    expect(input.attributes("aria-activedescendant")).toBe(wrapper.findAll('[role="option"]')[2].attributes("id"));

    await input.trigger("keydown", { key: "ArrowUp" });
    await input.trigger("keydown", { key: "ArrowUp" });
    await input.trigger("keydown", { key: "ArrowUp" });
    expect(highlighted(wrapper)).toBe("Valve");
  });

  it("picks the highlighted result with Enter, without submitting a form", async () => {
    const { wrapper, input, value } = mountSelect();
    await typeAndWait(input, "valve");
    await input.trigger("keydown", { key: "ArrowDown" });

    const event = new KeyboardEvent("keydown", { key: "Enter", cancelable: true });
    input.element.dispatchEvent(event);
    await wrapper.vm.$nextTick();

    expect(event.defaultPrevented).toBeTruthy();
    expect(value.value).toEqual(VALVE_SOFTWARE);
    expect(input.attributes("aria-expanded")).toBe("false");
    expect(input.element.value).toBe("");
  });

  it("does nothing on Enter with no results", async () => {
    const { input, value } = mountSelect();
    await input.trigger("focus");
    await input.trigger("keydown", { key: "Enter" });
    expect(value.value).toBeNull();
  });

  it("picks a result with the mouse", async () => {
    const { wrapper, input, value } = mountSelect();
    await typeAndWait(input, "valve");
    await wrapper.findAll('[role="option"]')[2].trigger("mousedown");
    expect(value.value).toEqual(VALVE_CORP);
  });

  it("marks the selected option", async () => {
    const { wrapper, input } = mountSelect(VALVE_SOFTWARE);
    await typeAndWait(input, "valve");
    expect(wrapper.findAll('[role="option"]').map((o) => o.attributes("aria-selected"))).toEqual([
      "false",
      "true",
      "false"
    ]);
  });

  it("closes and clears the query on Escape, keeping the selection", async () => {
    const { input, value } = mountSelect(VALVE);
    await typeAndWait(input, "soft");
    await input.trigger("keydown", { key: "Escape" });
    expect(input.attributes("aria-expanded")).toBe("false");
    expect(input.element.value).toBe("");
    expect(value.value).toEqual(VALVE);
  });

  it("closes when focus leaves", async () => {
    const { input } = mountSelect();
    await typeAndWait(input, "valve");
    await input.trigger("blur");
    expect(input.attributes("aria-expanded")).toBe("false");
    expect(input.element.value).toBe("");
  });

  it("clears the selection from the clear button and refocuses the input", async () => {
    const { wrapper, input, value } = mountSelect(VALVE);
    const clear = wrapper.find(".ss-clear");
    expect(clear.attributes("aria-label")).toBe("Clear Valve");
    await clear.trigger("click");
    await wrapper.vm.$nextTick();
    expect(value.value).toBeNull();
    expect(document.activeElement).toBe(input.element);
  });

  it("describes the selection to screen readers", () => {
    const { input } = mountSelect(VALVE);
    expect(input.attributes("aria-description")).toBe("Selected: Valve");
  });
});
