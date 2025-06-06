require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:provider) }
    it { should validate_presence_of(:provider_id) }

    it 'validates uniqueness of provider_id scoped to provider' do
      existing_user = create(:user)

      # Same provider_id, same provider should be invalid
      new_user = build(:user, provider_id: existing_user.provider_id)
      expect(new_user).not_to be_valid

      # Same provider_id, different provider should be valid
      new_user.provider = 'apple'
      expect(new_user).to be_valid
    end
  end

  describe '.from_google_token!' do
    let(:google_payload) do
      {
        'sub' => '12345',
        'email' => 'user@example.com',
        'name' => 'Test User',
        'picture' => 'https://example.com/avatar.jpg'
      }
    end

    it 'creates a new user from Google payload' do
      expect {
        user = described_class.from_google_token!(google_payload)

        expect(user).to be_persisted
        expect(user.provider).to eq('google')
        expect(user.provider_id).to eq('12345')
        expect(user.email).to eq('user@example.com')
        expect(user.name).to eq('Test User')
        expect(user.avatar_url).to eq('https://example.com/avatar.jpg')
      }.to change(User, :count).by(1)
    end

    it 'updates existing user from Google payload' do
      existing_user = build(:user)
      existing_user.provider_id = '12345'
      existing_user.save!

      expect {
        user = described_class.from_google_token!(google_payload)

        expect(user.id).to eq(existing_user.id)
        expect(user.email).to eq('user@example.com')
        expect(user.name).to eq('Test User')
      }.not_to change(User, :count)
    end
  end
end
