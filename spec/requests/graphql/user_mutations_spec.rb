require 'rails_helper'

RSpec.describe "GraphQL User Mutations", type: :request do
  let(:user) { create(:confirmed_user) }
  let(:jwt_token) { JwtService.encode(user) }
  let(:auth_headers) { { 'Authorization': "Bearer #{jwt_token}" } }

  describe "updateUser mutation" do
    let(:query) do
      <<~GQL
        mutation UpdateUser($bio: String) {
          updateUser(bio: $bio) {
            user { id bio }
            errors
          }
        }
      GQL
    end

    it "updates the user's bio", :aggregate_failures do
      post graphql_path, params: {
        query: query,
        variables: { bio: "Updated bio!" }.to_json
      }, headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      data = json.dig('data', 'updateUser')
      expect(data['errors']).to be_empty
      expect(data['user']['bio']).to eq("Updated bio!")
      expect(user.reload.bio).to eq("Updated bio!")
    end

    it "returns an error when not authenticated" do
      post graphql_path, params: {
        query: query,
        variables: { bio: "New bio" }.to_json
      }

      json = JSON.parse(response.body)
      expect(json['errors'].first['message']).to include("logged in")
    end
  end

  describe "resetApiToken mutation" do
    let(:query) do
      <<~GQL
        mutation ResetApiToken {
          resetApiToken {
            apiToken
            errors
          }
        }
      GQL
    end

    it "generates a new API token", :aggregate_failures do
      post graphql_path, params: { query: query }, headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      data = json.dig('data', 'resetApiToken')
      expect(data['errors']).to be_empty
      expect(data['apiToken']).to be_present
      expect(data['apiToken'].length).to eq(40)
    end

    it "returns an error when not authenticated" do
      post graphql_path, params: { query: query }

      json = JSON.parse(response.body)
      expect(json['errors'].first['message']).to include("logged in")
    end
  end

  describe "updateEmail mutation" do
    let(:query) do
      <<~GQL
        mutation UpdateEmail($newEmail: String!, $currentPassword: String!) {
          updateEmail(newEmail: $newEmail, currentPassword: $currentPassword) {
            user { id }
            errors
          }
        }
      GQL
    end

    it "sets the unconfirmed email with correct password", :aggregate_failures do
      post graphql_path, params: {
        query: query,
        variables: { newEmail: "newemail@example.com", currentPassword: "password" }.to_json
      }, headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      data = json.dig('data', 'updateEmail')
      expect(data['errors']).to be_empty
      expect(data['user']).to be_present
      # Devise reconfirmable stores new email in unconfirmed_email until confirmed
      expect(user.reload.unconfirmed_email).to eq("newemail@example.com")
    end

    it "returns an error when current password is incorrect" do
      post graphql_path, params: {
        query: query,
        variables: { newEmail: "newemail@example.com", currentPassword: "wrongpassword" }.to_json
      }, headers: auth_headers

      json = JSON.parse(response.body)
      data = json.dig('data', 'updateEmail')
      expect(data['user']).to be_nil
      expect(data['errors']).to include("Current password is incorrect.")
    end

    it "returns an error when email is already taken" do
      create(:confirmed_user, email: "taken@example.com")

      post graphql_path, params: {
        query: query,
        variables: { newEmail: "taken@example.com", currentPassword: "password" }.to_json
      }, headers: auth_headers

      json = JSON.parse(response.body)
      data = json.dig('data', 'updateEmail')
      expect(data['user']).to be_nil
      expect(data['errors']).not_to be_empty
    end

    it "returns an error when not authenticated" do
      post graphql_path, params: {
        query: query,
        variables: { newEmail: "new@example.com", currentPassword: "password" }.to_json
      }

      json = JSON.parse(response.body)
      expect(json['errors'].first['message']).to include("logged in")
    end
  end

  describe "updatePassword mutation" do
    let(:query) do
      <<~GQL
        mutation UpdatePassword($currentPassword: String!, $newPassword: String!, $newPasswordConfirmation: String!) {
          updatePassword(currentPassword: $currentPassword, newPassword: $newPassword, newPasswordConfirmation: $newPasswordConfirmation) {
            user { id }
            errors
          }
        }
      GQL
    end

    it "updates the user's password with correct current password", :aggregate_failures do
      post graphql_path, params: {
        query: query,
        variables: {
          currentPassword: "password",
          newPassword: "newpassword123",
          newPasswordConfirmation: "newpassword123"
        }.to_json
      }, headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      data = json.dig('data', 'updatePassword')
      expect(data['errors']).to be_empty
      expect(data['user']).to be_present
      expect(user.reload.valid_password?("newpassword123")).to be true
    end

    it "returns an error when current password is incorrect" do
      post graphql_path, params: {
        query: query,
        variables: {
          currentPassword: "wrongpassword",
          newPassword: "newpassword123",
          newPasswordConfirmation: "newpassword123"
        }.to_json
      }, headers: auth_headers

      json = JSON.parse(response.body)
      data = json.dig('data', 'updatePassword')
      expect(data['user']).to be_nil
      expect(data['errors']).to include("Current password is incorrect.")
    end

    it "returns an error when new passwords do not match" do
      post graphql_path, params: {
        query: query,
        variables: {
          currentPassword: "password",
          newPassword: "newpassword123",
          newPasswordConfirmation: "differentpassword"
        }.to_json
      }, headers: auth_headers

      json = JSON.parse(response.body)
      data = json.dig('data', 'updatePassword')
      expect(data['user']).to be_nil
      expect(data['errors']).to include("New password and confirmation do not match.")
    end

    it "returns an error when new password is too short" do
      post graphql_path, params: {
        query: query,
        variables: {
          currentPassword: "password",
          newPassword: "short",
          newPasswordConfirmation: "short"
        }.to_json
      }, headers: auth_headers

      json = JSON.parse(response.body)
      data = json.dig('data', 'updatePassword')
      expect(data['user']).to be_nil
      expect(data['errors']).not_to be_empty
    end

    it "returns an error when not authenticated" do
      post graphql_path, params: {
        query: query,
        variables: {
          currentPassword: "password",
          newPassword: "newpassword123",
          newPasswordConfirmation: "newpassword123"
        }.to_json
      }

      json = JSON.parse(response.body)
      expect(json['errors'].first['message']).to include("logged in")
    end

    it "revokes previously issued JWTs after a successful password update", :aggregate_failures do
      # Capture the token as it stood before the password change, then make
      # sure a fresh token works (sanity check) before asserting that the
      # pre-change token no longer decodes to the user.
      old_token = jwt_token
      expect(JwtService.decode_and_verify(old_token)).to eq(user)

      post graphql_path, params: {
        query: query,
        variables: {
          currentPassword: "password",
          newPassword: "newpassword123",
          newPasswordConfirmation: "newpassword123"
        }.to_json
      }, headers: auth_headers

      expect(response).to have_http_status(:success)
      data = JSON.parse(response.body).dig('data', 'updatePassword')
      expect(data['errors']).to be_empty

      # The user's jwt_version should have been bumped, invalidating the
      # token issued before the password change.
      expect(JwtService.decode_and_verify(old_token)).to be_nil
    end

    it "does not revoke tokens when the password update fails" do
      old_token = jwt_token

      post graphql_path, params: {
        query: query,
        variables: {
          currentPassword: "wrongpassword",
          newPassword: "newpassword123",
          newPasswordConfirmation: "newpassword123"
        }.to_json
      }, headers: auth_headers

      # Failed updates must not bump jwt_version — otherwise a wrong-password
      # guess would log the real user out.
      expect(JwtService.decode_and_verify(old_token)).to eq(user)
    end
  end

  describe "exportLibrary mutation" do
    let(:query) do
      <<~GQL
        mutation ExportLibrary {
          exportLibrary {
            libraryJson
            errors
          }
        }
      GQL
    end

    it "exports an empty library" do
      post graphql_path, params: { query: query }, headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      data = json.dig('data', 'exportLibrary')
      expect(data['errors']).to be_empty
      library = JSON.parse(data['libraryJson'])
      expect(library).to eq([])
    end

    it "exports a library with game purchases", :aggregate_failures do
      user_with_games = create(:user_with_game_purchase)
      user_with_games.confirm
      token = JwtService.encode(user_with_games)

      post graphql_path, params: { query: query }, headers: { 'Authorization': "Bearer #{token}" }

      json = JSON.parse(response.body)
      data = json.dig('data', 'exportLibrary')
      expect(data['errors']).to be_empty
      library = JSON.parse(data['libraryJson'])
      expect(library.length).to eq(1)
      expect(library.first).to have_key('game')
      expect(library.first['game']).to have_key('name')
    end

    it "returns an error when not authenticated" do
      post graphql_path, params: { query: query }

      json = JSON.parse(response.body)
      expect(json['errors'].first['message']).to include("logged in")
    end

    it "returns an error when using a non-first-party API token" do
      api_token = SecureRandom.alphanumeric(20)
      api_token_user = create(:confirmed_user, encrypted_api_token: EncryptionService.encrypt(api_token))

      post graphql_path, params: { query: query }, headers: {
        'X-User-Email': api_token_user.email,
        'X-User-Token': api_token_user.api_token
      }

      json = JSON.parse(response.body)
      expect(json['errors'].first['message']).to include("first-party")
    end
  end
end
