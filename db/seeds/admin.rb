# typed: strict
puts "Creating admin..."

# Create an account for admin usage.
User.create_with(
  password: "password",
  role: :admin
).find_or_create_by!(
  email: "admin@example.com",
  username: "connor"
)

admin = User.find_by(email: "admin@example.com")

# Confirm the admin's email.
T.must(admin).confirm

# Exit early if there aren't at least 10 games in the db.
return if Game.count < 10

puts "Creating Game Purchases for admin..."

# Create 10 unique game purchases for the admin user.
(1..Game.count).to_a.sample(10).each do |game_id|
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

  GamePurchase.create_with(
    platforms: platforms,
    stores: stores
  ).find_or_create_by!(
    game: game,
    user: admin,
    rating: rand(0..100),
    completion_status: rand(0..5),
    start_date: Faker::Date.between(from: 1.month.ago.to_date, to: 1.day.ago.to_date),
    completion_date: Faker::Date.between(from: 1.month.ago.to_date, to: 1.day.ago.to_date),
    comments: Faker::Lorem.sentence,
    hours_played: rand(0..100),
    replay_count: rand(0..3)
  )
end
