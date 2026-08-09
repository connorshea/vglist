import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount } from "@vue/test-utils";
import ResourceForm from "./ResourceForm.vue";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockAuthStore } = vi.hoisted(() => ({
  mockAuthStore: { isModerator: true }
}));

vi.mock("@/stores/auth", () => ({
  useAuthStore: () => mockAuthStore
}));

const baseProps = {
  name: "",
  wikidataId: "",
  label: "Platform",
  pluralLabel: "platforms",
  isEditing: false,
  cancelTo: "/platforms"
};

function mountForm(props: Partial<typeof baseProps> & Record<string, unknown> = {}) {
  return mount(ResourceForm, {
    props: { ...baseProps, ...props },
    global: {
      stubs: {
        RouterLink: true
      }
    }
  });
}

// ── Tests ─────────────────────────────────────────────────────────

describe("ResourceForm", () => {
  beforeEach(() => {
    mockAuthStore.isModerator = true;
  });

  it("renders a create heading and button when not editing", () => {
    const wrapper = mountForm();

    expect(wrapper.find("h1").text()).toBe("New Platform");
    expect(wrapper.find("button[type='submit']").text()).toBe("Create Platform");
  });

  it("renders an edit heading and button when editing", () => {
    const wrapper = mountForm({ isEditing: true });

    expect(wrapper.find("h1").text()).toBe("Edit Platform");
    expect(wrapper.find("button[type='submit']").text()).toBe("Save Changes");
  });

  it("populates the fields from its props", () => {
    const wrapper = mountForm({ name: "Nintendo Switch", wikidataId: "19610114" });

    expect(wrapper.find<HTMLInputElement>("#platform-name").element.value).toBe("Nintendo Switch");
    expect(wrapper.find<HTMLInputElement>("#platform-wikidata-id").element.value).toBe("19610114");
  });

  it("emits update events when the fields change", async () => {
    const wrapper = mountForm();

    await wrapper.find("#platform-name").setValue("Xbox");
    await wrapper.find("#platform-wikidata-id").setValue("13361286");

    expect(wrapper.emitted("update:name")).toEqual([["Xbox"]]);
    expect(wrapper.emitted("update:wikidataId")).toEqual([["13361286"]]);
  });

  it("emits submit when the form is submitted", async () => {
    const wrapper = mountForm();

    await wrapper.find("form").trigger("submit");

    expect(wrapper.emitted("submit")).toHaveLength(1);
  });

  it("shows a loading message instead of the form while fetching", () => {
    const wrapper = mountForm({ isEditing: true, loading: true });

    expect(wrapper.text()).toContain("Loading platform...");
    expect(wrapper.find("form").exists()).toBeFalsy();
  });

  it("shows the submit error when one is given", () => {
    const wrapper = mountForm({ submitError: "Wikidata has already been taken" });

    expect(wrapper.find(".notification.is-danger").text()).toBe("Wikidata has already been taken");
  });

  it("disables the submit button while submitting", () => {
    const wrapper = mountForm({ submitting: true });

    expect(wrapper.find("button[type='submit']").attributes("disabled")).toBeDefined();
  });

  it("hides the Wikidata field for resources that don't have one", () => {
    const wrapper = mountForm({ label: "Store", pluralLabel: "stores", withWikidataId: false });

    expect(wrapper.find("#store-name").exists()).toBeTruthy();
    expect(wrapper.find("#store-wikidata-id").exists()).toBeFalsy();
  });

  it("hides the form from users who aren't moderators", () => {
    mockAuthStore.isModerator = false;
    const wrapper = mountForm();

    expect(wrapper.find("form").exists()).toBeFalsy();
    expect(wrapper.find(".notification.is-warning").text()).toContain(
      "You must be a moderator or admin to create or edit platforms."
    );
  });
});
