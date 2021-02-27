# typed: strict
# rubocop:disable Style/StringConcatenation
module ActivityHelper
  extend T::Sig

  sig { params(event: Event).returns(String) }
  def event_text(event)
    case event.event_category.to_sym
    when :add_to_library
      add_to_library_event_text(event)
    when :change_completion_status
      completion_status_event_text(event)
    when :favorite_game
      favorite_game_event_text(event)
    when :new_user
      new_user_event_text(event)
    when :following
      following_event_text(event)
    else
      ''
    end
  end

  sig { params(event: Event).returns(String) }
  def completion_status_event_text(event)
    # Coerce the value to a hash since we know it will always be one
    after_value = T.cast(event.differences, T::Hash[String, T.untyped])['completion_status'][1].to_sym
    user_link = link_to(event.user.username, user_path(event.user))
    game_link = link_to(event.eventable.game.name, game_path(event.eventable.game))

    case after_value
    when :completed
      text = user_link + " completed " + game_link + "."
    when :fully_completed
      text = user_link + " 100% completed " + game_link + "."
    when :dropped
      text = user_link + " dropped " + game_link + "."
    when :paused
      text = user_link + " paused " + game_link + "."
    end

    return text
  end

  sig { params(event: Event).returns(String) }
  def add_to_library_event_text(event)
    user_link = link_to(event.user.username, user_path(event.user))
    game_link = link_to(event.eventable.game.name, game_path(event.eventable.game))

    return user_link + " added " + game_link + " to their library."
  end

  sig { params(event: Event).returns(String) }
  def favorite_game_event_text(event)
    user_link = link_to(event.user.username, user_path(event.user))
    game_link = link_to(event.eventable.game.name, game_path(event.eventable.game))

    return user_link + " favorited " + game_link + "."
  end

  sig { params(event: Event).returns(String) }
  def new_user_event_text(event)
    user_link = link_to(event.user.username, user_path(event.user))

    return user_link + " created their account."
  end

  sig { params(event: Event).returns(String) }
  def following_event_text(event)
    follower_user_link = link_to(event.user.username, user_path(event.user))
    followed_user_link = link_to(event.eventable.followed.username, user_path(event.eventable.followed))

    return follower_user_link + " started following " + followed_user_link + "."
  end

  sig { params(event: Event).returns(T::Boolean) }
  def handleable_event?(event)
    case event.event_category.to_sym
    when :change_completion_status
      ['completed', 'fully_completed', 'dropped', 'paused'].include?(
        # Coerce the value to a hash since we know it will always be one
        T.cast(event.differences, T::Hash[String, T.untyped])['completion_status'][1]
      )
    when :add_to_library, :favorite_game, :new_user, :following
      true
    else
      false
    end
  end
end
# rubocop:enable Style/StringConcatenation
