class User < ApplicationRecord
  # Validations
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :provider, presence: true
  validates :provider_id, presence: true, uniqueness: { scope: :provider }

  # Class method to find or create a user from Google token payload
  def self.from_google_token!(payload)
    user = find_or_initialize_by(provider: "google", provider_id: payload["sub"])

    user.assign_attributes(
      email: payload["email"],
      name: payload["name"],
      avatar_url: payload["picture"]
    )

    user.save!
    user
  end
end
