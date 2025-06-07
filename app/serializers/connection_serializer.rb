class ConnectionSerializer < ActiveModel::Serializer
  attributes :id, :name, :phone_number, :relationship, :created_at, :updated_at

  # Example of computed attributes (can be uncommented if needed)
  # attribute :formatted_phone_number
  #
  # def formatted_phone_number
  #   # Format phone number if needed
  #   object.phone_number
  # end

  # Example of conditional attributes (can be uncommented if needed)
  # attribute :user_id, if: :include_user_id?
  #
  # def include_user_id?
  #   # Only include user_id for admins or specific contexts
  #   false
  # end
end
