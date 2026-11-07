import type { UserRole } from "@/types/graphql";

export interface RoleChange {
  role: UserRole;
  /** Menu item and confirm button label. */
  label: string;
  /** Confirm dialog title. */
  title: string;
  /** Follows the username in the confirm dialog body. */
  description: string;
  /** Follows "<username> is now" in the success message. */
  noun: string;
}

const RANK: Record<UserRole, number> = { MEMBER: 0, MODERATOR: 1, ADMIN: 2 };
const NOUN: Record<UserRole, string> = { MEMBER: "a member", MODERATOR: "a moderator", ADMIN: "an admin" };
const PRIVILEGES: Record<UserRole, string> = { MEMBER: "", MODERATOR: "moderator", ADMIN: "admin" };

function promotion(role: UserRole): RoleChange {
  const label = role === "ADMIN" ? "Make admin" : "Make moderator";
  const description =
    role === "ADMIN" ? "will be granted full admin privileges." : "will be granted moderator privileges.";
  return { role, label, title: `${label}?`, description, noun: NOUN[role] };
}

function demotion(from: UserRole, role: UserRole): RoleChange {
  const label = role === "MEMBER" ? "Demote to member" : "Demote to moderator";
  const becomes = role === "MEMBER" ? "a regular member" : "a moderator";
  return {
    role,
    label,
    title: `${label}?`,
    description: `will lose their ${PRIVILEGES[from]} privileges and become ${becomes}.`,
    noun: NOUN[role]
  };
}

/**
 * The role changes an admin can make to a user with the given role, like the
 * old app's profile menu: every role other than the current one. Promotions
 * come first, then demotions, each nearest role first.
 */
export function roleChanges(current: UserRole): RoleChange[] {
  const roles: UserRole[] = ["MEMBER", "MODERATOR", "ADMIN"];
  const promotions = roles.filter((role) => RANK[role] > RANK[current]).map(promotion);
  const demotions = roles
    .filter((role) => RANK[role] < RANK[current])
    .reverse()
    .map((role) => demotion(current, role));
  return [...promotions, ...demotions];
}
