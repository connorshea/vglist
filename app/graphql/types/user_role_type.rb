# typed: true
module Types
  class UserRoleType < Types::BaseEnum
    value "MEMBER", value: 'member', description: "User is a regular user."
    value "MODERATOR", value: 'moderator', description: "User has some heightened permissions."
    value "ADMIN", value: 'admin', description: "User is an admin and has the highest permissions."
  end
end
