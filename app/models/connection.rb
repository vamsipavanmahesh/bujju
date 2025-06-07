class Connection < ApplicationRecord
  belongs_to :user

  validates :name, presence: true, length: { maximum: 100 }
  validates :phone_number, presence: true
  validates :relationship, presence: true
  validates :user_id, presence: true

  enum :relationship, {
    friend: "friend",
    family: "family",
    colleague: "colleague",
    partner: "partner",
    parent: "parent",
    child: "child",
    sibling: "sibling",
    romantic_interest: "romantic_interest"
  }

  # Sanitize input data
  before_save :sanitize_input

  private

  def sanitize_input
    self.name = name.strip if name.present?
    self.phone_number = phone_number.strip if phone_number.present?
    # Note: Don't sanitize relationship as it's handled by enum
  end
end
