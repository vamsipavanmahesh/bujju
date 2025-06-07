FactoryBot.define do
  factory :onboarding do
    association :user
    notification_time_setting { Faker::Time.between(from: 1.day.ago, to: 1.day.from_now) }
  end
end
