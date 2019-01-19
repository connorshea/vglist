require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the ApplicationHelper. For example:
#
# describe ApplicationHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe ApplicationHelper, type: :helper do
  describe 'flash class' do
    it 'sets the correct class for a notice' do
      expect(helper.flash_class(:notice)).to eq("is-info")
    end

    it 'sets the correct class for a success' do
      expect(helper.flash_class(:success)).to eq("is-success")
    end

    it 'sets the correct class for an error' do
      expect(helper.flash_class(:error)).to eq("is-danger")
    end

    it 'sets the correct class for an alert' do
      expect(helper.flash_class(:alert)).to eq("is-warning")
    end
  end
end
