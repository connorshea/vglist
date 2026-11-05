import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import ConfirmationResendPage from "./ConfirmationResendPage.vue";

// ── Hoisted mocks ─────────────────────────────────────────────────

interface ResendResult {
  success: boolean;
  message: string;
  errors: string[];
}

const { mockResendConfirmation } = vi.hoisted(() => ({
  mockResendConfirmation: vi.fn<(email: string) => Promise<ResendResult>>()
}));

vi.mock("@/composables/useAuth", () => ({
  useAuth: () => ({
    resendConfirmation: mockResendConfirmation
  })
}));

const mountOptions = {
  global: {
    stubs: {
      RouterLink: true
    }
  }
};

// ── Tests ─────────────────────────────────────────────────────────

describe("ConfirmationResendPage", () => {
  beforeEach(() => {
    mockResendConfirmation.mockReset();
  });

  it("renders the form with a labelled email field", () => {
    const wrapper = mount(ConfirmationResendPage, mountOptions);

    expect(wrapper.find("h1").text()).toBe("Resend Confirmation Email");
    expect(wrapper.find("label[for='confirmation-resend-email']").exists()).toBeTruthy();
    expect(wrapper.find("input#confirmation-resend-email[type='email']").exists()).toBeTruthy();
    expect(wrapper.find("button[type='submit']").text()).toBe("Resend Confirmation Email");
  });

  it("calls resendConfirmation with the email and shows the success message", async () => {
    mockResendConfirmation.mockResolvedValue({ success: true, message: "Check your inbox.", errors: [] });
    const wrapper = mount(ConfirmationResendPage, mountOptions);

    await wrapper.find("input[type='email']").setValue("test@example.com");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mockResendConfirmation).toHaveBeenCalledWith("test@example.com");
    expect(wrapper.find(".notification.is-success").text()).toContain("Check your inbox.");
    expect(wrapper.find("form").exists()).toBeFalsy();
  });

  it("shows errors and keeps the form when sending fails", async () => {
    mockResendConfirmation.mockResolvedValue({
      success: false,
      message: "",
      errors: ["Too many requests. Please try again later."]
    });
    const wrapper = mount(ConfirmationResendPage, mountOptions);

    await wrapper.find("input[type='email']").setValue("test@example.com");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(wrapper.find(".notification.is-danger").text()).toContain("Too many requests");
    expect(wrapper.find("form").exists()).toBeTruthy();
  });

  it("shows loading state while submitting", async () => {
    mockResendConfirmation.mockReturnValue(new Promise<ResendResult>(() => {}));
    const wrapper = mount(ConfirmationResendPage, mountOptions);

    await wrapper.find("input[type='email']").setValue("test@example.com");
    await wrapper.find("form").trigger("submit");

    expect(wrapper.find("button[type='submit']").text()).toBe("Sending...");
    expect(wrapper.find("button[type='submit']").attributes("disabled")).toBeDefined();
  });
});
