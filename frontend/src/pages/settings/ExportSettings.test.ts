import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { ref } from "vue";
import ExportSettings from "./ExportSettings.vue";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mutationState } = vi.hoisted(() => ({
  mutationState: { libraryJson: "" }
}));

vi.mock("@/composables/useGraphQL", () => ({
  useMutation: () => ({
    mutate: () => Promise.resolve({ exportLibrary: { libraryJson: mutationState.libraryJson, errors: [] } }),
    loading: ref(false)
  })
}));

const writeText = vi.fn<(text: string) => Promise<void>>();

beforeEach(() => {
  mutationState.libraryJson = '[{"game":{"id":26,"name":"Zero Hour"},"rating":90}]';
  writeText.mockReset();
  writeText.mockResolvedValue(undefined);
  Object.defineProperty(navigator, "clipboard", { value: { writeText }, configurable: true });
  URL.createObjectURL = vi.fn<(obj: Blob | MediaSource) => string>(() => "blob:export");
  URL.revokeObjectURL = vi.fn<(url: string) => void>();
});

afterEach(() => {
  vi.useRealTimers();
});

async function mountAndExport() {
  const wrapper = mount(ExportSettings);
  await wrapper.get("button.is-primary").trigger("click");
  await flushPromises();
  return wrapper;
}

describe("ExportSettings", () => {
  it("pretty-prints the exported JSON across multiple lines", async () => {
    const wrapper = await mountAndExport();
    const text = wrapper.get("pre.export-json").text();

    expect(text.split("\n").length).toBeGreaterThan(1);
    expect(text).toContain('"name": "Zero Hour"');
  });

  it("shows the raw string when the export isn't valid JSON", async () => {
    mutationState.libraryJson = "not json";
    const wrapper = await mountAndExport();

    expect(wrapper.get("pre.export-json").text()).toBe("not json");
  });

  it("copies the pretty-printed JSON and shows Copied feedback", async () => {
    vi.useFakeTimers();
    const wrapper = await mountAndExport();
    const button = wrapper.get("button.export-copy");

    expect(button.text()).toBe("Copy");
    await button.trigger("click");
    await flushPromises();

    expect(writeText).toHaveBeenCalledWith(wrapper.get("pre.export-json").text());
    expect(button.text()).toBe("Copied");
    expect(wrapper.get('[role="status"].is-sr-only').text()).toBe("JSON copied to clipboard");

    vi.advanceTimersByTime(2000);
    await flushPromises();
    expect(button.text()).toBe("Copy");
  });

  it("reports when the clipboard write fails", async () => {
    writeText.mockRejectedValue(new Error("denied"));
    const wrapper = await mountAndExport();
    await wrapper.get("button.export-copy").trigger("click");
    await flushPromises();

    expect(wrapper.get("button.export-copy").text()).toBe("Copy failed");
  });
});
