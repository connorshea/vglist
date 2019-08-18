# typed: true
module ActivityFeedHelper
  def changed_completion_status?(event)
    event.event_type == 'change_completion_status' \
      && ['completed', 'fully_completed', 'dropped'].include?(event.differences['completion_status'][1])
  end

  def completion_status_event_text(event)
    after_value = event.differences['completion_status'][1]
    if after_value == 'completed'
      event_text = [
        link_to(event.user.username, user_path(event.user)),
        " completed ",
        link_to(event.game_purchase.game.name, game_path(event.game_purchase.game)),
        "."
      ]
      return event_text.inject(:+)
    elsif after_value == 'fully_completed'
      event_text = [
        link_to(event.user.username, user_path(event.user)),
        " 100% completed ",
        link_to(event.game_purchase.game.name, game_path(event.game_purchase.game)),
        "."
      ]
      return event_text.inject(:+)
    elsif after_value == 'dropped'
      event_text = [
        link_to(event.user.username, user_path(event.user)),
        " dropped ",
        link_to(event.game_purchase.game.name, game_path(event.game_purchase.game)),
        "."
      ]
      return event_text.inject(:+)
    end
  end
end
