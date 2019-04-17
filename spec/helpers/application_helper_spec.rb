require 'rails_helper'

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

  describe 'meta title' do
    it 'returns a title when provided a parameter' do
      expect(helper.meta_title('This is the title')).to eq("This is the title | VideoGameList")
    end

    it 'returns a title when not provided a parameter' do
      expect(helper.meta_title('')).to eq("VideoGameList")
    end
  end

  describe 'meta description' do
    it 'returns a description when provided a parameter' do
      expect(helper.meta_description('This is the description')).to eq("This is the description")
    end

    it 'returns a description when provided an empty string' do
      expect(helper.meta_description('')).to eq("VideoGameList (VGList) helps you track your entire video game library across every store and platform.")
    end
  end
end
