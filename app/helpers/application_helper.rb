module ApplicationHelper
  def flash_class(level)
    case level.to_sym
    when :notice then "is-info"
    when :success then "is-success"
    when :error then "is-danger"
    when :alert then "is-warning"
    end
  end

  # A helper for displaying user avatars.
  def user_avatar(user_id, size)
    user = User.find(user_id)
    if user.avatar.attached?
      image_tag user.avatar.variant(resize: "#{size}x#{size}")
    else
      image_tag 'default-avatar.png', height: "#{size}px", width: "#{size}px"
    end
  end
end
