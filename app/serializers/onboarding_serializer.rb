class OnboardingSerializer < ActiveModel::Serializer
  attributes :id, :notification_time_setting, :created_at, :updated_at

  # Format notification_time_setting as ISO 8601 datetime string
  def notification_time_setting
    object.notification_time_setting&.iso8601
  end
end
