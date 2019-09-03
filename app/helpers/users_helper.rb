# typed: strict
module UsersHelper
  extend T::Sig

  # Checks if the current user is already following the other user.
  sig { params(user: User).returns(T::Boolean) }
  def current_user_following?(user)
    current_user.following.find_by(id: user.id).present?
  end
end
