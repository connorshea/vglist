# typed: strict
module Types::Enums
  class UserPrivacyType < Types::BaseEnum
    description "An enum describing the privacy level of a given user. Most users will be `PUBLIC_ACCOUNT`."

    value "PUBLIC_ACCOUNT", value: 'public_account', description: "User has a publicly-visible profile."
    value "PRIVATE_ACCOUNT", value: 'private_account', description: "User has a private profile."
  end
end
