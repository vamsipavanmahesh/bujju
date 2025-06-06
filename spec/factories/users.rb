FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    name { Faker::Name.name }
    avatar_url { Faker::Internet.url }
    provider { 'google' }
    provider_id { Faker::Internet.unique.uuid }
  end
end 