FactoryBot.define do
  factory :user do
    email { "johndoe@example.com" }
    password { "password" }
    username { "johndoe" }
    bio { "My name is John Doe and I love video games." }
  end
end
