# typed: strong
module Types
  class UserPrivacyType < Types::BaseEnum
    value "PUBLIC_ACCOUNT", value: 'public_account', description: "User has a publicly-visible profile."
    value "PRIVATE_ACCOUNT", value: 'private_account', description: "User has a private profile."
  end
end
