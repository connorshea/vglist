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

# Create 50 more random users.
50.times do
  User.create!(
    email: Faker::Internet.unique.email,
    # Usernames must be between (inclusive) 4 and 20 characters.
    username: Faker::Internet.unique.username(4..20),

    # Passwords can be up to 128 characters, but we'll just do up to 20 here.
    password: Faker::Internet.password(8, 20)
  )
end

puts "Creating Games..."

# Create 50 random Games.
50.times do
  Game.create!(
    name: Faker::Game.name,
    description: Faker::Lorem.sentence
  )
end

puts "Created #{User.count} users and #{Game.count} games."
