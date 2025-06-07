class UserPreferenceSerializer < ActiveModel::Serializer
  attributes :id, :notification_time, :timezone, :created_at, :updated_at

  # Format notification_time as HH:MM string
  def notification_time
    object.notification_time&.strftime("%H:%M")
  end
end
