class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  has_many :release_purchases
  has_many :releases, through: :release_purchases

  validates :username,
    # Username is required
    presence: true,
    # Must be between 4 and 20 characters
    length: { minimum: 4, maximum: 20 },
    # Allow letters, numbers, disallow _ and . at the start or end,
    # disallow _ or . next to each other or themselves.
    # Based on https://stackoverflow.com/a/12019115/7143763
    format: /(?![_.])(?!.*[_.]{2})[a-zA-Z0-9._]+(?<![_.])/,
    uniqueness: {
      message: ->(object, data) do
        "#{data[:value]} is taken already!"
      end
    }

end
