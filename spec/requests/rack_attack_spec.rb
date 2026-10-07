# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Rack::Attack throttling", type: :request do
  let(:user) { create(:confirmed_user) }

  # Rails.cache is a null store in test, so swap in a real store for these
  # examples and start each one with empty counters.
  around(:each) do |example|
    original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!
    example.run
  ensure
    Rack::Attack.cache.store = original_store
  end

  def sign_in_query
    <<~GQL
      mutation SignIn($email: String!, $password: String!) {
        signIn(email: $email, password: $password) { token errors }
      }
    GQL
  end

  def graphql_sign_in(email:, password:, ip: '1.2.3.4')
    post graphql_path,
      params: { query: sign_in_query, variables: { email: email, password: password } }.to_json,
      headers: { 'Content-Type' => 'application/json', 'REMOTE_ADDR' => ip }
  end

  describe "per-email sign-in throttle" do
    it "blocks password guesses against one account after the limit, regardless of IP", :aggregate_failures do
      10.times do |i|
        post api_auth_sign_in_path, params: { email: user.email, password: "wrong" }, headers: { 'REMOTE_ADDR' => "10.0.0.#{i}" }
        expect(response).to have_http_status(:unauthorized)
      end

      post api_auth_sign_in_path, params: { email: user.email.upcase, password: "wrong" }, headers: { 'REMOTE_ADDR' => '10.0.0.99' }
      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers['Retry-After']).to be_present
      json = JSON.parse(response.body)
      expect(json['error']).to eq("Too many requests. Please try again later.")
      expect(json['errors'].first['message']).to eq("Too many requests. Please try again later.")

      # The correct password is also blocked while throttled.
      post api_auth_sign_in_path, params: { email: user.email, password: "password" }, headers: { 'REMOTE_ADDR' => '10.0.0.100' }
      expect(response).to have_http_status(:too_many_requests)

      # Other accounts are unaffected.
      other = create(:confirmed_user)
      post api_auth_sign_in_path, params: { email: other.email, password: "password" }, headers: { 'REMOTE_ADDR' => '10.0.0.101' }
      expect(response).to have_http_status(:success)
    end

    it "shares the counter between the REST endpoint and the GraphQL signIn mutation (JSON body)", :aggregate_failures do
      5.times do
        post api_auth_sign_in_path, params: { email: user.email, password: "wrong" }
      end
      5.times do |i|
        graphql_sign_in(email: user.email, password: "wrong", ip: "10.1.0.#{i}")
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body).dig('data', 'signIn', 'errors')).to eq(["Invalid email or password."])
      end

      graphql_sign_in(email: user.email, password: "wrong", ip: '10.1.0.50')
      expect(response).to have_http_status(:too_many_requests)
      expect(JSON.parse(response.body)['errors'].first['message']).to eq("Too many requests. Please try again later.")
    end

    it "reads an inline email literal from the GraphQL query", :aggregate_failures do
      query = %(mutation { signIn(email: "#{user.email}", password: "wrong") { token errors } })
      10.times do |i|
        post graphql_path, params: { query: query }, headers: { 'REMOTE_ADDR' => "10.2.0.#{i}" }
        expect(response).to have_http_status(:success)
      end

      post graphql_path, params: { query: query }, headers: { 'REMOTE_ADDR' => '10.2.0.50' }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "per-email email-delivery throttle" do
    it "limits password reset requests for one address", :aggregate_failures do
      5.times do |i|
        post user_password_path, params: { user: { email: user.email } }, headers: { 'REMOTE_ADDR' => "10.3.0.#{i}" }
        expect(response).to have_http_status(:success)
      end

      post user_password_path, params: { user: { email: user.email } }, headers: { 'REMOTE_ADDR' => '10.3.0.50' }
      expect(response).to have_http_status(:too_many_requests)
    end

    it "limits requestPasswordReset mutations for one address", :aggregate_failures do
      query = <<~GQL
        mutation Reset($email: String!) { requestPasswordReset(email: $email) { message } }
      GQL
      5.times do |i|
        post graphql_path,
          params: { query: query, variables: { email: user.email } }.to_json,
          headers: { 'Content-Type' => 'application/json', 'REMOTE_ADDR' => "10.4.0.#{i}" }
        expect(response).to have_http_status(:success)
      end

      post graphql_path,
        params: { query: query, variables: { email: user.email } }.to_json,
        headers: { 'Content-Type' => 'application/json', 'REMOTE_ADDR' => '10.4.0.50' }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "per-IP throttle" do
    it "blocks a single client spraying attempts across many accounts", :aggregate_failures do
      20.times do |i|
        post api_auth_sign_in_path, params: { email: "user#{i}@example.com", password: "wrong" }, headers: { 'REMOTE_ADDR' => '10.5.0.1' }
        expect(response).to have_http_status(:unauthorized)
      end

      post api_auth_sign_in_path, params: { email: "user99@example.com", password: "wrong" }, headers: { 'REMOTE_ADDR' => '10.5.0.1' }
      expect(response).to have_http_status(:too_many_requests)

      # A different client is unaffected.
      post api_auth_sign_in_path, params: { email: "user99@example.com", password: "wrong" }, headers: { 'REMOTE_ADDR' => '10.5.0.2' }
      expect(response).to have_http_status(:unauthorized)
    end

    it "does not count ordinary GraphQL queries", :aggregate_failures do
      25.times do
        post graphql_path, params: { query: '{ games(first: 1) { nodes { id } } }' }, headers: { 'REMOTE_ADDR' => '10.6.0.1' }
        expect(response).to have_http_status(:success)
      end
    end
  end

  # Rack::Attack runs before routing, so it must match the same paths the
  # router does: optional format suffix, duplicate and trailing slashes.
  describe "path variants" do
    it "counts format-suffixed and slash-variant sign-in paths against the same email", :aggregate_failures do
      paths = ['/api/auth/sign_in.json', '/api/auth/sign_in/', '//api/auth/sign_in', '/api/auth/sign_in.json/']
      10.times do |i|
        post paths[i % paths.length], params: { email: user.email, password: "wrong" }, headers: { 'REMOTE_ADDR' => "10.7.0.#{i}" }
        expect(response).to have_http_status(:unauthorized)
      end

      post '/api/auth/sign_in.json', params: { email: user.email, password: "wrong" }, headers: { 'REMOTE_ADDR' => '10.7.0.50' }
      expect(response).to have_http_status(:too_many_requests)
    end

    it "throttles GraphQL sign-in mutations sent to /graphql.json", :aggregate_failures do
      10.times do |i|
        post '/graphql.json',
          params: { query: sign_in_query, variables: { email: user.email, password: "wrong" } }.to_json,
          headers: { 'Content-Type' => 'application/json', 'REMOTE_ADDR' => "10.8.0.#{i}" }
        expect(response).to have_http_status(:success)
      end

      graphql_sign_in(email: user.email, password: "wrong", ip: '10.8.0.50')
      expect(response).to have_http_status(:too_many_requests)
    end

    it "limits password reset requests sent with a format suffix", :aggregate_failures do
      5.times do |i|
        post '/users/password.json', params: { user: { email: user.email } }, headers: { 'REMOTE_ADDR' => "10.9.0.#{i}" }
        expect(response).not_to have_http_status(:too_many_requests)
      end

      post '/users/password.json', params: { user: { email: user.email } }, headers: { 'REMOTE_ADDR' => '10.9.0.50' }
      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
