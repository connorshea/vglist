import { describe, expect, it } from "vitest";
import { roleChanges } from "./user-roles";

const labels = (role: Parameters<typeof roleChanges>[0]) => roleChanges(role).map((change) => change.label);

describe("roleChanges", () => {
  it("offers promotions to a member", () => {
    expect(labels("MEMBER")).toEqual(["Make moderator", "Make admin"]);
  });

  it("offers promotion and demotion to a moderator", () => {
    expect(labels("MODERATOR")).toEqual(["Make admin", "Demote to member"]);
  });

  it("offers demotions to an admin", () => {
    expect(labels("ADMIN")).toEqual(["Demote to moderator", "Demote to member"]);
  });

  it("never offers the user's current role", () => {
    for (const role of ["MEMBER", "MODERATOR", "ADMIN"] as const) {
      expect(roleChanges(role).map((change) => change.role)).not.toContain(role);
    }
  });

  it("describes what an admin loses when demoted to member", () => {
    const change = roleChanges("ADMIN").find((c) => c.role === "MEMBER");
    expect(change).toMatchObject({
      title: "Demote to member?",
      description: "will lose their admin privileges and become a regular member.",
      noun: "a member"
    });
  });

  it("describes a demotion from admin to moderator", () => {
    const change = roleChanges("ADMIN").find((c) => c.role === "MODERATOR");
    expect(change?.description).toBe("will lose their admin privileges and become a moderator.");
  });

  it("describes a promotion to admin", () => {
    const change = roleChanges("MEMBER").find((c) => c.role === "ADMIN");
    expect(change).toMatchObject({
      title: "Make admin?",
      description: "will be granted full admin privileges.",
      noun: "an admin"
    });
  });
});
