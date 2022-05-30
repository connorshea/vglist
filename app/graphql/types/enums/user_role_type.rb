# typed: strict
module Types::Enums
  class UserRoleType < Types::BaseEnum
    description "Roles that a user can have, these define permissions levels. Most users will be `MEMBER`."

    value "MEMBER", value: 'member', description: "User is a regular user."
    value "MODERATOR", value: 'moderator', description: "User has some heightened permissions."
    value "ADMIN", value: 'admin', description: "User is an admin and has the highest permissions."
  end
end
