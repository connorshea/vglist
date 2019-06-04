puts "Creating Game Purchases..."

# Add 3 game to each user's libraries.
(1..User.count).each do |index|
  # Skip occasionally to allow the database to be seeded with users that have
  # empty libraries.
  next if rand(3) == 1

  user = User.find(index)

  # Choose 3 unique random game IDs and add each to the user's library.
  (1..Game.count).to_a.sample(3).each do |game_id|
    game = Game.find(game_id)

    platforms = []
    rand(0..3).times.each do
      platforms << Platform.find(rand(1..Platform.count))
    end
    platforms.uniq!

    begin
      GamePurchase.find_or_create_by!(
        game: game,
        user: user,
        rating: rand(0..100),
        completion_status: rand(0..5),
        start_date: Faker::Date.between(1.month.ago, 1.day.ago),
        completion_date: Faker::Date.between(1.month.ago, 1.day.ago),
        comments: Faker::Lorem.sentence,
        platforms: platforms
      )
    rescue ActiveRecord::RecordInvalid => e
      puts "Error: #{e}"
    end
  end
end
