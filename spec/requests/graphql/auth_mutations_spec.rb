require 'rails_helper'

RSpec.describe "GraphQL Auth Mutations", type: :request do
  describe "signIn mutation" do
    let(:user) { create(:confirmed_user) }
    let(:query) do
      <<~GQL
        mutation SignIn($email: String!, $password: String!) {
          signIn(email: $email, password: $password) {
            token
            errors
          }
        }
      GQL
    end

    it "returns a JWT token for valid credentials" do
      post graphql_path, params: {
        query: query,
        variables: { email: user.email, password: "password" }.to_json
      }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      data = json.dig('data', 'signIn')
      expect(data['token']).to be_present
      expect(data['errors']).to be_empty

      # Verify the token decodes to the correct user
      decoded = JwtService.decode(data['token'])
      expect(decoded.first['user_id']).to eq(user.id)
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
            errors
          }
        }
      GQL
    end

    it "creates a new user" do
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
      expect(data['errors']).not_to be_empty
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
