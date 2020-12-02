# typed: strict
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

    stores = []
    rand(0..3).times.each do
      stores << Store.find(rand(1..Store.count))
    end
    stores.uniq!

    begin
      GamePurchase.create_with(
        platforms: platforms,
        stores: stores
      ).find_or_create_by!(
        game: game,
        user: user,
        rating: rand(0..100),
        completion_status: rand(0..5),
        start_date: Faker::Date.between(from: 1.month.ago.to_date, to: 1.day.ago.to_date),
        completion_date: Faker::Date.between(from: 1.month.ago.to_date, to: 1.day.ago.to_date),
        comments: Faker::Lorem.sentence
      )
    rescue ActiveRecord::RecordInvalid => e
      puts "Error: #{e}"
    end
  end
end
