require 'rails_helper'

RSpec.describe EncryptionService, type: :service do
  describe '.encrypt' do
    it 'returns a string that is not the original value' do
      encrypted = described_class.encrypt('hunter2')
      expect(encrypted).to be_a(String)
      expect(encrypted).not_to eq('hunter2')
    end

    it 'produces a different ciphertext each call for the same input' do
      expect(described_class.encrypt('hunter2')).not_to eq(described_class.encrypt('hunter2'))
    end
  end

  describe '.decrypt' do
    it 'round-trips a value back to its original form' do
      encrypted = described_class.encrypt('super-secret-api-token')
      expect(described_class.decrypt(encrypted)).to eq('super-secret-api-token')
    end

    it 'raises when given a tampered ciphertext' do
      encrypted = described_class.encrypt('hunter2')
      expect { described_class.decrypt("#{encrypted}tampered") }.to raise_error(ActiveSupport::MessageEncryptor::InvalidMessage)
    end

    it 'raises when given an unrelated string' do
      expect { described_class.decrypt('not-a-real-ciphertext') }.to raise_error(ActiveSupport::MessageEncryptor::InvalidMessage)
    end
  end
end
