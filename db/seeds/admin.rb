puts "Creating admin..."

# Create an account for admin usage.
User.create!(
  email: "admin@example.com",
  username: "connor",
  password: "password",
  role: :admin
)

admin = User.find_by(email: "admin@example.com")

# Confirm the admin's email.
admin.confirm

# Exit early if there aren't at least 10 games in the db.
return if Game.count < 10

puts "Creating Game Purchases for admin..."

# Create 10 unique game purchases for the admin user.
(1..Game.count).to_a.sample(10).each do |game_id|
  game = Game.find(game_id)

  GamePurchase.find_or_create_by!(
    game: game,
    user: admin,
    rating: rand(0..100),
    completion_status: rand(0..5),
    start_date: Faker::Date.between(1.month.ago, 1.day.ago),
    completion_date: Faker::Date.between(1.month.ago, 1.day.ago),
    comments: Faker::Lorem.sentence
  )
end
