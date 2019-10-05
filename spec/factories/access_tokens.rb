# typed: false
FactoryBot.define do
  factory :access_token, class: 'Doorkeeper::AccessToken' do
    application
    expires_in { 2.hours }
    scopes { 'read write' }

    # Bit of a hack to make the resource_owner relationship work.
    transient do
      resource_owner { create :user }
    end
    resource_owner_id { resource_owner.id }
  end
end
