# typed: strict
module Types::Enums
  class UserAvatarSizeType < Types::BaseEnum
    description "The size of the user avatar."

    User::AVATAR_SIZES.each do |key, (width, height)|
      value key.to_s.upcase, value: key, description: "User avatar image with a width of #{width} and height of #{height}."
    end
  end
end
