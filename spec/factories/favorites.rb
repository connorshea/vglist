FactoryBot.define do
  factory :favorite do
    user

    association(:favoritable, factory: :game)
  end
end
