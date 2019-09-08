namespace :helpers do
  desc "Creates User Creation Events for users that do not have them."
  task make_user_creation_events: :environment do
    events = Event.where(eventable_type: 'User')
    user_ids_with_events = events.map { |event| event.user_id }

    all_user_ids = User.all.map { |u| u.id }
    user_ids_without_events = all_user_ids.difference(user_ids_with_events)

    user_ids_without_events.each do |user_id|
      user = User.find(user_id)
      Event.create!(
        eventable_type: 'User',
        event_category: :new_user,
        eventable_id: user.id,
        user_id: user.id,
        created_at: user.created_at,
        updated_at: user.created_at
      )
    end
  end

  desc "Makes every user follow the user with ID 1."
  task make_users_follow_admin: :environment do
    first_user = User.find(1)
    users_already_following = first_user.passive_relationships.map { |rel| rel.follower_id }
    all_user_ids = User.all.map { |u| u.id }
    all_user_ids.reject! { |uid| uid == 1 }
    user_ids_not_following = all_user_ids.difference(users_already_following)

    user_ids_not_following.each do |user_id|
      Relationship.create!(
        follower_id: user_id,
        followed_id: 1
      )
    end
  end
end
