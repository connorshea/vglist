# frozen_string_literal: true

FactoryBot.define do
  factory :webauthn_credential do
    user
    sequence(:external_id) { |n| "credential-#{n}" }
    public_key { "public-key" }
    sign_count { 0 }
    nickname { "MacBook Pro" }
  end
end
