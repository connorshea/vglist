module UsersHelper
  # Checks if the current user is already following the other user.
  def current_user_following?(user)
    current_user&.following&.find_by(id: user.id).present?
  end
end
