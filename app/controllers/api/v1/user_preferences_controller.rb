class Api::V1::UserPreferencesController < Api::V1::AuthController
  before_action :set_user_preference, only: [ :show, :update ]

  # GET /api/v1/user_preferences
  def show
    render json: {
      success: true,
      data: ActiveModelSerializers::SerializableResource.new(@user_preference).as_json
    }
  end

  # PUT/PATCH /api/v1/user_preferences
  def update
    if @user_preference.update(user_preference_params)
      # Update onboarding notification time when user preferences are updated
      update_onboarding_notification_time

      render json: {
        success: true,
        data: ActiveModelSerializers::SerializableResource.new(@user_preference).as_json,
        message: "User preferences updated successfully"
      }
    else
      render json: {
        success: false,
        errors: @user_preference.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_user_preference
    @user_preference = current_user.user_preference

    # Create empty user preference if record does not exist
    @user_preference = current_user.create_user_preference! unless @user_preference
  end

  def user_preference_params
    params.require(:user_preference).permit(:notification_time, :timezone)
  end

  def update_onboarding_notification_time
    onboarding = current_user.onboarding

    # Create onboarding record if it doesn't exist
    onboarding = current_user.create_onboarding! unless onboarding

    onboarding.update!(notification_time_setting: Time.current)
  end
end
