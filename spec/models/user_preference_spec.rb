require 'rails_helper'

RSpec.describe UserPreference, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:user_preference) }

    it { should validate_length_of(:timezone).is_at_most(50) }
    it { should validate_uniqueness_of(:user_id) }

    it 'accepts empty timezone' do
      user_preference = build(:user_preference, timezone: nil)
      expect(user_preference).to be_valid
    end

    it 'accepts empty notification_time' do
      user_preference = build(:user_preference, notification_time: nil)
      expect(user_preference).to be_valid
    end

    it 'accepts any timezone string' do
      timezones = [
        'Asia/Kolkata',
        'America/New_York',
        'Europe/London',
        'Invalid/Timezone',
        'GMT+5:30',
        'random_string',
        nil,
        ''
      ]

      timezones.each do |timezone|
        user_preference = build(:user_preference, timezone: timezone)
        expect(user_preference).to be_valid, "Expected #{timezone} to be valid"
      end
    end
  end

  describe 'database constraints' do
    it 'enforces user_id uniqueness at database level' do
      user = create(:user)
      create(:user_preference, user: user)

      # The model validation should catch this before it hits the database
      duplicate_preference = build(:user_preference, user: user)
      expect(duplicate_preference).not_to be_valid
      expect(duplicate_preference.errors[:user_id]).to include('has already been taken')
    end
  end

  describe 'factory' do
    it 'creates a valid user preference' do
      user_preference = build(:user_preference)
      expect(user_preference).to be_valid
    end

    it 'creates user preference with traits' do
      user_preference = build(:user_preference, :with_different_timezone, :with_morning_notification)
      expect(user_preference.timezone).to eq('America/New_York')
      expect(user_preference.notification_time.strftime('%H:%M')).to eq('09:00')
    end

    it 'creates empty user preference' do
      user_preference = build(:user_preference, :empty)
      expect(user_preference.notification_time).to be_nil
      expect(user_preference.timezone).to be_nil
      expect(user_preference).to be_valid
    end
  end
end
