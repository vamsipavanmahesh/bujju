class UserPreference < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :timezone, length: { maximum: 50 }
  validates :user_id, uniqueness: true
end
