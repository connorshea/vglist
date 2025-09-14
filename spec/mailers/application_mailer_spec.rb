require "rails_helper"

RSpec.describe ApplicationMailer, type: :mailer do
  describe 'default email from' do
    subject { described_class.default[:from] }

    it { should eq('noreply@mail.vglist.co') }
  end
end
