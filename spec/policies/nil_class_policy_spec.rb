# typed: false
require 'rails_helper'

RSpec.describe NilClassPolicy, type: :policy do
  subject(:nil_class_policy) { described_class.new(user, nil) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }

    it 'defaults to disallowing everything' do
      expect(nil_class_policy).not_to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }

    it 'defaults to disallowing everything' do
      expect(nil_class_policy).not_to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy]
      )
    end
  end

  describe "An action that doesn't exist" do
    let(:user) { create(:user) }

    it "is disallowed" do
      expect(nil_class_policy).not_to permit_actions(
        [:not_a_real_action]
      )
    end
  end
end
