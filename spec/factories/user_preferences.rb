FactoryBot.define do
  factory :user_preference do
    association :user
    notification_time { "14:30:00" }
    timezone { "Asia/Kolkata" }

    trait :with_different_timezone do
      timezone { "America/New_York" }
    end

    trait :with_morning_notification do
      notification_time { "09:00:00" }
    end

    trait :with_evening_notification do
      notification_time { "18:00:00" }
    end

    trait :empty do
      notification_time { nil }
      timezone { nil }
    end
  end
end
