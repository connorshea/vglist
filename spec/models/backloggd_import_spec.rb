# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BackloggdImport, type: :model do
  subject(:backloggd_import) { described_class.new(user: create(:user), username: 'Example') }

  it { should belong_to(:user) }
  it { should validate_presence_of(:username) }
  it { should validate_length_of(:username).is_at_most(40) }

  describe '#in_progress?' do
    it 'is true while queued or running' do
      backloggd_import.update!(status: :running)

      expect(backloggd_import).to be_in_progress
    end

    it 'is false once finished' do
      backloggd_import.update!(status: :succeeded)

      expect(backloggd_import).not_to be_in_progress
    end

    it 'is false for an import that has stopped moving' do
      backloggd_import.update!(status: :running, updated_at: 31.minutes.ago)

      expect(backloggd_import).not_to be_in_progress
    end
  end

  it 'is deleted with its user' do
    backloggd_import.save!

    expect { backloggd_import.user.destroy! }.to change(described_class, :count).by(-1)
  end
end
