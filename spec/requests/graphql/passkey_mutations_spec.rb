# frozen_string_literal: true

require 'rails_helper'
require 'webauthn/fake_client'

RSpec.describe "GraphQL passkey mutations", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:confirmed_user) }
  let(:origin) { WebAuthn.configuration.allowed_origins.first }
  let(:client) { WebAuthn::FakeClient.new(origin) }

  let(:registration_options_query) do
    <<~GQL
      mutation PasskeyRegistrationOptions {
        passkeyRegistrationOptions { options errors }
      }
    GQL
  end

  let(:register_query) do
    <<~GQL
      mutation RegisterPasskey($response: JSON!, $nickname: String) {
        registerPasskey(response: $response, nickname: $nickname) {
          passkey { id nickname backedUp lastUsedAt createdAt }
          errors
        }
      }
    GQL
  end

  let(:authentication_options_query) do
    <<~GQL
      mutation PasskeyAuthenticationOptions {
        passkeyAuthenticationOptions { options }
      }
    GQL
  end

  let(:sign_in_query) do
    <<~GQL
      mutation SignInWithPasskey($response: JSON!) {
        signInWithPasskey(response: $response) {
          token userId username slug role email avatarUrl errors
        }
      }
    GQL
  end

  def auth_headers(for_user)
    { 'Authorization' => "Bearer #{JwtService.encode(for_user)}" }
  end

  # Post JSON like the SPA does, so variables arrive as
  # ActionController::Parameters rather than a parsed string.
  def graphql(query, variables: {}, headers: {})
    post graphql_path,
      params: { query: query, variables: variables }.to_json,
      headers: headers.merge('Content-Type' => 'application/json')
    JSON.parse(response.body)
  end

  def registration_options(for_user = user)
    graphql(registration_options_query, headers: auth_headers(for_user)).dig('data', 'passkeyRegistrationOptions')
  end

  def register(for_user = user, with_client: client, nickname: 'MacBook Pro', **create_options)
    challenge = registration_options(for_user).dig('options', 'challenge')
    credential = with_client.create(challenge: challenge, user_verified: true, **create_options)
    graphql(register_query, variables: { response: credential, nickname: nickname }, headers: auth_headers(for_user))
      .dig('data', 'registerPasskey')
  end

  def authentication_challenge
    graphql(authentication_options_query).dig('data', 'passkeyAuthenticationOptions', 'options', 'challenge')
  end

  def assertion(for_user = user, with_client: client, challenge: authentication_challenge, **get_options)
    with_client.get(
      challenge: challenge,
      user_verified: true,
      user_handle: WebAuthn.standard_encoder.decode(for_user.reload.webauthn_id),
      **get_options
    )
  end

  def sign_in_with(credential)
    graphql(sign_in_query, variables: { response: credential }).dig('data', 'signInWithPasskey')
  end

  describe "passkeyRegistrationOptions" do
    it "returns creation options for discoverable, user-verified passkeys", :aggregate_failures do
      result = registration_options
      options = result['options']

      expect(result['errors']).to be_empty
      expect(options['challenge']).to be_present
      expect(options['rp']).to eq('name' => 'vglist', 'id' => WebAuthn.configuration.rp_id)
      expect(options['user']).to include('name' => user.email, 'displayName' => user.username, 'id' => user.reload.webauthn_id)
      expect(options['authenticatorSelection']).to include('residentKey' => 'required', 'userVerification' => 'required')
      expect(WebauthnChallenge.registration.where(user: user).count).to eq(1)
    end

    it "uses a random user handle rather than the user's ID", :aggregate_failures do
      handle = registration_options.dig('options', 'user', 'id')
      expect(handle).not_to eq(user.id.to_s)
      expect(registration_options.dig('options', 'user', 'id')).to eq(handle)
    end

    it "excludes passkeys the user already has" do
      register
      excluded = registration_options.dig('options', 'excludeCredentials').pluck('id')
      expect(excluded).to eq(user.webauthn_credentials.pluck(:external_id))
    end

    it "requires a confirmed email", :aggregate_failures do
      unconfirmed = create(:user)
      result = registration_options(unconfirmed)
      expect(result['options']).to be_nil
      expect(result['errors']).to eq(["Confirm your email address before adding a passkey."])
    end

    it "refuses once the user has the maximum number of passkeys" do
      create_list(:webauthn_credential, WebauthnCredential::MAX_PER_USER, user: user)
      expect(registration_options['errors'].first).to include("more than #{WebauthnCredential::MAX_PER_USER}")
    end

    it "requires a signed-in user" do
      json = graphql(registration_options_query)
      expect(json['errors'].first['message']).to include("logged in")
    end
  end

  describe "registerPasskey" do
    it "stores the passkey", :aggregate_failures do
      result = register(backup_eligibility: true, backup_state: true)

      expect(result['errors']).to be_empty
      expect(result['passkey']).to include('nickname' => 'MacBook Pro', 'backedUp' => true, 'lastUsedAt' => nil)
      passkey = user.webauthn_credentials.sole
      expect(passkey.public_key).to be_present
      expect(passkey.backed_up).to be(true)
    end

    it "emails the user about the new passkey" do
      expect { register }.to have_enqueued_mail(PasskeyMailer, :passkey_added)
    end

    it "doesn't email the user when the passkey is rejected" do
      evil_client = WebAuthn::FakeClient.new('https://evil.example')
      expect { register(with_client: evil_client) }.not_to have_enqueued_mail(PasskeyMailer, :passkey_added)
    end

    it "defaults the nickname" do
      expect(register(nickname: nil).dig('passkey', 'nickname')).to eq('Unnamed passkey')
    end

    it "rejects a response from another origin", :aggregate_failures do
      evil_client = WebAuthn::FakeClient.new('https://evil.example')
      result = register(with_client: evil_client)
      expect(result['passkey']).to be_nil
      expect(result['errors']).to eq(["That passkey couldn't be verified."])
    end

    it "rejects a passkey created without user verification" do
      challenge = registration_options.dig('options', 'challenge')
      credential = client.create(challenge: challenge, user_verified: false)
      result = graphql(register_query, variables: { response: credential }, headers: auth_headers(user)).dig('data', 'registerPasskey')
      expect(result['errors']).to eq(["That passkey couldn't be verified."])
    end

    it "rejects an expired challenge" do
      challenge = registration_options.dig('options', 'challenge')
      credential = client.create(challenge: challenge, user_verified: true)

      travel(WebauthnChallenge::TTL + 1.second) do
        result = graphql(register_query, variables: { response: credential }, headers: auth_headers(user)).dig('data', 'registerPasskey')
        expect(result['errors'].first).to include("expired")
      end
    end

    it "rejects a reused challenge", :aggregate_failures do
      challenge = registration_options.dig('options', 'challenge')
      credential = client.create(challenge: challenge, user_verified: true)
      graphql(register_query, variables: { response: credential }, headers: auth_headers(user))

      result = graphql(register_query, variables: { response: credential }, headers: auth_headers(user)).dig('data', 'registerPasskey')
      expect(result['errors'].first).to include("already used")
      expect(user.webauthn_credentials.count).to eq(1)
    end

    it "rejects a challenge issued to another user" do
      other = create(:confirmed_user)
      challenge = registration_options(other).dig('options', 'challenge')
      credential = client.create(challenge: challenge, user_verified: true)

      result = graphql(register_query, variables: { response: credential }, headers: auth_headers(user)).dig('data', 'registerPasskey')
      expect(result['errors'].first).to include("expired")
    end

    it "rejects an authentication challenge" do
      credential = client.create(challenge: authentication_challenge, user_verified: true)
      result = graphql(register_query, variables: { response: credential }, headers: auth_headers(user)).dig('data', 'registerPasskey')
      expect(result['errors'].first).to include("expired")
    end

    it "rejects a malformed response" do
      result = graphql(register_query, variables: { response: { id: 'nope' } }, headers: auth_headers(user)).dig('data', 'registerPasskey')
      expect(result['errors']).to eq(["The passkey response is malformed."])
    end

    it "rejects a passkey that's already registered", :aggregate_failures do
      challenge = registration_options.dig('options', 'challenge')
      credential = client.create(challenge: challenge, user_verified: true)
      create(:webauthn_credential, external_id: credential['id'])

      result = graphql(register_query, variables: { response: credential }, headers: auth_headers(user)).dig('data', 'registerPasskey')
      expect(result['errors']).to eq(["This passkey is already registered."])
      expect(user.webauthn_credentials.count).to eq(0)
    end

    it "requires a signed-in user" do
      json = graphql(register_query, variables: { response: {} })
      expect(json['errors'].first['message']).to include("logged in")
    end
  end

  describe "passkeyAuthenticationOptions" do
    it "returns request options with no allow list", :aggregate_failures do
      options = graphql(authentication_options_query).dig('data', 'passkeyAuthenticationOptions', 'options')

      expect(options['challenge']).to be_present
      expect(options['rpId']).to eq(WebAuthn.configuration.rp_id)
      expect(options['userVerification']).to eq('required')
      expect(options['allowCredentials']).to eq([])
      expect(WebauthnChallenge.authentication.count).to eq(1)
    end
  end

  describe "signInWithPasskey" do
    before(:each) { register }

    it "signs the user in", :aggregate_failures do
      result = sign_in_with(assertion)

      expect(result['errors']).to be_empty
      expect(result).to include('userId' => user.id.to_s, 'username' => user.username, 'slug' => user.slug, 'email' => user.email)
      expect(JwtService.decode_and_verify(result['token'])).to eq(user)
      expect(user.webauthn_credentials.sole.last_used_at).to be_present
    end

    it "updates the sign count" do
      sign_in_with(assertion(sign_count: 5))
      expect(user.webauthn_credentials.sole.sign_count).to eq(5)
    end

    it "rejects a sign count that went backwards (possible cloned authenticator)", :aggregate_failures do
      sign_in_with(assertion(sign_count: 5))
      result = sign_in_with(assertion(sign_count: 3))

      expect(result['token']).to be_nil
      expect(result['errors']).to eq(["That passkey couldn't be verified."])
    end

    it "rejects a response from another origin", :aggregate_failures do
      evil_client = WebAuthn::FakeClient.new('https://evil.example', authenticator: client.send(:authenticator))
      result = sign_in_with(assertion(with_client: evil_client, rp_id: WebAuthn.configuration.rp_id))

      expect(result['token']).to be_nil
      expect(result['errors']).to eq(["That passkey couldn't be verified."])
    end

    it "rejects an assertion without user verification" do
      result = sign_in_with(assertion(user_verified: false))
      expect(result['errors']).to eq(["That passkey couldn't be verified."])
    end

    it "rejects a reused challenge", :aggregate_failures do
      credential = assertion
      sign_in_with(credential)
      result = sign_in_with(credential)

      expect(result['token']).to be_nil
      expect(result['errors'].first).to include("already used")
    end

    it "rejects an expired challenge" do
      credential = assertion
      travel(WebauthnChallenge::TTL + 1.second) do
        expect(sign_in_with(credential)['errors'].first).to include("expired")
      end
    end

    it "rejects a registration challenge" do
      challenge = registration_options.dig('options', 'challenge')
      result = sign_in_with(assertion(challenge: challenge))
      expect(result['errors'].first).to include("expired")
    end

    it "rejects a challenge the server never issued" do
      fake_challenge = WebAuthn.standard_encoder.encode(SecureRandom.random_bytes(32))
      result = sign_in_with(assertion(challenge: fake_challenge))
      expect(result['errors'].first).to include("expired")
    end

    it "rejects an unknown passkey", :aggregate_failures do
      stranger = WebAuthn::FakeClient.new(origin)
      stranger.create(challenge: WebAuthn.standard_encoder.encode(SecureRandom.random_bytes(32)), user_verified: true)
      result = sign_in_with(assertion(with_client: stranger))

      expect(result['token']).to be_nil
      expect(result['errors']).to eq(["That passkey isn't linked to a vglist account."])
    end

    it "rejects a user handle that doesn't match the passkey's owner" do
      other = create(:confirmed_user)
      other.webauthn_id!
      result = sign_in_with(assertion(other))
      expect(result['errors']).to eq(["That passkey isn't linked to a vglist account."])
    end

    it "rejects a removed passkey" do
      user.webauthn_credentials.destroy_all
      expect(sign_in_with(assertion)['errors']).to eq(["That passkey isn't linked to a vglist account."])
    end

    it "rejects a banned user", :aggregate_failures do
      user.update!(banned: true)
      result = sign_in_with(assertion)

      expect(result['token']).to be_nil
      expect(result['errors']).to eq(["Your account has been banned."])
    end

    it "rejects an unconfirmed user", :aggregate_failures do
      user.update!(confirmed_at: nil)
      result = sign_in_with(assertion)

      expect(result['token']).to be_nil
      expect(result['errors']).to eq(["You must confirm your email address before signing in."])
    end

    it "rejects a malformed response" do
      result = sign_in_with({ 'response' => { 'clientDataJSON' => 'garbage' } })
      expect(result['errors']).to eq(["The passkey response is malformed."])
    end
  end

  describe "renamePasskey" do
    let(:passkey) { create(:webauthn_credential, user: user) }
    let(:query) do
      <<~GQL
        mutation RenamePasskey($id: ID!, $nickname: String!) {
          renamePasskey(id: $id, nickname: $nickname) { passkey { id nickname } errors }
        }
      GQL
    end

    it "renames the passkey", :aggregate_failures do
      result = graphql(query, variables: { id: passkey.id, nickname: 'Work laptop' }, headers: auth_headers(user))
      expect(result.dig('data', 'renamePasskey', 'passkey', 'nickname')).to eq('Work laptop')
      expect(passkey.reload.nickname).to eq('Work laptop')
    end

    it "rejects a nickname that's too long" do
      result = graphql(query, variables: { id: passkey.id, nickname: 'a' * 61 }, headers: auth_headers(user))
      expect(result.dig('data', 'renamePasskey', 'errors')).to eq(["Nickname is too long (maximum is 60 characters)"])
    end

    it "can't rename another user's passkey", :aggregate_failures do
      result = graphql(query, variables: { id: passkey.id, nickname: 'Mine now' }, headers: auth_headers(create(:confirmed_user)))
      expect(result['errors'].first['message']).to eq("Passkey not found.")
      expect(passkey.reload.nickname).to eq('MacBook Pro')
    end
  end

  describe "deletePasskey" do
    let!(:passkey) { create(:webauthn_credential, user: user) }
    let(:query) do
      <<~GQL
        mutation DeletePasskey($id: ID!) {
          deletePasskey(id: $id) { deleted }
        }
      GQL
    end

    it "deletes the passkey" do
      expect do
        graphql(query, variables: { id: passkey.id }, headers: auth_headers(user))
      end.to change(WebauthnCredential, :count).by(-1)
    end

    it "leaves the user's other passkeys and password alone", :aggregate_failures do
      other_passkey = create(:webauthn_credential, user: user)
      graphql(query, variables: { id: passkey.id }, headers: auth_headers(user))

      expect(WebauthnCredential.exists?(other_passkey.id)).to be(true)
      expect(user.reload.valid_password?('password')).to be(true)
    end

    it "can't delete another user's passkey", :aggregate_failures do
      result = graphql(query, variables: { id: passkey.id }, headers: auth_headers(create(:confirmed_user)))
      expect(result['errors'].first['message']).to eq("Passkey not found.")
      expect(WebauthnCredential.exists?(passkey.id)).to be(true)
    end

    it "requires a signed-in user" do
      result = graphql(query, variables: { id: passkey.id })
      expect(result['errors'].first['message']).to include("logged in")
    end
  end

  describe "User.passkeys" do
    let(:query) do
      <<~GQL
        query User($id: ID!) {
          user(id: $id) { passkeys { id nickname } }
        }
      GQL
    end

    it "lists the user's own passkeys, newest first" do
      older = create(:webauthn_credential, user: user, created_at: 2.days.ago)
      newer = create(:webauthn_credential, user: user, created_at: 1.day.ago)

      result = graphql(query, variables: { id: user.id }, headers: auth_headers(user))
      expect(result.dig('data', 'user', 'passkeys').pluck('id')).to eq([newer.id.to_s, older.id.to_s])
    end

    it "is null for other users" do
      create(:webauthn_credential, user: user)
      result = graphql(query, variables: { id: user.id }, headers: auth_headers(create(:confirmed_user)))
      expect(result.dig('data', 'user', 'passkeys')).to be_nil
    end

    it "is null for anonymous visitors" do
      result = graphql(query, variables: { id: user.id })
      expect(result.dig('data', 'user', 'passkeys')).to be_nil
    end
  end
end
