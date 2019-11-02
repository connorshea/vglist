# typed: false
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
      expect(helper.meta_title('This is the title')).to eq("This is the title | vglist")
    end

    it 'returns a title when not provided a parameter' do
      expect(helper.meta_title('')).to eq("vglist")
    end
  end

  describe 'meta description' do
    it 'returns a description when provided a parameter' do
      expect(helper.meta_description('This is the description')).to eq("This is the description")
    end

    it 'returns a description when provided an empty string' do
      expect(helper.meta_description('')).to eq("vglist helps you track your entire video game library across every store and platform.")
    end
  end

  describe 'summarize helper' do
    it 'returns the correct string when given 4 items with a limit of 2' do
      expect(helper.summarize(['PlayStation 2', 'Xbox 360', 'Wii U', 'Windows'], limit: 2)).to eq("PlayStation 2, Xbox 360, and 2 more")
    end

    it 'defaults to a limit of 3' do
      expect(helper.summarize(['PlayStation 2', 'Xbox 360', 'Wii U', 'Windows'])).to eq("PlayStation 2, Xbox 360, Wii U, and 1 more")
    end

    it 'can handle an array with less items than the limit' do
      expect(helper.summarize(['PlayStation 2', 'Xbox 360', 'Wii U', 'Windows'], limit: 5)).to eq("PlayStation 2, Xbox 360, Wii U, Windows")
    end

    it 'can handle a limit of 1 without adding a comma' do
      expect(helper.summarize(['PlayStation 2', 'Xbox 360', 'Wii U', 'Windows'], limit: 1)).to eq("PlayStation 2 and 3 more")
    end

    it 'can handle an array where the length is the same as the limit' do
      expect(helper.summarize(['PlayStation 2', 'Xbox 360', 'Wii U', 'Windows'], limit: 4)).to eq("PlayStation 2, Xbox 360, Wii U, Windows")
    end

    it 'can handle an array with 1 item' do
      expect(helper.summarize(['Windows'])).to eq("Windows")
    end

    it 'can handle an array with 1 item and a limit of 1' do
      expect(helper.summarize(['Windows'], limit: 1)).to eq("Windows")
    end

    it 'can handle an empty array with a limit of 1' do
      expect(helper.summarize([], limit: 1)).to eq("")
    end

    it 'can handle an empty array' do
      expect(helper.summarize([])).to eq("")
    end

    it 'raises an ArgumentError if the limit is less than 1' do
      expect { helper.summarize(['Windows'], limit: -1) }.to raise_error(ArgumentError, 'Limit must be a positive integer')
      expect { helper.summarize(['Windows'], limit: 0) }.to raise_error(ArgumentError, 'Limit must be a positive integer')
    end
  end
end
