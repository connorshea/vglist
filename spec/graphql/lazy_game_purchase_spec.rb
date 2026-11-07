# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LazyGamePurchase do
  let(:context) { {} }

  it 'loads every queued purchase in one query' do
    purchases = create_list(:game_purchase, 3)
    lazies = purchases.map { |purchase| described_class.new(context, purchase.id) }

    queries = 0
    callback = ->(*) { queries += 1 }
    values = ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { lazies.map(&:value) }

    expect(values).to eq(purchases)
    expect(queries).to eq(1)
  end

  it 'returns nil for a purchase deleted since it was queued' do
    purchase = create(:game_purchase)
    lazy = described_class.new(context, purchase.id)
    purchase.destroy!

    expect(lazy.value).to be_nil
  end
end
