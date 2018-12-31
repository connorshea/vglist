class ReleasePurchase < ApplicationRecord
  belongs_to :release
  belongs_to :user

  validates :comment,
    length: { maximum: 500 }
end
