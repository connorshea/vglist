class ReleasePurchase < ApplicationRecord
  belongs_to :release
  belongs_to :user

  validates :comment,
    length: { maximum: 500 }

  validates :release_id,
    uniqueness: { scope: :user_id }
end
