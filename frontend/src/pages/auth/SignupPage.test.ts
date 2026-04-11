import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import SignupPage from "./SignupPage.vue";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockSignUp } = vi.hoisted(() => ({
  mockSignUp:
    vi.fn<
      (
        username: string,
        email: string,
        password: string,
        passwordConfirmation: string
      ) => Promise<{ success: boolean; errors: string[] }>
    >()
}));

vi.mock("vue-router", () => ({
  useRouter: () => ({ push: vi.fn<() => void>() })
}));

vi.mock("@/composables/useAuth", () => ({
  useAuth: () => ({
    signUp: mockSignUp
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

describe("SignupPage", () => {
  beforeEach(() => {
    mockSignUp.mockReset();
  });

  it("renders the form with all required fields", () => {
    const wrapper = mount(SignupPage, mountOptions);

    expect(wrapper.find("h1").text()).toBe("Sign Up");
    expect(wrapper.find("input[type='text']").exists()).toBeTruthy();
    expect(wrapper.find("input[type='email']").exists()).toBeTruthy();
    expect(wrapper.findAll("input[type='password']")).toHaveLength(2);
    expect(wrapper.find("button[type='submit']").text()).toBe("Sign Up");
  });

  it("calls signUp with all fields on submit", async () => {
    mockSignUp.mockResolvedValue({ success: true, errors: [] });
    const wrapper = mount(SignupPage, mountOptions);

    await wrapper.find("input[type='text']").setValue("testuser");
    await wrapper.find("input[type='email']").setValue("test@example.com");
    const passwordInputs = wrapper.findAll("input[type='password']");
    await passwordInputs[0].setValue("password123");
    await passwordInputs[1].setValue("password123");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mockSignUp).toHaveBeenCalledWith("testuser", "test@example.com", "password123", "password123");
  });

  it("shows success message and hides the form on success", async () => {
    mockSignUp.mockResolvedValue({ success: true, errors: [] });
    const wrapper = mount(SignupPage, mountOptions);

    await wrapper.find("input[type='text']").setValue("testuser");
    await wrapper.find("input[type='email']").setValue("test@example.com");
    const passwordInputs = wrapper.findAll("input[type='password']");
    await passwordInputs[0].setValue("password123");
    await passwordInputs[1].setValue("password123");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(wrapper.find(".notification.is-success").text()).toContain("Account created successfully");
    expect(wrapper.find("form").exists()).toBeFalsy();
  });

  it("shows errors on failed sign-up", async () => {
    mockSignUp.mockResolvedValue({ success: false, errors: ["Email has already been taken."] });
    const wrapper = mount(SignupPage, mountOptions);

    await wrapper.find("input[type='text']").setValue("testuser");
    await wrapper.find("input[type='email']").setValue("taken@example.com");
    const passwordInputs = wrapper.findAll("input[type='password']");
    await passwordInputs[0].setValue("password123");
    await passwordInputs[1].setValue("password123");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(wrapper.find(".notification.is-danger").text()).toContain("Email has already been taken.");
    expect(wrapper.find("form").exists()).toBeTruthy();
  });

  it("shows loading state while submitting", async () => {
    mockSignUp.mockReturnValue(new Promise(() => {}));
    const wrapper = mount(SignupPage, mountOptions);

    await wrapper.find("input[type='text']").setValue("testuser");
    await wrapper.find("input[type='email']").setValue("test@example.com");
    const passwordInputs = wrapper.findAll("input[type='password']");
    await passwordInputs[0].setValue("password123");
    await passwordInputs[1].setValue("password123");
    await wrapper.find("form").trigger("submit");

    expect(wrapper.find("button[type='submit']").text()).toBe("Creating account...");
    expect(wrapper.find("button[type='submit']").attributes("disabled")).toBeDefined();
  });
});
