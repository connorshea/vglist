# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
require 'database_cleaner'
require 'open-uri'

# Fetches an avatar image from Faker, or uses an image from the test suite
# if in CI, to avoid external HTTP requests.
def avatar_fetcher
  if ENV['CI']
    File.open('./spec/factories/images/avatar.jpg')
  else
    URI.open(Faker::Avatar.image)
  end
end

# Fetches a cover image from LoremPixel, or uses an image from the test suite
# if in CI, to avoid external HTTP requests.
def cover_fetcher
  if ENV['CI']
    File.open('./spec/factories/images/crysis.jpg')
  else
    # TODO: Make the dimensions more random.
    URI.open("#{Faker::LoremPixel.image('560x800', false)}/")
  end
end

puts "Cleaning out database..."

# Make sure the DB is cleaned before seeding.
DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean

puts "Creating Users..."

# Create an account for admin usage.
User.create!(
  email: "admin@example.com",
  username: "connor",
  password: "password",
  role: :admin
)

# Confirm the admin's email.
User.find(1).confirm

# Create 30 more random users.
30.times do |n|
  user = User.create!(
    email: Faker::Internet.unique.email,
    # Usernames must be between (inclusive) 4 and 20 characters.
    username: Faker::Internet.unique.username(4..20),
    # Passwords can be up to 128 characters, but we'll just do up to 20 here.
    password: Faker::Internet.password(8, 20),
    bio: Faker::Lorem.sentence
  )

  # Only attach an avatar for some of the users.
  next unless rand(0..2) > 1

  user.avatar.attach(
    io: avatar_fetcher,
    filename: "#{n}_faker_avatar.jpg"
  )
end

# Create 5 moderators.
5.times do
  User.create!(
    email: Faker::Internet.unique.email,
    # Usernames must be between (inclusive) 4 and 20 characters.
    username: Faker::Internet.unique.username(4..20),
    # Passwords can be up to 128 characters, but we'll just do up to 20 here.
    password: Faker::Internet.password(8, 20),
    bio: Faker::Lorem.sentence,
    role: :moderator
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

puts "Creating Engines..."

10.times do
  Engine.create!(name: Faker::Game.unique.engine)
end

puts "Creating Series..."

# Create 20 Series.
20.times do
  Series.create!(
    name: Faker::Game.unique.series
  )
end

puts "Creating Games..."

# Create 50 random Games.
50.times do |n|
  genres = []
  rand(0..3).times.each do
    genres << Genre.find(rand(1..Genre.count))
  end
  genres.uniq!

  engines = []
  rand(0..3).times.each do
    engines << Engine.find(rand(1..Engine.count))
  end
  engines.uniq!

  game = Game.create!(
    name: Faker::Game.unique.name,
    description: Faker::Lorem.sentence,
    genres: genres,
    engines: engines,
    series: Series.find(rand(1..Series.count))
  )

  next unless rand(0..4) != 0

  # Add a cover for most games.
  game.cover.attach(
    io: cover_fetcher,
    filename: "#{n}_faker_cover.jpg"
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

puts "Creating Game Purchases..."

# Create 10 unique game purchases for the admin user.
admin = User.find(1)
(1..Game.count).to_a.sample(10).each do |game_id|
  game = Game.find(game_id)

  GamePurchase.find_or_create_by!(
    game: game,
    user: admin,
    score: rand(0..100),
    comments: Faker::Lorem.sentence
  )
end

# Add 3 game to each user's libraries.
(1..User.count).each do |index|
  # Skip for admin and skip occasionally to allow the database to be seeded
  # with users that have empty libraries.
  next if index == 1 || rand(3) == 1

  user = User.find(index)

  # Choose 3 unique random game IDs and add each to the user's library.
  (1..Game.count).to_a.sample(3).each do |game_id|
    game = Game.find(game_id)

    GamePurchase.find_or_create_by!(
      game: game,
      user: user,
      score: rand(0..100),
      comments: Faker::Lorem.sentence
    )
  end
end

puts "Creating Game Developers..."

20.times do
  game = Game.find(rand(1..Game.count))
  developer = Company.find(rand(1..Company.count))

  GameDeveloper.find_or_create_by!(
    game: game,
    company: developer
  )
end

puts "Creating Game Publishers..."

20.times do
  game = Game.find(rand(1..Game.count))
  publisher = Company.find(rand(1..Company.count))

  GamePublisher.find_or_create_by!(
    game: game,
    company: publisher
  )
end

puts "Creating Game Platforms..."

20.times do
  game = Game.find(rand(1..Game.count))
  platform = Platform.find(rand(1..Platform.count))

  GamePlatform.find_or_create_by!(
    game: game,
    platform: platform
  )
end

puts
puts "Created:"

# Don't forget to also update faker.rb when you add new Faker data, idiot.
[User, Genre, Company, Engine, Series, Game, Platform, GamePurchase, GameDeveloper, GamePublisher, GamePlatform].each do |class_name|
  puts "- #{class_name.count} #{class_name.to_s.titleize.pluralize}"
end
