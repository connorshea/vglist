import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import PasswordResetPage from "./PasswordResetPage.vue";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockRequestPasswordReset } = vi.hoisted(() => ({
  mockRequestPasswordReset: vi.fn<(email: string) => Promise<string>>()
}));

vi.mock("vue-router", () => ({
  useRouter: () => ({ push: vi.fn<() => void>() })
}));

vi.mock("@/composables/useAuth", () => ({
  useAuth: () => ({
    requestPasswordReset: mockRequestPasswordReset
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

describe("PasswordResetPage", () => {
  beforeEach(() => {
    mockRequestPasswordReset.mockReset();
  });

  it("renders the form with an email field", () => {
    const wrapper = mount(PasswordResetPage, mountOptions);

    expect(wrapper.find("h1").text()).toBe("Reset Password");
    expect(wrapper.find("input[type='email']").exists()).toBeTruthy();
    expect(wrapper.find("button[type='submit']").text()).toBe("Send Reset Instructions");
  });

  it("calls requestPasswordReset with the email on submit", async () => {
    mockRequestPasswordReset.mockResolvedValue("Check your email for instructions.");
    const wrapper = mount(PasswordResetPage, mountOptions);

    await wrapper.find("input[type='email']").setValue("test@example.com");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mockRequestPasswordReset).toHaveBeenCalledWith("test@example.com");
  });

  it("shows success message and hides the form after submission", async () => {
    mockRequestPasswordReset.mockResolvedValue("Check your email for instructions.");
    const wrapper = mount(PasswordResetPage, mountOptions);

    await wrapper.find("input[type='email']").setValue("test@example.com");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(wrapper.find(".notification.is-success").text()).toContain("Check your email for instructions.");
    expect(wrapper.find("form").exists()).toBeFalsy();
  });

  it("shows loading state while submitting", async () => {
    mockRequestPasswordReset.mockReturnValue(new Promise<string>(() => {}));
    const wrapper = mount(PasswordResetPage, mountOptions);

    await wrapper.find("input[type='email']").setValue("test@example.com");
    await wrapper.find("form").trigger("submit");

    expect(wrapper.find("button[type='submit']").text()).toBe("Sending...");
    expect(wrapper.find("button[type='submit']").attributes("disabled")).toBeDefined();
  });
});
