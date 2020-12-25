FactoryBot.define do
  factory :relationship do
    association :follower, factory: :user
    association :followed, factory: :user
  end
end
