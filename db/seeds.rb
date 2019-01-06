# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
require 'database_cleaner'

puts "Cleaning out database..."

# Make sure the DB is cleaned before seeding.
DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean

puts "Creating Users..."

# Create an account for admin usage.
User.create!(
  email: "admin@example.com",
  username: "admin",
  password: "password"
)

# Confirm the admin's email.
User.find(1).confirm

# Create 30 more random users.
30.times do
  User.create!(
    email: Faker::Internet.unique.email,
    # Usernames must be between (inclusive) 4 and 20 characters.
    username: Faker::Internet.unique.username(4..20),

    # Passwords can be up to 128 characters, but we'll just do up to 20 here.
    password: Faker::Internet.password(8, 20)
  )
end

puts "Creating Genres..."

# Create 20 unique genres.
20.times do
  Genre.create!(
    name: Faker::Game.unique.genre,
    description: Faker::Lorem.sentence
  )
end

puts "Creating Companies..."

20.times do
  Company.create!(
    name: Faker::Game.unique.company,
    description: Faker::Lorem.sentence
  )
end

puts "Creating Games..."

# Create 50 random Games.
50.times do
  Game.create!(
    name: Faker::Game.unique.name,
    description: Faker::Lorem.sentence
  )
end

puts "Creating Platforms..."

# Create 20 Platforms.
20.times do
  Platform.create!(
    name: Faker::Game.unique.platform,
    description: Faker::Lorem.sentence
  )
end

puts "Creating Releases..."

# Create 25 Releases.
25.times do
  game_id = rand(1..Game.count)
  game = Game.find(game_id)
  platform_id = rand(1..Platform.count)
  platform = Platform.find(platform_id)

  Release.create!(
    name: "#{game.name} for #{platform.name}",
    description: Faker::Lorem.sentence,
    game: game,
    platform: platform
  )
end

puts "Creating Release Purchases..."

# Create 10 unique release purchases for the admin user.
admin = User.find(1)
(1..Release.count).to_a.sample(10).each do |release_id|
  release = Release.find(release_id)

  ReleasePurchase.create!(
    release: release,
    user: admin
  )
end

# Add 3 releases to each user's libraries.
(1..User.count).each do |index|
  # Skip for admin and skip occasionally to allow the database to be seeded
  # with users that have empty libraries.
  next if index == 1 || rand(3) == 1

  user = User.find(index)

  # Choose 3 unique random release IDs and add each to the user's library.
  (1..Release.count).to_a.sample(3).each do |release_id|
    release = Release.find(release_id)

    ReleasePurchase.create!(
      release: release,
      user: user
    )
  end
end

puts
puts "Created:"

[User, Genre, Company, Game, Platform, Release, ReleasePurchase].each do |class_name|
  puts "- #{class_name.count} #{class_name.to_s.titleize.pluralize}"
end
