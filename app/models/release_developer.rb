class ReleaseDeveloper < ApplicationRecord
  belongs_to :release
  belongs_to :company
end
