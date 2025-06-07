FactoryBot.define do
  factory :connection do
    name { Faker::Name.name }
    phone_number { Faker::PhoneNumber.phone_number }
    relationship { Connection.relationships.keys.sample }
    association :user
  end
end
