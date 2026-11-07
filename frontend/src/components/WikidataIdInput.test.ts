import { describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import WikidataIdInput from "./WikidataIdInput.vue";

function mountInput(modelValue = "") {
  return mount(WikidataIdInput, { props: { modelValue, id: "wikidata-id" } });
}

describe("WikidataIdInput", () => {
  it("passes attributes through to the input", () => {
    const wrapper = mountInput("123");

    expect(wrapper.find("input").attributes("id")).toBe("wikidata-id");
    expect(wrapper.find("input").element.value).toBe("123");
  });

  it("normalizes a pasted Wikidata URL right away", async () => {
    const wrapper = mountInput();
    const input = wrapper.find("input");

    input.element.value = "https://www.wikidata.org/wiki/Q13361286";
    input.element.dispatchEvent(new InputEvent("input", { inputType: "insertFromPaste" }));

    expect(input.element.value).toBe("13361286");
    expect(wrapper.emitted("update:modelValue")).toEqual([["13361286"]]);
  });

  it("normalizes a pasted Q-prefixed ID even when it matches the current value", async () => {
    const wrapper = mountInput("123");
    const input = wrapper.find("input");

    input.element.value = "Q123";
    input.element.dispatchEvent(new InputEvent("input", { inputType: "insertFromPaste" }));

    expect(input.element.value).toBe("123");
  });

  it("leaves a typed Q-prefixed ID alone until the field loses focus", async () => {
    const wrapper = mountInput();
    const input = wrapper.find("input");

    input.element.value = "Q13361286";
    await input.trigger("input");
    expect(input.element.value).toBe("Q13361286");

    await input.trigger("change");
    expect(input.element.value).toBe("13361286");
    expect(wrapper.emitted("update:modelValue")).toEqual([["Q13361286"], ["13361286"]]);
  });

  it("doesn't emit again on change when the ID is already numeric", async () => {
    const wrapper = mountInput();
    const input = wrapper.find("input");

    await input.setValue("13361286");
    await input.trigger("change");

    expect(wrapper.emitted("update:modelValue")).toEqual([["13361286"]]);
  });
});
