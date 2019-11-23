# typed: strict
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
require 'database_cleaner'
require 'open-uri'

puts "Cleaning out database..."

# Make sure the DB is cleaned before seeding.
DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean

seed_tasks = [
  'db:seed:users',
  'db:seed:genres',
  'db:seed:companies',
  'db:seed:engines',
  'db:seed:series',
  'db:seed:stores',
  'db:seed:games',
  'db:seed:platforms',
  'db:seed:game_purchases',
  'db:seed:admin'
]

seed_tasks.each do |task|
  Rake::Task[task].invoke
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
[User, Genre, Company, Engine, Series, Store, Game, Platform, GamePurchase, GameDeveloper, GamePublisher, GamePlatform].each do |class_name|
  puts "- #{class_name.count} #{class_name.to_s.titleize.pluralize}"
end
