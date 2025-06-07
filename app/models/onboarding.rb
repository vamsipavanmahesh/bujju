class Onboarding < ApplicationRecord
  self.table_name = "onboarding"

  # Associations
  belongs_to :user

  # Validations
  validates :user, presence: true
end
