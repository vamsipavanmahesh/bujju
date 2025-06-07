require 'rails_helper'

RSpec.describe Onboarding, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:user) }
  end

  describe 'table name' do
    it 'uses singular table name' do
      expect(described_class.table_name).to eq('onboarding')
    end
  end

  describe 'factory' do
    it 'creates a valid onboarding' do
      onboarding = build(:onboarding)
      expect(onboarding).to be_valid
    end

    it 'creates onboarding with user association' do
      onboarding = create(:onboarding)
      expect(onboarding.user).to be_present
      expect(onboarding.user).to be_a(User)
    end
  end
end
