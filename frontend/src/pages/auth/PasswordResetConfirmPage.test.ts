import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import PasswordResetConfirmPage from "./PasswordResetConfirmPage.vue";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockRoute, mockResetPassword } = vi.hoisted(() => ({
  mockRoute: { query: { reset_password_token: "valid-token-123" } as Record<string, string> },
  mockResetPassword:
    vi.fn<(token: string, pw: string, pwc: string) => Promise<{ success: boolean; errors: string[] }>>()
}));

vi.mock("vue-router", () => ({
  useRoute: () => mockRoute,
  RouterLink: {
    template: "<a><slot /></a>",
    props: ["to"]
  }
}));

vi.mock("@/composables/useAuth", () => ({
  useAuth: () => ({
    resetPassword: mockResetPassword
  })
}));

// ── Tests ─────────────────────────────────────────────────────────

describe("PasswordResetConfirmPage", () => {
  beforeEach(() => {
    mockRoute.query = { reset_password_token: "valid-token-123" };
    mockResetPassword.mockReset();
  });

  it("renders the form with password fields", () => {
    const wrapper = mount(PasswordResetConfirmPage);

    expect(wrapper.find("h1").text()).toBe("Set New Password");
    expect(wrapper.findAll("input[type='password']")).toHaveLength(2);
    expect(wrapper.find("button[type='submit']").text()).toBe("Reset Password");
  });

  it("calls resetPassword with token and passwords on submit", async () => {
    mockResetPassword.mockResolvedValue({ success: true, errors: [] });
    const wrapper = mount(PasswordResetConfirmPage);

    const inputs = wrapper.findAll("input[type='password']");
    await inputs[0].setValue("newpassword123");
    await inputs[1].setValue("newpassword123");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mockResetPassword).toHaveBeenCalledWith("valid-token-123", "newpassword123", "newpassword123");
  });

  it("shows success message and hides the form on success", async () => {
    mockResetPassword.mockResolvedValue({ success: true, errors: [] });
    const wrapper = mount(PasswordResetConfirmPage);

    const inputs = wrapper.findAll("input[type='password']");
    await inputs[0].setValue("newpassword123");
    await inputs[1].setValue("newpassword123");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(wrapper.find(".notification.is-success").text()).toContain("Your password has been reset successfully");
    expect(wrapper.find("form").exists()).toBe(false);
  });

  it("shows errors on failure", async () => {
    mockResetPassword.mockResolvedValue({ success: false, errors: ["Token is invalid or expired."] });
    const wrapper = mount(PasswordResetConfirmPage);

    const inputs = wrapper.findAll("input[type='password']");
    await inputs[0].setValue("newpassword123");
    await inputs[1].setValue("newpassword123");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(wrapper.find(".notification.is-danger").text()).toContain("Token is invalid or expired.");
    expect(wrapper.find("form").exists()).toBe(true);
  });

  it("shows an error when the reset token is missing", async () => {
    mockRoute.query = {};
    const wrapper = mount(PasswordResetConfirmPage);

    const inputs = wrapper.findAll("input[type='password']");
    await inputs[0].setValue("newpassword123");
    await inputs[1].setValue("newpassword123");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(wrapper.find(".notification.is-danger").text()).toContain("Missing password reset token");
    expect(mockResetPassword).not.toHaveBeenCalled();
  });
});
