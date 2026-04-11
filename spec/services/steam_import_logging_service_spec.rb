require 'rails_helper'

RSpec.describe SteamImportLoggingService, type: :service do
  # Mirrors SteamImportService::Unmatched — a struct with `name` and `steam_id`.
  let(:unmatched_struct) { Struct.new(:name, :steam_id) }
  let(:user) { create(:user) }

  describe '#call' do
    it 'creates an UnmatchedGame for each entry' do
      unmatched = [
        unmatched_struct.new('Half-Life 3', '12345'),
        unmatched_struct.new('Portal 3', '67890')
      ]

      expect do
        described_class.new(user: user, unmatched_from_import: unmatched).call
      end.to change(UnmatchedGame, :count).by(2)
    end

    it 'records the supplied name, steam id, and user on each row' do
      described_class.new(
        user: user,
        unmatched_from_import: [unmatched_struct.new('Half-Life 3', '12345')]
      ).call

      row = UnmatchedGame.last
      expect(row).to have_attributes(
        name: 'Half-Life 3',
        external_service_id: '12345',
        external_service_name: 'Steam',
        user_id: user.id
      )
    end

    it 'does not create duplicates when called twice for the same user and steam id' do
      unmatched = [unmatched_struct.new('Half-Life 3', '12345')]

      described_class.new(user: user, unmatched_from_import: unmatched).call
      expect do
        described_class.new(user: user, unmatched_from_import: unmatched).call
      end.not_to change(UnmatchedGame, :count)
    end

    it 'scopes uniqueness by user — the same steam id logs once per user' do
      other_user = create(:user)
      unmatched = [unmatched_struct.new('Half-Life 3', '12345')]

      described_class.new(user: user, unmatched_from_import: unmatched).call
      expect do
        described_class.new(user: other_user, unmatched_from_import: unmatched).call
      end.to change(UnmatchedGame, :count).by(1)
    end

    it 'does nothing when the unmatched list is empty' do
      expect do
        described_class.new(user: user, unmatched_from_import: []).call
      end.not_to change(UnmatchedGame, :count)
    end
  end
end
