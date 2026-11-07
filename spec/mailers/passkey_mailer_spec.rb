# frozen_string_literal: true

require "rails_helper"

RSpec.describe PasskeyMailer, type: :mailer do
  describe 'passkey_added' do
    let(:user) { create(:confirmed_user, username: 'gordon') }
    let(:passkey) { create(:webauthn_credential, user: user, nickname: '<b>Work laptop</b>') }
    let(:mail) { described_class.with(passkey: passkey).passkey_added }

    it 'goes to the passkey owner', :aggregate_failures do
      expect(mail.to).to eq([user.email])
      expect(mail.subject).to eq('A passkey was added to your vglist account')
    end

    it 'names the passkey and links to account settings', :aggregate_failures do
      expect(mail.text_part.body.to_s).to include('"<b>Work laptop</b>"')
      expect(mail.text_part.body.to_s).to include('/settings/account')
      expect(mail.html_part.body.to_s).to include('&lt;b&gt;Work laptop&lt;/b&gt;')
      expect(mail.html_part.body.to_s).to include('/settings/account')
    end
  end
end
