# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GraphQL auth mutation limit", type: :request do
  let(:user) { create(:confirmed_user) }
  let(:limit_message) { "Only one of signIn, signUp, requestPasswordReset may be used per request." }

  it "rejects a document with more than one aliased signIn", :aggregate_failures do
    query = <<~GQL
      mutation {
        a: signIn(email: "#{user.email}", password: "guess1") { token errors }
        b: signIn(email: "#{user.email}", password: "guess2") { token errors }
      }
    GQL

    post graphql_path, params: { query: query }

    json = JSON.parse(response.body)
    expect(json['data']).to be_nil
    expect(json['errors'].pluck('message')).to include(limit_message)
  end

  it "rejects mixing signIn with requestPasswordReset in one document" do
    query = <<~GQL
      mutation {
        signIn(email: "#{user.email}", password: "guess1") { token }
        requestPasswordReset(email: "#{user.email}") { message }
      }
    GQL

    post graphql_path, params: { query: query }

    json = JSON.parse(response.body)
    expect(json['errors'].pluck('message')).to include(limit_message)
  end

  it "counts auth mutations selected through fragments" do
    query = <<~GQL
      mutation {
        a: signIn(email: "#{user.email}", password: "guess1") { ...SignInFields }
        b: signIn(email: "#{user.email}", password: "guess2") { ...SignInFields }
      }
      fragment SignInFields on SignInMutationPayload { token }
    GQL

    post graphql_path, params: { query: query }

    json = JSON.parse(response.body)
    expect(json['errors'].pluck('message')).to include(limit_message)
  end

  it "still allows a single signIn", :aggregate_failures do
    query = <<~GQL
      mutation { signIn(email: "#{user.email}", password: "password") { token errors } }
    GQL

    post graphql_path, params: { query: query }

    json = JSON.parse(response.body)
    expect(json['errors']).to be_nil
    expect(json.dig('data', 'signIn', 'token')).to be_present
  end

  it "does not limit other mutations from being batched alongside one auth mutation" do
    query = <<~GQL
      mutation {
        a: signIn(email: "#{user.email}", password: "password") { token }
        b: updateUser(bio: "hello") { user { id } }
      }
    GQL

    post graphql_path, params: { query: query }

    json = JSON.parse(response.body)
    expect(json['errors'].to_a.pluck('message')).not_to include(limit_message)
  end
end
