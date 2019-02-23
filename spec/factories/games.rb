FactoryBot.define do
  factory :game do
    name { "Half-Life 2" }
    description { "A 2004 first-person shooter video game created by Valve." }

    factory :game_with_cover do
      after(:build) do |game|
        game.cover.attach(io: File.open(Rails.root.join('spec', 'factories', 'images', 'crysis.jpg')), filename: 'crysis.jpg', content_type: 'image/jpg')
      end
    end
  end
end
