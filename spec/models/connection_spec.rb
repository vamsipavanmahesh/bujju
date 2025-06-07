require 'rails_helper'

RSpec.describe Connection, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:phone_number) }
    it { should validate_presence_of(:relationship) }
    it { should validate_presence_of(:user_id) }
    it { should validate_length_of(:name).is_at_most(100) }
  end

  describe 'factory' do
    it 'creates a valid connection' do
      connection = create(:connection)
      expect(connection).to be_valid
      expect(connection.user).to be_present
      expect(connection.relationship).to be_present
    end
  end

  describe 'enum relationship' do
    it 'defines relationship enum values' do
      expect(Connection.relationships.keys).to include('friend', 'family', 'colleague', 'partner', 'parent', 'child', 'sibling', 'romantic_interest')
    end

    it 'allows setting relationship with enum values' do
      connection = create(:connection, relationship: :family)
      expect(connection.relationship).to eq('family')
      expect(connection.family?).to be true
    end

    it 'stores relationship as string in database' do
      connection = create(:connection, relationship: :colleague)
      expect(connection.read_attribute(:relationship)).to eq('colleague')
    end
  end

  describe 'input sanitization' do
    it 'strips whitespace from name' do
      connection = create(:connection, name: '  John Doe  ')
      expect(connection.name).to eq('John Doe')
    end

    it 'strips whitespace from phone_number' do
      connection = create(:connection, phone_number: '  +1234567890  ')
      expect(connection.phone_number).to eq('+1234567890')
    end

    it 'does not sanitize relationship as it is handled by enum' do
      connection = create(:connection, relationship: :friend)
      expect(connection.relationship).to eq('friend')
    end
  end
end
