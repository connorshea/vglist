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
      # Resize the image, center it, and then crop it to a square.
      # This prevents users from having images that aren't either
      # too wide or too tall.
      image_tag user.avatar.variant(
        combine_options: {
          resize: "#{size}x#{size}^",
          gravity: 'Center',
          crop: "#{size}x#{size}+0+0"
        }
      ),
      height: "#{size}px",
      width: "#{size}px"
    else
      image_tag 'default-avatar.png', height: "#{size}px", width: "#{size}px"
    end
  end

  # A helper for displaying game covers.
  def game_cover(game, width, height)
    if game.cover.attached?
      image_tag game.cover.variant(
        resize: "#{width}x#{height}>"
      ),
      width: "#{width}px",
      height: "#{height}px"
    else
      image_tag 'no-cover.png', width: "#{width}px", height: "#{height}px"
    end
  end
end
