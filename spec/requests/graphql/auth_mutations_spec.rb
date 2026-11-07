# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GraphQL Auth Mutations", type: :request do
  describe "signIn mutation" do
    let(:user) { create(:confirmed_user) }
    let(:query) do
      <<~GQL
        mutation SignIn($email: String!, $password: String!) {
          signIn(email: $email, password: $password) {
            token
            userId
            username
            slug
            role
            avatarUrl
            errors
          }
        }
      GQL
    end

    it "returns a JWT token for valid credentials", :aggregate_failures do
      post graphql_path, params: {
        query: query,
        variables: { email: user.email, password: "password" }.to_json
      }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      data = json.dig('data', 'signIn')
      expect(data['token']).to be_present
      expect(data['errors']).to be_empty
      expect(data['userId']).to eq(user.id.to_s)
      expect(data['username']).to eq(user.username)
      expect(data['slug']).to eq(user.slug)
      expect(data['avatarUrl']).to be_nil

      # Verify the token decodes to the correct user
      decoded = JwtService.decode(data['token'])
      expect(decoded.first['user_id']).to eq(user.id)
    end

    it "returns the small avatar URL for a user with an avatar" do
      user_with_avatar = create(:confirmed_user_with_avatar)
      post graphql_path, params: {
        query: query,
        variables: { email: user_with_avatar.email, password: "password" }.to_json
      }

      avatar_url = JSON.parse(response.body).dig('data', 'signIn', 'avatarUrl')
      expect(avatar_url).to be_present
    end

    it "returns a token that includes jwt_version and passes verification" do
      post graphql_path, params: {
        query: query,
        variables: { email: user.email, password: "password" }.to_json
      }

      json = JSON.parse(response.body)
      token = json.dig('data', 'signIn', 'token')
      decoded = JwtService.decode(token)
      expect(decoded.first['jwt_version']).to eq(user.jwt_version)
      expect(JwtService.decode_and_verify(token)).to eq(user)
    end

    it "returns a token that is rejected after revocation" do
      post graphql_path, params: {
        query: query,
        variables: { email: user.email, password: "password" }.to_json
      }

      token = JSON.parse(response.body).dig('data', 'signIn', 'token')
      JwtService.revoke_all!(user)
      expect(JwtService.decode_and_verify(token)).to be_nil
    end

    it "returns errors for invalid credentials" do
      post graphql_path, params: {
        query: query,
        variables: { email: user.email, password: "wrong" }.to_json
      }

      json = JSON.parse(response.body)
      data = json.dig('data', 'signIn')
      expect(data['token']).to be_nil
      expect(data['errors']).to include("Invalid email or password.")
    end

    it "returns errors for a banned user" do
      banned_user = create(:banned_user)
      post graphql_path, params: {
        query: query,
        variables: { email: banned_user.email, password: "password" }.to_json
      }

      json = JSON.parse(response.body)
      data = json.dig('data', 'signIn')
      expect(data['token']).to be_nil
      expect(data['errors']).to include("Your account has been banned.")
    end

    it "returns errors for an unconfirmed user" do
      unconfirmed_user = create(:user)
      post graphql_path, params: {
        query: query,
        variables: { email: unconfirmed_user.email, password: "password" }.to_json
      }

      json = JSON.parse(response.body)
      data = json.dig('data', 'signIn')
      expect(data['token']).to be_nil
      expect(data['errors']).to include("You must confirm your email address before signing in.")
    end
  end

  describe "signUp mutation" do
    let(:query) do
      <<~GQL
        mutation SignUp($username: String!, $email: String!, $password: String!, $passwordConfirmation: String!) {
          signUp(username: $username, email: $email, password: $password, passwordConfirmation: $passwordConfirmation) {
            message
            errors
          }
        }
      GQL
    end

    it "creates a new user", :aggregate_failures do
      post graphql_path, params: {
        query: query,
        variables: {
          username: "graphqluser",
          email: "graphqluser@example.com",
          password: "password123",
          passwordConfirmation: "password123"
        }.to_json
      }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      data = json.dig('data', 'signUp')
      expect(data['errors']).to be_empty
      expect(data['message']).to include("Account created successfully")
      expect(User.find_by(email: "graphqluser@example.com")).to be_present
    end

    it "returns errors for invalid input" do
      post graphql_path, params: {
        query: query,
        variables: {
          username: "",
          email: "invalid",
          password: "short",
          passwordConfirmation: "mismatch"
        }.to_json
      }

      json = JSON.parse(response.body)
      data = json.dig('data', 'signUp')
      expect(data['message']).to be_nil
      expect(data['errors']).not_to be_empty
    end

    context "when Turnstile is enabled" do
      let(:siteverify_url) { 'https://challenges.cloudflare.com/turnstile/v0/siteverify' }
      let(:turnstile_query) do
        <<~GQL
          mutation SignUp($username: String!, $email: String!, $password: String!, $passwordConfirmation: String!, $turnstileToken: String) {
            signUp(username: $username, email: $email, password: $password, passwordConfirmation: $passwordConfirmation, turnstileToken: $turnstileToken) {
              message
              errors
            }
          }
        GQL
      end
      let(:variables) do
        {
          username: "graphqluser",
          email: "graphqluser@example.com",
          password: "password123",
          passwordConfirmation: "password123"
        }
      end

      around(:each) do |example|
        with_environment('TURNSTILE_SECRET_KEY' => '1x0000000000000000000000000000000AA') { example.run }
      end

      it "creates the user when the token is valid, and passes the client IP to Cloudflare", :aggregate_failures do
        stub_request(:post, siteverify_url).to_return(body: { success: true }.to_json)

        post graphql_path,
          params: { query: turnstile_query, variables: variables.merge(turnstileToken: "XXXX.DUMMY.TOKEN.XXXX").to_json },
          env: { 'REMOTE_ADDR' => '203.0.113.7' }

        data = JSON.parse(response.body).dig('data', 'signUp')
        expect(data['errors']).to be_empty
        expect(User.find_by(email: "graphqluser@example.com")).to be_present
        expect(
          a_request(:post, siteverify_url).with(body: hash_including('response' => 'XXXX.DUMMY.TOKEN.XXXX', 'remoteip' => '203.0.113.7'))
        ).to have_been_made.once
      end

      it "rejects the sign-up without a token", :aggregate_failures do
        post graphql_path, params: { query: query, variables: variables.to_json }

        data = JSON.parse(response.body).dig('data', 'signUp')
        expect(data['message']).to be_nil
        expect(data['errors']).to eq([TurnstileVerifier::ERROR_MESSAGE])
        expect(User.find_by(email: "graphqluser@example.com")).to be_nil
      end

      it "rejects the sign-up when Cloudflare rejects the token", :aggregate_failures do
        stub_request(:post, siteverify_url).to_return(body: { success: false, 'error-codes' => ['timeout-or-duplicate'] }.to_json)

        post graphql_path, params: { query: turnstile_query, variables: variables.merge(turnstileToken: "used").to_json }

        data = JSON.parse(response.body).dig('data', 'signUp')
        expect(data['errors']).to eq([TurnstileVerifier::ERROR_MESSAGE])
        expect(User.find_by(email: "graphqluser@example.com")).to be_nil
      end
    end
  end

  describe "requestPasswordReset mutation" do
    let(:query) do
      <<~GQL
        mutation RequestPasswordReset($email: String!) {
          requestPasswordReset(email: $email) {
            message
          }
        }
      GQL
    end

    it "returns a success message for an existing email" do
      user = create(:confirmed_user)
      post graphql_path, params: {
        query: query,
        variables: { email: user.email }.to_json
      }

      json = JSON.parse(response.body)
      data = json.dig('data', 'requestPasswordReset')
      expect(data['message']).to include("password reset instructions have been sent")
    end

    it "returns the same message for a nonexistent email (anti-enumeration)" do
      post graphql_path, params: {
        query: query,
        variables: { email: "nonexistent@example.com" }.to_json
      }

      json = JSON.parse(response.body)
      data = json.dig('data', 'requestPasswordReset')
      expect(data['message']).to include("password reset instructions have been sent")
    end
  end
end
