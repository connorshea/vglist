# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "ImportBackloggdLibrary Mutation API", type: :request do
  include ActiveJob::TestHelper

  let(:query_string) do
    <<-GRAPHQL
      mutation($id: ID!, $username: String!) {
        importBackloggdLibrary(userId: $id, backloggdUsername: $username) {
          backloggdImport { username status }
        }
      }
    GRAPHQL
  end
  let(:user) { create(:confirmed_user) }
  let(:access_token) { JwtService.encode(user) }

  def start_import(username, id: user.id)
    api_request(query_string, variables: { id: id, username: username }, token: access_token)
  end

  it 'queues an import of the Backloggd profile' do
    result = nil

    expect { result = start_import('https://backloggd.com/u/Example/') }.to have_enqueued_job(BackloggdImportJob)
    expect(result.graphql_dig(:import_backloggd_library, :backloggd_import)).to eq({ username: 'Example', status: 'QUEUED' })
  end

  it 'starts over from a finished import' do
    BackloggdImport.create!(user: user, username: 'Old', status: :failed, error_message: 'Nope')

    start_import('Example')

    expect(user.backloggd_import.reload).to have_attributes(username: 'Example', status: 'queued', error_message: nil)
  end

  it 'refuses to start a second import while one is running' do
    BackloggdImport.create!(user: user, username: 'Example', status: :running)

    result = nil
    expect { result = start_import('Example') }.not_to have_enqueued_job(BackloggdImportJob)
    expect(result.to_h['errors'].first['message']).to eq('An import from Backloggd is already running.')
  end

  it 'rejects something that is not a username' do
    result = start_import('not a username!')

    expect(result.to_h['errors'].first['message']).to eq("That doesn't look like a Backloggd username.")
  end

  it "does not import into another user's library" do
    result = start_import('Example', id: create(:confirmed_user).id)

    expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to import games for this user.")
  end
end
