# typed: strict
class ExternalAccount < ApplicationRecord
  belongs_to :user

  validates :user_id,
    uniqueness: { scope: [:account_type] },
    presence: true

  validates :steam_id,
    uniqueness: true,
    allow_nil: true,
    numericality: {
      only_integer: true,
      allow_nil: true,
      greater_than: 0
    }

  validates :account_type, presence: true

  enum account_type: {
    steam: 0
  }
end
